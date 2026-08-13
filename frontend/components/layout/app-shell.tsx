import { Sidebar } from "@/components/layout/sidebar";
import { Header } from "@/components/layout/header";

// Desktop (≥lg): Sidebar (fixed) + Header + content, side by side.
// Mobile/tablet (<lg): Header (with drawer trigger) + content, full width —
// Sidebar renders nothing below lg (see Sidebar's `hidden lg:flex`).
export function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-svh">
      <Sidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <Header />
        <main className="min-w-0 flex-1 overflow-x-hidden p-4 sm:p-6">{children}</main>
      </div>
    </div>
  );
}
