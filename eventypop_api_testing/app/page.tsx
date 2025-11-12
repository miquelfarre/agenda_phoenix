export default function Home() {
  return (
    <main className="min-h-screen p-8">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-4xl font-bold mb-2">EventyPop API Testing</h1>
        <p className="text-lg text-slate-600 mb-8">
          Test and interact with the EventyPop API
        </p>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white p-6 rounded-lg shadow border border-slate-200">
            <h2 className="text-xl font-semibold mb-2">Users</h2>
            <p className="text-slate-600">Test user-related endpoints</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow border border-slate-200">
            <h2 className="text-xl font-semibold mb-2">Events</h2>
            <p className="text-slate-600">Test event-related endpoints</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow border border-slate-200">
            <h2 className="text-xl font-semibold mb-2">Calendars</h2>
            <p className="text-slate-600">Test calendar-related endpoints</p>
          </div>
        </div>
      </div>
    </main>
  );
}
