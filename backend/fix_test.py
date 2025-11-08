#!/usr/bin/env python3
"""Script para convertir test_user_events_public_owner.py a usar TestClient"""

import re

# Leer archivo
with open('func_tests/test_user_events_public_owner.py', 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    # Reemplazar api_request calls
    if 'api_request(' in line:
        # Extraer método y endpoint
        if '"POST", "/users"' in line:
            line = line.replace('api_request("POST", "/users"', 'client.post("/api/v1/users"')
            line = line.replace(', json=', ', json=')
        elif '"POST", "/contacts"' in line:
            line = line.replace('api_request("POST", "/contacts"', 'client.post("/api/v1/contacts"')
        elif '"POST", "/events"' in line:
            # Necesita auth context
            if ', user_id=' in line:
                user_id_match = re.search(r'user_id=(\w+\["id"\])', line)
                if user_id_match:
                    user_id = user_id_match.group(1)
                    indent = len(line) - len(line.lstrip())
                    auth_line = ' ' * indent + f'client._auth_context["user_id"] = {user_id}\n'
                    new_lines.append(auth_line)
                line = re.sub(r', user_id=\w+\["id"\]', '', line)
            line = line.replace('api_request("POST", "/events"', 'client.post("/api/v1/events"')
        elif '"POST", "/interactions"' in line:
            # Necesita auth context
            if ', user_id=' in line:
                user_id_match = re.search(r'user_id=(\w+\["id"\])', line)
                if user_id_match:
                    user_id = user_id_match.group(1)
                    indent = len(line) - len(line.lstrip())
                    auth_line = ' ' * indent + f'client._auth_context["user_id"] = {user_id}\n'
                    new_lines.append(auth_line)
                line = re.sub(r', user_id=\w+\["id"\]', '', line)
            line = line.replace('api_request("POST", "/interactions"', 'client.post("/api/v1/interactions"')
        elif '"GET"' in line and '/users/' in line:
            # GET /users/{id}/events
            if ', user_id=' in line:
                user_id_match = re.search(r'user_id=(\w+\["id"\])', line)
                if user_id_match:
                    user_id = user_id_match.group(1)
                    indent = len(line) - len(line.lstrip())
                    auth_line = ' ' * indent + f'client._auth_context["user_id"] = {user_id}\n'
                    new_lines.append(auth_line)
                line = re.sub(r', user_id=\w+\["id"\]', '', line)
            line = line.replace('api_request("GET",', 'client.get(')
            # Arreglar el formato de la URL si usa f-string
            if 'f"/users/' in line:
                line = line.replace('f"/users/', 'f"/api/v1/users/')
        elif '"PATCH"' in line:
            # PATCH /events/{id}
            if ', user_id=' in line:
                user_id_match = re.search(r'user_id=(\w+\["id"\])', line)
                if user_id_match:
                    user_id = user_id_match.group(1)
                    indent = len(line) - len(line.lstrip())
                    auth_line = ' ' * indent + f'client._auth_context["user_id"] = {user_id}\n'
                    new_lines.append(auth_line)
                line = re.sub(r', user_id=\w+\["id"\]', '', line)
            line = line.replace('api_request("PATCH",', 'client.patch(')
            if 'f"/events/' in line:
                line = line.replace('f"/events/', 'f"/api/v1/events/')

    new_lines.append(line)

# Agregar fixture de client al segundo test
fixed_lines = []
for i, line in enumerate(new_lines):
    if 'def test_user_events_preserves_owner_info_across_updates():' in line:
        line = line.replace('():', '(client):')
    fixed_lines.append(line)

# Escribir archivo
with open('func_tests/test_user_events_public_owner.py', 'w') as f:
    f.writelines(fixed_lines)

print("✅ Archivo actualizado!")
