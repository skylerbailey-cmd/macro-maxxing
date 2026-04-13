export function DownloadCTA({
  headline = "Ready to start maxxing your macros?",
  subheadline = "Download Macromaxxing and start tracking with AI today.",
}: {
  headline?: string;
  subheadline?: string;
}) {
  return (
    <section id="download" className="py-24 px-4 sm:px-6">
      <div className="max-w-3xl mx-auto text-center">
        <h2 className="text-3xl sm:text-4xl font-bold mb-4 text-gradient">
          {headline}
        </h2>
        <p className="text-gray-400 text-lg mb-8">{subheadline}</p>
        <a
          href="#"
          className="inline-flex items-center gap-3 bg-white text-brand-bg px-8 py-4 rounded-full font-bold text-lg hover:bg-gray-100 transition"
        >
          <svg className="w-7 h-7" viewBox="0 0 24 24" fill="currentColor">
            <path d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 21.99 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.1 21.99C7.79 22.03 6.8 20.68 5.96 19.47C4.25 16.97 2.94 12.45 4.7 9.39C5.57 7.87 7.13 6.91 8.82 6.89C10.1 6.87 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z" />
          </svg>
          Download on the App Store
        </a>
        <p className="text-gray-500 text-sm mt-4">Available on iOS 17+.</p>
      </div>
    </section>
  );
}
