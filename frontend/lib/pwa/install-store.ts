// Framework-agnostic external store (React 19's useSyncExternalStore contract,
// same shape as lib/auth/session-store.ts) for "Add to Home Screen" install
// state. Lives outside React because the values it tracks — device/browser
// detection, the Chrome-only beforeinstallprompt event — only exist
// client-side and never change via props/state, just like the auth token.

export interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
}

export interface InstallPromptState {
  visible: boolean;
  platform: "ios" | "android" | null;
  deferredPrompt: BeforeInstallPromptEvent | null;
}

const DISMISSED_KEY = "villeon-install-prompt-dismissed";
const HIDDEN: InstallPromptState = {
  visible: false,
  platform: null,
  deferredPrompt: null,
};

function isStandalone(): boolean {
  return (
    window.matchMedia("(display-mode: standalone)").matches ||
    // iOS Safari's own (non-standard) flag — the media query above doesn't
    // reliably reflect standalone launch on iOS.
    (window.navigator as { standalone?: boolean }).standalone === true
  );
}

function isIOSDevice(): boolean {
  if (/iPad|iPhone|iPod/.test(navigator.userAgent)) return true;
  // iPadOS 13+ spoofs a desktop Mac user agent; touch support is the tell.
  return navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1;
}

function computeInitialState(): InstallPromptState {
  if (typeof window === "undefined") return HIDDEN;
  if (isStandalone() || window.localStorage.getItem(DISMISSED_KEY)) return HIDDEN;
  // No native install prompt exists on iOS (Apple provides no equivalent of
  // Chrome's beforeinstallprompt), so this is shown unconditionally rather
  // than waiting on a browser-fired event like the Android branch below.
  if (isIOSDevice()) return { visible: true, platform: "ios", deferredPrompt: null };
  return HIDDEN;
}

let state: InstallPromptState = computeInitialState();
const listeners = new Set<() => void>();

function emit() {
  listeners.forEach((listener) => listener());
}

if (typeof window !== "undefined") {
  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    if (window.localStorage.getItem(DISMISSED_KEY)) return;
    state = {
      visible: true,
      platform: "android",
      deferredPrompt: event as BeforeInstallPromptEvent,
    };
    emit();
  });

  window.addEventListener("appinstalled", () => {
    window.localStorage.setItem(DISMISSED_KEY, "1");
    state = HIDDEN;
    emit();
  });
}

export function subscribe(listener: () => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function getSnapshot(): InstallPromptState {
  return state;
}

// useSyncExternalStore uses this during SSR and during hydration's first
// client render, so the initial render never depends on device/localStorage
// detection — avoids a hydration mismatch even though `state` above is
// already computed by the time components mount.
export function getServerSnapshot(): InstallPromptState {
  return HIDDEN;
}

export function dismissInstallPrompt(): void {
  if (typeof window !== "undefined") window.localStorage.setItem(DISMISSED_KEY, "1");
  state = HIDDEN;
  emit();
}

export async function triggerAndroidInstall(): Promise<void> {
  const { deferredPrompt } = state;
  if (!deferredPrompt) return;

  await deferredPrompt.prompt();
  const { outcome } = await deferredPrompt.userChoice;

  if (outcome === "accepted") {
    dismissInstallPrompt();
  } else {
    state = { ...state, deferredPrompt: null };
    emit();
  }
}
