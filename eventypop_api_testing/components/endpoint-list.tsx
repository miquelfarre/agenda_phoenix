"use client";

import { useState } from "react";
import { ENDPOINTS, ENDPOINT_CATEGORIES, Endpoint } from "@/lib/endpoints";
import { TestUser } from "@/lib/api-client";

interface EndpointListProps {
  currentUser: TestUser | null;
  onSelectEndpoint: (endpoint: Endpoint) => void;
  selectedEndpoint: Endpoint | null;
}

export default function EndpointList({ currentUser, onSelectEndpoint, selectedEndpoint }: EndpointListProps) {
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [search, setSearch] = useState('');

  // Filter endpoints based on user type and category
  const filteredEndpoints = ENDPOINTS.filter((endpoint) => {
    // Filter by user type
    if (currentUser) {
      if (endpoint.userType !== 'both' && endpoint.userType !== currentUser.type) {
        return false;
      }
    }

    // Filter by category
    if (selectedCategory !== 'all' && endpoint.category !== selectedCategory) {
      return false;
    }

    // Filter by search
    if (search && !endpoint.name.toLowerCase().includes(search.toLowerCase())) {
      return false;
    }

    return true;
  });

  const getMethodColor = (method: string) => {
    switch (method) {
      case 'GET': return 'text-green-600 bg-green-50';
      case 'POST': return 'text-blue-600 bg-blue-50';
      case 'PUT': return 'text-orange-600 bg-orange-50';
      case 'PATCH': return 'text-yellow-600 bg-yellow-50';
      case 'DELETE': return 'text-red-600 bg-red-50';
      default: return 'text-slate-600 bg-slate-50';
    }
  };

  if (!currentUser) {
    return (
      <div className="flex items-center justify-center h-full text-slate-500">
        <div className="text-center">
          <div className="text-4xl mb-4">👈</div>
          <div className="text-lg font-medium">Select a user to start testing</div>
          <div className="text-sm mt-2">Choose from private or public users</div>
        </div>
      </div>
    );
  }

  return (
    <div className="border-r border-slate-200 bg-white w-96 flex flex-col h-screen">
      {/* Header */}
      <div className="p-4 border-b border-slate-200">
        <h2 className="text-lg font-semibold text-slate-900 mb-3">Endpoints</h2>

        {/* Search */}
        <input
          type="text"
          placeholder="Search endpoints..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {/* Categories */}
      <div className="p-4 border-b border-slate-200 space-y-2">
        <button
          onClick={() => setSelectedCategory('all')}
          className={`w-full px-3 py-2 rounded-lg text-left text-sm font-medium transition-colors ${
            selectedCategory === 'all'
              ? 'bg-blue-100 text-blue-700'
              : 'text-slate-600 hover:bg-slate-100'
          }`}
        >
          📋 All Endpoints ({filteredEndpoints.length})
        </button>
        {ENDPOINT_CATEGORIES.map((category) => {
          const count = ENDPOINTS.filter(e => e.category === category.id).length;
          return (
            <button
              key={category.id}
              onClick={() => setSelectedCategory(category.id)}
              className={`w-full px-3 py-2 rounded-lg text-left text-sm font-medium transition-colors ${
                selectedCategory === category.id
                  ? 'bg-blue-100 text-blue-700'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              {category.icon} {category.name} ({count})
            </button>
          );
        })}
      </div>

      {/* Endpoint List */}
      <div className="flex-1 overflow-y-auto">
        {filteredEndpoints.length === 0 ? (
          <div className="p-8 text-center text-slate-500">
            <div className="text-2xl mb-2">🔍</div>
            <div className="text-sm">No endpoints found</div>
          </div>
        ) : (
          filteredEndpoints.map((endpoint) => (
            <button
              key={endpoint.id}
              onClick={() => onSelectEndpoint(endpoint)}
              className={`w-full p-4 text-left border-b border-slate-100 transition-colors hover:bg-slate-50 ${
                selectedEndpoint?.id === endpoint.id
                  ? 'bg-blue-50 border-l-4 border-l-blue-500'
                  : ''
              }`}
            >
              <div className="flex items-start gap-3">
                <span className={`px-2 py-1 rounded text-xs font-semibold ${getMethodColor(endpoint.method)}`}>
                  {endpoint.method}
                </span>
                <div className="flex-1 min-w-0">
                  <div className="font-medium text-slate-900 mb-1">
                    {endpoint.name}
                  </div>
                  <div className="text-xs text-slate-500 font-mono truncate">
                    {endpoint.path}
                  </div>
                  <div className="text-xs text-slate-600 mt-2">
                    {endpoint.description}
                  </div>
                </div>
              </div>
            </button>
          ))
        )}
      </div>
    </div>
  );
}
