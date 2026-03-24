export function AppJsonLd() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "Macro Maxxing",
    operatingSystem: "iOS",
    applicationCategory: "HealthApplication",
    description:
      "Macro Maxxing is a free AI-powered macro tracking app for iOS that uses photo scanning and voice logging to estimate calories, protein, carbs, and fat. It includes workout tracking with automatic macro adjustments, an intermittent fasting timer, daily streaks, leaderboards, and a social community feed.",
    url: "https://macromaxxing.app",
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
    author: {
      "@type": "Organization",
      name: "Macro Maxxing",
      url: "https://macromaxxing.app",
    },
    featureList: [
      "AI photo food scanning powered by Claude AI",
      "Voice meal logging with natural language processing",
      "Workout tracking with automatic macro adjustments",
      "Intermittent fasting timer",
      "Daily streaks and Aura XP system",
      "Social community feed and leaderboards",
      "USDA FoodData Central nutrition database",
      "Saved meal templates",
    ],
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}

export function OrganizationJsonLd() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Organization",
    name: "Macro Maxxing",
    url: "https://macromaxxing.app",
    description:
      "Macro Maxxing builds AI-powered nutrition tracking tools for iOS, helping users track macros through photo scanning, voice logging, and smart workout adjustments.",
    foundingDate: "2025",
    sameAs: [],
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
  datePublished = "2026-03-01",
  dateModified = "2026-03-24",
}: {
  title: string;
  description: string;
  url: string;
  datePublished?: string;
  dateModified?: string;
}) {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: title,
    description,
    url,
    mainEntityOfPage: { "@type": "WebPage", "@id": url },
    author: { "@type": "Organization", name: "Macro Maxxing", url: "https://macromaxxing.app" },
    publisher: { "@type": "Organization", name: "Macro Maxxing", url: "https://macromaxxing.app" },
    datePublished,
    dateModified,
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}

export function FAQPageJsonLd({
  faqs,
}: {
  faqs: { question: string; answer: string }[];
}) {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: faqs.map((faq) => ({
      "@type": "Question",
      name: faq.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: faq.answer,
      },
    })),
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}

export function BreadcrumbJsonLd({
  items,
}: {
  items: { name: string; url: string }[];
}) {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((item, index) => ({
      "@type": "ListItem",
      position: index + 1,
      name: item.name,
      item: item.url,
    })),
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}
