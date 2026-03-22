import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          bg: "#120D1E",
          card: "#1F1A38",
          purple: "#A572FF",
          gold: "#FFD833",
          teal: "#33CDB3",
          green: "#4DE58C",
          orange: "#FF8C26",
          cyan: "#5CBFFF",
          mint: "#66E5B8",
          rose: "#FF80B8",
        },
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
};

export default config;
