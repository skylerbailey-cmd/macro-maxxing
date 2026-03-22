import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = "https://macromaxxing.com";
  const lastModified = new Date("2026-03-22");

  return [
    { url: baseUrl, lastModified, changeFrequency: "weekly", priority: 1 },
    {
      url: `${baseUrl}/best-macro-tracking-app`,
      lastModified,
      changeFrequency: "monthly",
      priority: 0.9,
    },
    {
      url: `${baseUrl}/ai-food-scanner`,
      lastModified,
      changeFrequency: "monthly",
      priority: 0.9,
    },
    {
      url: `${baseUrl}/calorie-counter-app`,
      lastModified,
      changeFrequency: "monthly",
      priority: 0.9,
    },
    {
      url: `${baseUrl}/intermittent-fasting-tracker`,
      lastModified,
      changeFrequency: "monthly",
      priority: 0.8,
    },
    {
      url: `${baseUrl}/workout-tracker-app`,
      lastModified,
      changeFrequency: "monthly",
      priority: 0.8,
    },
    {
      url: `${baseUrl}/voice-food-logging`,
      lastModified,
      changeFrequency: "monthly",
      priority: 0.8,
    },
  ];
}
