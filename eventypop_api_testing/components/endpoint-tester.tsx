"use client";

import { useState } from "react";
import { Endpoint, EndpointParam } from "@/lib/endpoints";
import { apiClient, TestUser } from "@/lib/api-client";

interface EndpointTesterProps {
  endpoint: Endpoint | null;
  currentUser: TestUser | null;
}

interface RequestData {
  pathParams: Record<string, any>;
  queryParams: Record<string, any>;
  bodyParams: Record<string, any>;
}

interface Response {
  data: any;
  status: number;
  error?: string;
  duration: number;
}

export default function EndpointTester({ endpoint, currentUser }: EndpointTesterProps) {
  const [requestData, setRequestData] = useState<RequestData>({
    pathParams: {},
    queryParams: {},
    bodyParams: {},
  });
  const [response, setResponse] = useState<Response | null>(null);
  const [loading, setLoading] = useState(false);

  const updateParam = (type: keyof RequestData, name: string, value: any) => {
    setRequestData((prev) => ({
      ...prev,
      [type]: { ...prev[type], [name]: value },
    }));
  };

  const buildUrl = () => {
    if (!endpoint) return '';

    let url = endpoint.path;

    // Replace path params
    Object.entries(requestData.pathParams).forEach(([key, value]) => {
      url = url.replace(`:${key}`, String(value));
    });

    // Add query params
    const queryString = new URLSearchParams(
      Object.entries(requestData.queryParams)
        .filter(([, value]) => value !== '')
        .map(([key, value]) => [key, String(value)])
    ).toString();

    if (queryString) {
      url += `?${queryString}`;
    }

    return url;
  };

  const handleTest = async () => {
    if (!endpoint || !currentUser) return;

    setLoading(true);
    setResponse(null);

    const startTime = Date.now();

    try {
      apiClient.setUser(currentUser);
      const url = buildUrl();

      let data: any;

      switch (endpoint.method) {
        case 'GET':
          data = await apiClient.get(url);
          break;
        case 'POST':
          data = await apiClient.post(url, requestData.bodyParams);
          break;
        case 'PUT':
          data = await apiClient.put(url, requestData.bodyParams);
          break;
        case 'PATCH':
          data = await apiClient.patch(url, requestData.bodyParams);
          break;
        case 'DELETE':
          data = await apiClient.delete(url);
          break;
        default:
          throw new Error(`Unsupported method: ${endpoint.method}`);
      }

      const duration = Date.now() - startTime;

      setResponse({
        data,
        status: 200,
        duration,
      });
    } catch (error: any) {
      const duration = Date.now() - startTime;

      setResponse({
        data: error.response?.data || null,
        status: error.response?.status || 500,
        error: error.message,
        duration,
      });
    } finally {
      setLoading(false);
    }
  };

  const renderParamInput = (param: EndpointParam, type: keyof RequestData) => {
    const value = requestData[type][param.name] || '';

    return (
      <div key={param.name} className="space-y-2">
        <label className="block">
          <div className="flex items-center gap-2 mb-1">
            <span className="text-sm font-medium text-slate-700">{param.name}</span>
            {param.required && (
              <span className="text-xs text-red-500">*required</span>
            )}
            <span className="text-xs text-slate-500">({param.type})</span>
          </div>
          {param.description && (
            <div className="text-xs text-slate-500 mb-2">{param.description}</div>
          )}
          {param.type === 'array' ? (
            <textarea
              value={value}
              onChange={(e) => updateParam(type, param.name, e.target.value)}
              placeholder={param.example ? JSON.stringify(param.example) : '[]'}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-blue-500"
              rows={2}
            />
          ) : param.type === 'boolean' ? (
            <select
              value={value}
              onChange={(e) => updateParam(type, param.name, e.target.value === 'true')}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select...</option>
              <option value="true">true</option>
              <option value="false">false</option>
            </select>
          ) : (
            <input
              type={param.type === 'number' ? 'number' : 'text'}
              value={value}
              onChange={(e) => updateParam(type, param.name, e.target.value)}
              placeholder={param.example ? String(param.example) : ''}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          )}
        </label>
      </div>
    );
  };

  if (!endpoint) {
    return (
      <div className="flex-1 flex items-center justify-center text-slate-500">
        <div className="text-center">
          <div className="text-4xl mb-4">⚡</div>
          <div className="text-lg font-medium">Select an endpoint to test</div>
          <div className="text-sm mt-2">Choose from the list on the left</div>
        </div>
      </div>
    );
  }

  const getMethodColor = (method: string) => {
    switch (method) {
      case 'GET': return 'text-green-600 bg-green-50 border-green-200';
      case 'POST': return 'text-blue-600 bg-blue-50 border-blue-200';
      case 'PUT': return 'text-orange-600 bg-orange-50 border-orange-200';
      case 'PATCH': return 'text-yellow-600 bg-yellow-50 border-yellow-200';
      case 'DELETE': return 'text-red-600 bg-red-50 border-red-200';
      default: return 'text-slate-600 bg-slate-50 border-slate-200';
    }
  };

  return (
    <div className="flex-1 flex flex-col h-screen overflow-hidden">
      {/* Header */}
      <div className="p-6 border-b border-slate-200 bg-white">
        <div className="flex items-start gap-4">
          <span className={`px-3 py-1.5 rounded-lg text-sm font-semibold border ${getMethodColor(endpoint.method)}`}>
            {endpoint.method}
          </span>
          <div className="flex-1">
            <h2 className="text-xl font-semibold text-slate-900 mb-1">{endpoint.name}</h2>
            <p className="text-sm text-slate-600 mb-2">{endpoint.description}</p>
            <code className="text-sm text-slate-700 bg-slate-100 px-3 py-1 rounded">
              {buildUrl()}
            </code>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="grid grid-cols-2 gap-6 p-6">
          {/* Request Builder */}
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-semibold text-slate-900 mb-4">Request</h3>

              {/* Path Params */}
              {endpoint.pathParams && endpoint.pathParams.length > 0 && (
                <div className="mb-6">
                  <h4 className="text-sm font-semibold text-slate-700 mb-3">Path Parameters</h4>
                  <div className="space-y-3">
                    {endpoint.pathParams.map((param) => renderParamInput(param, 'pathParams'))}
                  </div>
                </div>
              )}

              {/* Query Params */}
              {endpoint.queryParams && endpoint.queryParams.length > 0 && (
                <div className="mb-6">
                  <h4 className="text-sm font-semibold text-slate-700 mb-3">Query Parameters</h4>
                  <div className="space-y-3">
                    {endpoint.queryParams.map((param) => renderParamInput(param, 'queryParams'))}
                  </div>
                </div>
              )}

              {/* Body Params */}
              {endpoint.bodyParams && endpoint.bodyParams.length > 0 && (
                <div className="mb-6">
                  <h4 className="text-sm font-semibold text-slate-700 mb-3">Request Body</h4>
                  <div className="space-y-3">
                    {endpoint.bodyParams.map((param) => renderParamInput(param, 'bodyParams'))}
                  </div>
                </div>
              )}

              {/* Send Button */}
              <button
                onClick={handleTest}
                disabled={loading || !currentUser}
                className={`w-full px-6 py-3 rounded-lg font-semibold transition-colors ${
                  loading
                    ? 'bg-slate-300 text-slate-600 cursor-not-allowed'
                    : 'bg-blue-600 text-white hover:bg-blue-700'
                }`}
              >
                {loading ? 'Sending...' : '⚡ Send Request'}
              </button>
            </div>
          </div>

          {/* Response Viewer */}
          <div>
            <h3 className="text-lg font-semibold text-slate-900 mb-4">Response</h3>

            {response ? (
              <div className="space-y-4">
                {/* Status */}
                <div className="flex items-center gap-4">
                  <div className={`px-3 py-1.5 rounded-lg font-semibold ${
                    response.status < 300
                      ? 'bg-green-100 text-green-700'
                      : response.status < 400
                      ? 'bg-yellow-100 text-yellow-700'
                      : 'bg-red-100 text-red-700'
                  }`}>
                    Status: {response.status}
                  </div>
                  <div className="text-sm text-slate-600">
                    ⏱️ {response.duration}ms
                  </div>
                </div>

                {/* Error */}
                {response.error && (
                  <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                    <div className="text-sm font-semibold text-red-700 mb-1">Error</div>
                    <div className="text-sm text-red-600">{response.error}</div>
                  </div>
                )}

                {/* Data */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <div className="text-sm font-semibold text-slate-700">Response Body</div>
                    <button
                      onClick={() => {
                        navigator.clipboard.writeText(JSON.stringify(response.data, null, 2));
                      }}
                      className="px-3 py-1 text-xs bg-slate-700 text-white rounded hover:bg-slate-600 transition-colors"
                    >
                      📋 Copy JSON
                    </button>
                  </div>
                  <pre className="bg-slate-900 text-slate-100 p-4 rounded-lg text-xs overflow-x-auto">
                    {JSON.stringify(response.data, null, 2)}
                  </pre>
                </div>
              </div>
            ) : (
              <div className="flex items-center justify-center h-64 text-slate-400 border-2 border-dashed border-slate-200 rounded-lg">
                <div className="text-center">
                  <div className="text-3xl mb-2">📡</div>
                  <div className="text-sm">No response yet</div>
                  <div className="text-xs mt-1">Send a request to see the response</div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
