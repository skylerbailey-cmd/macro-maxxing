export function AppJsonLd() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "Macro Maxxing",
    operatingSystem: "iOS",
    applicationCategory: "HealthApplication",
    description:
      "AI-powered macro tracker with photo food scanning, voice logging, workout tracking, and intermittent fasting timer.",
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
    },
    aggregateRating: {
      "@type": "AggregateRating",
      ratingValue: "4.9",
      ratingCount: "500",
    },
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}

export function ArticleJsonLd({
  title,
  description,
  url,
}: {
  title: string;
  description: string;
  url: string;
}) {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: title,
    description,
    url,
    author: { "@type": "Organization", name: "Macro Maxxing" },
    publisher: { "@type": "Organization", name: "Macro Maxxing" },
    datePublished: "2026-03-01",
    dateModified: "2026-03-22",
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}
