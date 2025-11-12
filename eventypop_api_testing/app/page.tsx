"use client";

import { useState } from "react";
import { TestUser } from "@/lib/api-client";
import { Endpoint } from "@/lib/endpoints";
import UserSelector from "@/components/user-selector";
import EndpointList from "@/components/endpoint-list";
import EndpointTester from "@/components/endpoint-tester";

export default function Home() {
  const [selectedUser, setSelectedUser] = useState<TestUser | null>(null);
  const [selectedEndpoint, setSelectedEndpoint] = useState<Endpoint | null>(null);

  return (
    <div className="flex h-screen bg-slate-50">
      {/* User Selector - Left Sidebar */}
      <UserSelector
        selectedUser={selectedUser}
        onSelectUser={setSelectedUser}
      />

      {/* Endpoint List - Middle Sidebar */}
      <EndpointList
        currentUser={selectedUser}
        onSelectEndpoint={setSelectedEndpoint}
        selectedEndpoint={selectedEndpoint}
      />

      {/* Endpoint Tester - Main Content */}
      <EndpointTester
        endpoint={selectedEndpoint}
        currentUser={selectedUser}
      />
    </div>
  );
}
