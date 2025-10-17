"""Configuration for Agenda Phoenix CLI"""
import os

# API Base URL - can be overridden with AGENDA_API_URL environment variable
API_BASE_URL = os.getenv("AGENDA_API_URL", "http://localhost:8001")
