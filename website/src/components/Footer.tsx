import Link from "next/link";

export function Footer() {
  return (
    <footer className="bg-brand-bg border-t border-white/5 py-16">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-10">
          {/* Brand */}
          <div className="md:col-span-1">
            <div className="flex items-center gap-2 mb-4">
              <span className="text-2xl">🔥</span>
              <span className="text-xl font-bold text-gradient">
                Macro Maxxing
              </span>
            </div>
            <p className="text-gray-400 text-sm">
              log the mog. The AI-powered macro tracker built for serious
              athletes.
            </p>
          </div>

          {/* Features */}
          <div>
            <h4 className="font-semibold text-white mb-4">Features</h4>
            <ul className="space-y-2 text-sm text-gray-400">
              <li>
                <Link
                  href="/ai-food-scanner"
                  className="hover:text-white transition"
                >
                  AI Food Scanner
                </Link>
              </li>
              <li>
                <Link
                  href="/voice-food-logging"
                  className="hover:text-white transition"
                >
                  Voice Food Logging
                </Link>
              </li>
              <li>
                <Link
                  href="/workout-tracker-app"
                  className="hover:text-white transition"
                >
                  Workout Tracker
                </Link>
              </li>
              <li>
                <Link
                  href="/intermittent-fasting-tracker"
                  className="hover:text-white transition"
                >
                  Fasting Tracker
                </Link>
              </li>
            </ul>
          </div>

          {/* Resources */}
          <div>
            <h4 className="font-semibold text-white mb-4">Compare</h4>
            <ul className="space-y-2 text-sm text-gray-400">
              <li>
                <Link
                  href="/best-macro-tracking-app"
                  className="hover:text-white transition"
                >
                  Best Macro Tracking App
                </Link>
              </li>
              <li>
                <Link
                  href="/calorie-counter-app"
                  className="hover:text-white transition"
                >
                  Calorie Counter App
                </Link>
              </li>
            </ul>
          </div>

          {/* Download */}
          <div>
            <h4 className="font-semibold text-white mb-4">Get the App</h4>
            <a
              href="#download"
              className="inline-block bg-brand-purple hover:bg-brand-purple/80 text-white px-6 py-3 rounded-full font-semibold transition text-sm"
            >
              Download for iOS
            </a>
            <p className="text-gray-500 text-xs mt-3">
              Requires iOS 17 or later.
            </p>
          </div>
        </div>

        <div className="border-t border-white/5 mt-12 pt-8 flex flex-col sm:flex-row justify-between items-center text-xs text-gray-500">
          <p>&copy; {new Date().getFullYear()} Macro Maxxing. All rights reserved.</p>
          <div className="flex gap-6 mt-4 sm:mt-0">
            <Link href="#" className="hover:text-white transition">
              Privacy Policy
            </Link>
            <Link href="#" className="hover:text-white transition">
              Terms of Service
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
