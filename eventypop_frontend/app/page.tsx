export default function Home() {
  return (
    <main className="flex min-h-screen flex-col">
      {/* Hero Section */}
      <section className="flex flex-col items-center justify-center px-24 py-32 bg-gradient-to-b from-blue-50 to-white">
        <h1 className="text-6xl font-bold mb-6 text-center">
          EventyPop
        </h1>
        <p className="text-xl text-muted-foreground text-center max-w-2xl">
          Discover public events and connect with organizations in your area
        </p>
      </section>

      {/* Features Section */}
      <section className="py-24 px-8">
        <div className="max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="p-6">
            <h3 className="text-2xl font-semibold mb-3">Discover Events</h3>
            <p className="text-muted-foreground">
              Browse public events from organizations and creators
            </p>
          </div>
          <div className="p-6">
            <h3 className="text-2xl font-semibold mb-3">Subscribe</h3>
            <p className="text-muted-foreground">
              Follow your favorite organizations and stay updated
            </p>
          </div>
          <div className="p-6">
            <h3 className="text-2xl font-semibold mb-3">Share</h3>
            <p className="text-muted-foreground">
              Share calendars with friends using unique share codes
            </p>
          </div>
        </div>
      </section>
    </main>
  );
}
