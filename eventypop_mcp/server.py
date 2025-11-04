#!/usr/bin/env python3
"""
EventyPop MCP Server
Provides dynamic metadata about operations, API schemas, and intelligent workflows
"""

import asyncio
import json
import yaml
from pathlib import Path
from typing import Any, Dict, List, Optional

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent


# Load schemas
SCHEMAS_DIR = Path(__file__).parent / "schemas"

with open(SCHEMAS_DIR / "operations.yaml") as f:
    OPERATIONS = yaml.safe_load(f)["operations"]

with open(SCHEMAS_DIR / "workflows.yaml") as f:
    WORKFLOWS_DATA = yaml.safe_load(f)
    WORKFLOWS = WORKFLOWS_DATA["workflows"]
    WORKFLOW_CONFIG = {
        "max_suggestions": WORKFLOWS_DATA.get("max_suggestions", 3),
        "priority_order": WORKFLOWS_DATA.get("priority_order", ["high", "medium", "low"]),
        "overflow_strategy": WORKFLOWS_DATA.get("overflow_strategy", "highest_priority"),
    }


app = Server("eventypop-mcp")


def resolve_template(template: str, context: Dict[str, Any]) -> Any:
    """
    Resuelve templates del tipo {result.id} o {parameters.calendar_id}
    """
    if not isinstance(template, str) or not template.startswith("{"):
        return template

    # Remove braces
    path = template.strip("{}")

    # Split by dot
    parts = path.split(".")

    # Navigate through context
    value = context
    for part in parts:
        if isinstance(value, dict):
            value = value.get(part)
        else:
            return None

    return value


def apply_conditions(condition: Dict[str, Any], context: Dict[str, Any]) -> bool:
    """
    Evalúa si una condición se cumple dado el contexto
    """
    if "field" in condition:
        field_value = context.get("parameters", {}).get(condition["field"])

        if "value" in condition:
            if field_value != condition["value"]:
                return False

        if "is_null" in condition and condition["is_null"]:
            if field_value is not None:
                return False

        if "exists" in condition and condition["exists"]:
            if field_value is None:
                return False

    if "and" in condition:
        return apply_conditions(condition["and"], context)

    # Check special conditions
    if "user_has_groups" in condition:
        # TODO: This would need to check actual user data
        return condition["user_has_groups"]

    if "has" in condition:
        field = condition["has"]
        return field in context.get("parameters", {})

    return True


@app.list_tools()
async def list_tools() -> List[Tool]:
    """
    Lista todas las herramientas disponibles en el MCP server
    """
    return [
        Tool(
            name="get_operation_schema",
            description="Get the complete schema for a voice command operation",
            inputSchema={
                "type": "object",
                "properties": {
                    "operation": {
                        "type": "string",
                        "description": "The operation name (e.g., CREATE_CALENDAR, CREATE_EVENT)",
                    },
                    "language": {
                        "type": "string",
                        "description": "Language for questions (es, en, ca)",
                        "default": "es",
                    },
                },
                "required": ["operation"],
            },
        ),
        Tool(
            name="get_workflow_suggestions",
            description="Get suggested follow-up actions after completing an operation",
            inputSchema={
                "type": "object",
                "properties": {
                    "completed_action": {
                        "type": "string",
                        "description": "The action that was just completed",
                    },
                    "result": {
                        "type": "object",
                        "description": "The result returned by the API",
                    },
                    "parameters": {
                        "type": "object",
                        "description": "The parameters used in the completed action",
                    },
                    "language": {
                        "type": "string",
                        "description": "Language for questions (es, en, ca)",
                        "default": "es",
                    },
                },
                "required": ["completed_action"],
            },
        ),
        Tool(
            name="validate_parameters",
            description="Validate parameters for an operation before sending to API",
            inputSchema={
                "type": "object",
                "properties": {
                    "operation": {
                        "type": "string",
                        "description": "The operation name",
                    },
                    "parameters": {
                        "type": "object",
                        "description": "The parameters to validate",
                    },
                },
                "required": ["operation", "parameters"],
            },
        ),
        Tool(
            name="list_operations",
            description="List all available operations",
            inputSchema={
                "type": "object",
                "properties": {},
            },
        ),
        Tool(
            name="get_required_fields",
            description="Get only the required fields for an operation",
            inputSchema={
                "type": "object",
                "properties": {
                    "operation": {
                        "type": "string",
                        "description": "The operation name",
                    },
                },
                "required": ["operation"],
            },
        ),
    ]


@app.call_tool()
async def call_tool(name: str, arguments: Dict[str, Any]) -> List[TextContent]:
    """
    Maneja las llamadas a las herramientas del MCP server
    """
    if name == "get_operation_schema":
        return await handle_get_operation_schema(arguments)
    elif name == "get_workflow_suggestions":
        return await handle_get_workflow_suggestions(arguments)
    elif name == "validate_parameters":
        return await handle_validate_parameters(arguments)
    elif name == "list_operations":
        return await handle_list_operations(arguments)
    elif name == "get_required_fields":
        return await handle_get_required_fields(arguments)
    else:
        return [TextContent(type="text", text=f"Unknown tool: {name}")]


async def handle_get_operation_schema(args: Dict[str, Any]) -> List[TextContent]:
    """
    Retorna el schema completo de una operación
    """
    operation = args["operation"]
    language = args.get("language", "es")

    if operation not in OPERATIONS:
        return [
            TextContent(
                type="text",
                text=json.dumps({"error": f"Operation '{operation}' not found"}, indent=2),
            )
        ]

    op_schema = OPERATIONS[operation]

    # Build response with localized questions
    result = {
        "operation": operation,
        "description": op_schema.get("description", ""),
        "endpoint": op_schema.get("endpoint", {}),
        "confirmation_required": op_schema.get("confirmation_required", False),
        "fields": {},
    }

    # Process each field
    for field_name, field_def in op_schema.get("fields", {}).items():
        field_info = {
            "type": field_def.get("type"),
            "required": field_def.get("required", False),
            "default": field_def.get("default"),
            "auto_from_context": field_def.get("auto_from_context", False),
        }

        # Add validation info
        if "max_length" in field_def:
            field_info["max_length"] = field_def["max_length"]
        if "format" in field_def:
            field_info["format"] = field_def["format"]
        if "options" in field_def:
            field_info["options"] = field_def["options"]
        if "validation" in field_def:
            field_info["validation"] = field_def["validation"]

        # Add localized question
        if "questions" in field_def:
            questions = field_def["questions"]
            if isinstance(questions, dict):
                field_info["question"] = questions.get(language, questions.get("es"))
            else:
                field_info["question"] = questions

        # Add dynamic questions for conditional fields
        if "dynamic_questions" in field_def:
            field_info["dynamic_questions"] = field_def["dynamic_questions"]

        # Add dependencies
        if "depends_on" in field_def:
            field_info["depends_on"] = field_def["depends_on"]

        # Add value mapping for natural language
        if "value_mapping" in field_def:
            mapping = field_def["value_mapping"]
            if language in mapping:
                field_info["value_mapping"] = mapping[language]

        result["fields"][field_name] = field_info

    return [TextContent(type="text", text=json.dumps(result, indent=2, ensure_ascii=False))]


async def handle_get_workflow_suggestions(args: Dict[str, Any]) -> List[TextContent]:
    """
    Retorna sugerencias de acciones después de completar una operación
    """
    completed_action = args["completed_action"]
    result = args.get("result", {})
    parameters = args.get("parameters", {})
    language = args.get("language", "es")

    if completed_action not in WORKFLOWS:
        return [
            TextContent(
                type="text",
                text=json.dumps({"suggestions": []}, indent=2),
            )
        ]

    workflow = WORKFLOWS[completed_action]
    context = {"result": result, "parameters": parameters}

    suggestions = []

    for suggestion in workflow.get("suggestions", []):
        # Check conditions
        if "condition" in suggestion:
            if not apply_conditions(suggestion["condition"], context):
                continue

        # Resolve template parameters
        default_params = {}
        for key, value in suggestion.get("default_parameters", {}).items():
            default_params[key] = resolve_template(value, context)

        # Get localized question
        questions = suggestion.get("questions", {})
        if isinstance(questions, dict):
            question = questions.get(language, questions.get("es"))
        else:
            question = questions

        suggestions.append(
            {
                "action": suggestion["action"],
                "priority": suggestion.get("priority", "medium"),
                "question": question,
                "default_parameters": default_params,
            }
        )

    # Sort by priority
    priority_order = WORKFLOW_CONFIG["priority_order"]
    suggestions.sort(key=lambda s: priority_order.index(s["priority"]))

    # Apply max suggestions limit
    max_suggestions = WORKFLOW_CONFIG["max_suggestions"]
    if len(suggestions) > max_suggestions:
        overflow_strategy = WORKFLOW_CONFIG["overflow_strategy"]
        if overflow_strategy == "highest_priority":
            suggestions = suggestions[:max_suggestions]

    return [
        TextContent(
            type="text",
            text=json.dumps({"suggestions": suggestions}, indent=2, ensure_ascii=False),
        )
    ]


async def handle_validate_parameters(args: Dict[str, Any]) -> List[TextContent]:
    """
    Valida los parámetros de una operación
    """
    operation = args["operation"]
    parameters = args["parameters"]

    if operation not in OPERATIONS:
        return [
            TextContent(
                type="text",
                text=json.dumps({"error": f"Operation '{operation}' not found"}, indent=2),
            )
        ]

    op_schema = OPERATIONS[operation]
    missing_required = []
    validation_errors = []

    for field_name, field_def in op_schema.get("fields", {}).items():
        is_required = field_def.get("required", False)
        value = parameters.get(field_name)

        # Check required fields
        if is_required and (value is None or value == ""):
            missing_required.append(field_name)
            continue

        # Skip validation if field is not provided and not required
        if value is None:
            continue

        # Validate max_length
        if "max_length" in field_def and isinstance(value, str):
            if len(value) > field_def["max_length"]:
                validation_errors.append(
                    {
                        "field": field_name,
                        "error": f"exceeds max length of {field_def['max_length']}",
                    }
                )

        # Validate options
        if "options" in field_def:
            if value not in field_def["options"]:
                validation_errors.append(
                    {
                        "field": field_name,
                        "error": f"invalid value, must be one of: {field_def['options']}",
                    }
                )

        # Validate format
        if "format" in field_def:
            if field_def["format"] == "email":
                if "@" not in str(value):
                    validation_errors.append(
                        {"field": field_name, "error": "invalid email format"}
                    )

    result = {
        "valid": len(missing_required) == 0 and len(validation_errors) == 0,
        "missing_required": missing_required,
        "validation_errors": validation_errors,
    }

    return [TextContent(type="text", text=json.dumps(result, indent=2))]


async def handle_list_operations(args: Dict[str, Any]) -> List[TextContent]:
    """
    Lista todas las operaciones disponibles
    """
    operations = [
        {"name": op_name, "description": op_data.get("description", "")}
        for op_name, op_data in OPERATIONS.items()
    ]

    return [TextContent(type="text", text=json.dumps({"operations": operations}, indent=2))]


async def handle_get_required_fields(args: Dict[str, Any]) -> List[TextContent]:
    """
    Retorna solo los campos obligatorios de una operación
    """
    operation = args["operation"]

    if operation not in OPERATIONS:
        return [
            TextContent(
                type="text",
                text=json.dumps({"error": f"Operation '{operation}' not found"}, indent=2),
            )
        ]

    op_schema = OPERATIONS[operation]
    required_fields = [
        field_name
        for field_name, field_def in op_schema.get("fields", {}).items()
        if field_def.get("required", False)
    ]

    return [
        TextContent(
            type="text",
            text=json.dumps({"operation": operation, "required_fields": required_fields}, indent=2),
        )
    ]


async def main():
    """
    Punto de entrada principal del servidor MCP
    """
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
