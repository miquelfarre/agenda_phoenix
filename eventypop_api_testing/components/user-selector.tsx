"use client";

import { useState } from "react";
import { TEST_USERS, TestUser } from "@/lib/api-client";

interface UserSelectorProps {
  selectedUser: TestUser | null;
  onSelectUser: (user: TestUser) => void;
}

export default function UserSelector({ selectedUser, onSelectUser }: UserSelectorProps) {
  const [activeTab, setActiveTab] = useState<'private' | 'public'>('private');

  const privateUsers = TEST_USERS.filter(u => u.type === 'private');
  const publicUsers = TEST_USERS.filter(u => u.type === 'public');

  const usersToShow = activeTab === 'private' ? privateUsers : publicUsers;

  return (
    <div className="border-r border-slate-200 bg-white h-screen w-80 flex flex-col">
      {/* Header */}
      <div className="p-4 border-b border-slate-200">
        <h2 className="text-lg font-semibold text-slate-900">Test Users</h2>
        <p className="text-sm text-slate-600">Select a user to test with</p>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200">
        <button
          onClick={() => setActiveTab('private')}
          className={`flex-1 px-4 py-3 text-sm font-medium transition-colors ${
            activeTab === 'private'
              ? 'border-b-2 border-blue-500 text-blue-600'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          👤 Private ({privateUsers.length})
        </button>
        <button
          onClick={() => setActiveTab('public')}
          className={`flex-1 px-4 py-3 text-sm font-medium transition-colors ${
            activeTab === 'public'
              ? 'border-b-2 border-purple-500 text-purple-600'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          🏢 Public ({publicUsers.length})
        </button>
      </div>

      {/* User List */}
      <div className="flex-1 overflow-y-auto">
        {usersToShow.map((user) => (
          <button
            key={user.id}
            onClick={() => onSelectUser(user)}
            className={`w-full p-4 text-left border-b border-slate-100 transition-colors hover:bg-slate-50 ${
              selectedUser?.id === user.id
                ? 'bg-blue-50 border-l-4 border-l-blue-500'
                : ''
            }`}
          >
            <div className="flex items-start justify-between">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="font-medium text-slate-900 truncate">
                    {user.name}
                  </span>
                  <span className="text-xs text-slate-500">#{user.id}</span>
                </div>
                {user.username && (
                  <div className="text-sm text-purple-600 mt-0.5">
                    {user.username}
                  </div>
                )}
                <div className="text-xs text-slate-500 mt-1">
                  {user.phone}
                </div>
              </div>
              {selectedUser?.id === user.id && (
                <div className="ml-2">
                  <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                </div>
              )}
            </div>
          </button>
        ))}
      </div>

      {/* Selected User Info */}
      {selectedUser && (
        <div className="p-4 border-t border-slate-200 bg-slate-50">
          <div className="text-xs font-medium text-slate-500 mb-1">
            TESTING AS:
          </div>
          <div className="font-semibold text-slate-900">{selectedUser.name}</div>
          <div className="text-xs text-slate-600 mt-1">
            ID: {selectedUser.id} • {selectedUser.type === 'private' ? '👤 Private' : '🏢 Public'}
          </div>
        </div>
      )}
    </div>
  );
}
