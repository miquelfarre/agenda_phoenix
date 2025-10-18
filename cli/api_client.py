"""
API Client with automatic logging
Wraps all HTTP requests to log URL, method, response, and JSON data
"""
import requests
import json
import logging
from datetime import datetime
from typing import Optional, Dict, Any


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('cli_api_calls.log', encoding='utf-8'),
        logging.StreamHandler()  # Also print to console if needed
    ]
)

logger = logging.getLogger(__name__)


def _log_request(method: str, url: str, data: Optional[Dict] = None, params: Optional[Dict] = None):
    """Log the outgoing request"""
    logger.info("="*80)
    logger.info(f"REQUEST: {method} {url}")
    if params:
        logger.info(f"PARAMS: {json.dumps(params, indent=2, ensure_ascii=False)}")
    if data:
        logger.info(f"BODY: {json.dumps(data, indent=2, ensure_ascii=False)}")


def _log_response(response: requests.Response):
    """Log the response received"""
    logger.info(f"RESPONSE: {response.status_code} {response.reason}")
    logger.info(f"URL: {response.url}")

    try:
        response_json = response.json()
        logger.info(f"JSON: {json.dumps(response_json, indent=2, ensure_ascii=False)}")
    except:
        logger.info(f"BODY: {response.text[:500]}")  # First 500 chars if not JSON

    logger.info("="*80)
    logger.info("")  # Empty line for readability


def get(url: str, params: Optional[Dict] = None, **kwargs) -> requests.Response:
    """GET request with logging"""
    _log_request("GET", url, params=params)
    response = requests.get(url, params=params, **kwargs)
    _log_response(response)
    return response


def post(url: str, data: Optional[Dict] = None, json: Optional[Dict] = None, **kwargs) -> requests.Response:
    """POST request with logging"""
    _log_request("POST", url, data=json or data)
    if json is not None:
        response = requests.post(url, json=json, **kwargs)
    else:
        response = requests.post(url, data=data, **kwargs)
    _log_response(response)
    return response


def put(url: str, data: Optional[Dict] = None, json: Optional[Dict] = None, **kwargs) -> requests.Response:
    """PUT request with logging"""
    _log_request("PUT", url, data=json or data)
    if json is not None:
        response = requests.put(url, json=json, **kwargs)
    else:
        response = requests.put(url, data=data, **kwargs)
    _log_response(response)
    return response


def patch(url: str, data: Optional[Dict] = None, json: Optional[Dict] = None, **kwargs) -> requests.Response:
    """PATCH request with logging"""
    _log_request("PATCH", url, data=json or data)
    if json is not None:
        response = requests.patch(url, json=json, **kwargs)
    else:
        response = requests.patch(url, data=data, **kwargs)
    _log_response(response)
    return response


def delete(url: str, **kwargs) -> requests.Response:
    """DELETE request with logging"""
    _log_request("DELETE", url)
    response = requests.delete(url, **kwargs)
    _log_response(response)
    return response
