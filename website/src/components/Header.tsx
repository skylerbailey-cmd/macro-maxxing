"use client";

import Link from "next/link";
import { useState } from "react";

export function Header() {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-brand-bg/80 backdrop-blur-lg border-b border-white/5">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2">
          <span className="text-2xl">🔥</span>
          <span className="text-xl font-bold text-gradient">Macromaxxing</span>
        </Link>

        {/* Desktop nav */}
        <nav className="hidden md:flex items-center gap-8 text-sm text-gray-300">
          <Link href="/#features" className="hover:text-white transition">
            Features
          </Link>
          <Link href="/#ai-powered" className="hover:text-white transition">
            AI Tracking
          </Link>
          <Link href="/#screenshots" className="hover:text-white transition">
            Screenshots
          </Link>
          <Link
            href="#download"
            className="bg-brand-purple hover:bg-brand-purple/80 text-white px-5 py-2 rounded-full font-semibold transition"
          >
            Download
          </Link>
        </nav>

        {/* Mobile hamburger */}
        <button
          className="md:hidden text-white"
          onClick={() => setMobileOpen(!mobileOpen)}
          aria-label="Toggle menu"
        >
          <svg
            className="w-6 h-6"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            {mobileOpen ? (
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            ) : (
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 6h16M4 12h16M4 18h16"
              />
            )}
          </svg>
        </button>
      </div>

      {/* Mobile menu */}
      {mobileOpen && (
        <nav className="md:hidden bg-brand-card border-t border-white/5 px-6 py-4 space-y-4">
          <Link
            href="/#features"
            className="block text-gray-300 hover:text-white"
            onClick={() => setMobileOpen(false)}
          >
            Features
          </Link>
          <Link
            href="/#ai-powered"
            className="block text-gray-300 hover:text-white"
            onClick={() => setMobileOpen(false)}
          >
            AI Tracking
          </Link>
          <Link
            href="/#screenshots"
            className="block text-gray-300 hover:text-white"
            onClick={() => setMobileOpen(false)}
          >
            Screenshots
          </Link>
          <Link
            href="#download"
            className="block bg-brand-purple text-white text-center px-5 py-2 rounded-full font-semibold"
            onClick={() => setMobileOpen(false)}
          >
            Download
          </Link>
        </nav>
      )}
    </header>
  );
}
