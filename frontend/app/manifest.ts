import type { MetadataRoute } from "next";

// Installable PWA manifest only — no service worker, no offline caching.
// Explicit decision (see project memory "responsive-requirements"): stock
// and purchase data are shared/live between operators, so offline writes
// would risk silent conflicts. This just adds "Add to Home Screen" support.
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "VILLEON Gestão",
    short_name: "VILLEON",
    description: "Gestão de catálogo, estoque e compras do VILLEON Restaurant.",
    start_url: "/",
    display: "standalone",
    background_color: "#0b312e",
    theme_color: "#0b312e",
    icons: [
      {
        src: "/brand/villeon-icon.png",
        sizes: "320x339",
        type: "image/png",
      },
    ],
  };
}
