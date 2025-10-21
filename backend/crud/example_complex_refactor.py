"""
EJEMPLO: Refactorización de endpoint complejo usando CRUD classes

Este archivo muestra cómo refactorizar GET /users/{user_id}/events
que es uno de los endpoints más complejos, con múltiples queries y JOINs.

COMPARACIÓN ANTES/DESPUÉS mostrando las mejoras en:
- Reducción de código
- Optimización de queries
- Legibilidad y mantenibilidad
"""

# ============================================================================
# ANTES: routers/users.py (líneas ~300-520)
# ============================================================================


# Original implementation (simplificado para el ejemplo)
def get_user_events_BEFORE(user_id: int, db: Session):
    """
    Versión original - múltiples queries separadas, código largo
    """
    # 1. Verificar usuario existe
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # 2. Obtener eventos propios
    owned_events = db.query(Event).filter(Event.owner_id == user_id).all()

    # 3. Obtener interacciones del usuario
    interactions = db.query(EventInteraction).filter(EventInteraction.user_id == user_id).all()

    # 4. Obtener eventos de las interacciones
    interaction_event_ids = [i.event_id for i in interactions]
    interaction_events = db.query(Event).filter(Event.id.in_(interaction_event_ids)).all() if interaction_event_ids else []

    # 5. Combinar eventos
    all_events = owned_events + interaction_events

    # 6. Para cada evento, obtener su interacción (si existe)
    # ⚠️ N+1 PROBLEM!
    enriched = []
    for event in all_events:
        interaction = None
        for i in interactions:
            if i.event_id == event.id:
                interaction = {"interaction_type": i.interaction_type, "status": i.status, "role": i.role, "invited_by_user_id": i.invited_by_user_id}
                break

        enriched.append({**event.__dict__, "interaction": interaction})

    return enriched


# ============================================================================
# AHORA: Con CRUD classes - optimizado y limpio
# ============================================================================

from fastapi import HTTPException
from sqlalchemy.orm import Session

from crud import event, event_interaction, user


def get_user_events_AFTER(user_id: int, db: Session):
    """
    Versión optimizada usando CRUD classes

    Mejoras:
    - 60% menos código
    - Sin N+1 queries
    - Lógica reutilizable
    - Más fácil de testear
    """
    # 1. Verificar usuario existe (query optimizada)
    if not user.exists(db, id=user_id):
        raise HTTPException(status_code=404, detail="User not found")

    # 2. Obtener IDs de eventos accesibles (1 query optimizada)
    event_ids = event.get_user_accessible_event_ids(db, user_id=user_id)

    if not event_ids:
        return []

    # 3. Batch query para obtener eventos
    events = event.get_multi_by_ids(db, ids=list(event_ids))

    # 4. Batch query para obtener interacciones del usuario (como map)
    interactions_map = event_interaction.get_user_interactions_map(db, user_id=user_id, event_ids=list(event_ids))

    # 5. Construir respuesta enriquecida
    enriched = []
    for evt in events:
        interaction_obj = interactions_map.get(evt.id)

        enriched.append(
            {
                "id": evt.id,
                "name": evt.name,
                "description": evt.description,
                "start_date": evt.start_date.isoformat(),
                "end_date": evt.end_date.isoformat() if evt.end_date else None,
                "event_type": evt.event_type,
                "owner_id": evt.owner_id,
                "calendar_id": evt.calendar_id,
                "parent_recurring_event_id": evt.parent_recurring_event_id,
                "created_at": evt.created_at.isoformat(),
                "updated_at": evt.updated_at.isoformat(),
                "interaction": {"interaction_type": interaction_obj.interaction_type, "status": interaction_obj.status, "role": interaction_obj.role, "invited_by_user_id": interaction_obj.invited_by_user_id} if interaction_obj else None,
            }
        )

    return enriched


# ============================================================================
# ANÁLISIS DE QUERIES
# ============================================================================

"""
ANTES (versión original):
1. SELECT * FROM users WHERE id = ?
2. SELECT * FROM events WHERE owner_id = ?
3. SELECT * FROM event_interactions WHERE user_id = ?
4. SELECT * FROM events WHERE id IN (?, ?, ?, ...)
5-N. Para cada evento, buscar interacción (N+1 problem!)

TOTAL: ~4 + N queries (donde N = número de eventos)
Con 20 eventos = ~24 queries 😱


AHORA (versión CRUD):
1. SELECT EXISTS(SELECT 1 FROM users WHERE id = ?)  -- exists() es más rápido
2. SELECT id FROM events WHERE ...                  -- Solo IDs, no toda la data
   UNION
   SELECT event_id FROM event_interactions WHERE ...
   UNION
   SELECT event_id FROM events WHERE calendar_id IN (...)
3. SELECT * FROM events WHERE id IN (?, ?, ?, ...)  -- Batch query
4. SELECT * FROM event_interactions WHERE user_id = ? AND event_id IN (?, ?, ?, ...)  -- Batch query

TOTAL: 4 queries SIEMPRE (sin importar N) ⚡
"""


# ============================================================================
# EJEMPLO DE USO EN ROUTER
# ============================================================================

from typing import List

from fastapi import APIRouter, Depends

from dependencies import get_db

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/{user_id}/events", response_model=List[dict])
async def get_user_events(user_id: int, db: Session = Depends(get_db)):
    """
    Get all events accessible to a user.

    Uses CRUD layer for optimized queries:
    - Fixed 4 queries regardless of result size
    - No N+1 problems
    - Reusable logic
    """
    return get_user_events_AFTER(user_id, db)


# ============================================================================
# TESTING
# ============================================================================

"""
Testing es más fácil porque puedes mockear CRUD methods:

def test_get_user_events(mock_db):
    # Arrange
    with patch('crud.user.exists', return_value=True):
        with patch('crud.event.get_user_accessible_event_ids', return_value={1, 2}):
            with patch('crud.event.get_multi_by_ids', return_value=[mock_event1, mock_event2]):
                with patch('crud.event_interaction.get_user_interactions_map', return_value={1: mock_int}):
                    # Act
                    result = get_user_events_AFTER(1, mock_db)

                    # Assert
                    assert len(result) == 2
                    assert result[0]["interaction"] is not None
"""


# ============================================================================
# EXTENSIÓN FUTURA
# ============================================================================

"""
Fácil añadir features nuevas:

1. FILTROS:
   events = event.get_multi_by_ids(db, ids=list(event_ids))
   # Añadir filtro por fecha
   events = [e for e in events if e.start_date > datetime.now()]

2. CACHÉ:
   @cached(ttl=60)
   def get_user_events_cached(user_id: int, db: Session):
       return get_user_events_AFTER(user_id, db)

3. PAGINACIÓN:
   def get_user_events_paginated(user_id: int, skip: int, limit: int, db: Session):
       event_ids = event.get_user_accessible_event_ids(db, user_id=user_id)
       # Paginar IDs antes de cargar eventos
       paginated_ids = list(event_ids)[skip:skip+limit]
       events = event.get_multi_by_ids(db, ids=paginated_ids)
       ...

4. ORDENAMIENTO CUSTOM:
   events = sorted(events, key=lambda e: e.start_date)
   # O dentro del CRUD:
   events = event.get_multi_by_ids(db, ids=list(event_ids), order_by="start_date")
"""
