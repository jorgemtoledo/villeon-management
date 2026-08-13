"use client";

import { useState, useSyncExternalStore } from "react";
import { Share, X } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import {
  dismissInstallPrompt,
  getServerSnapshot,
  getSnapshot,
  subscribe,
  triggerAndroidInstall,
} from "@/lib/pwa/install-store";

export function InstallPrompt() {
  const { visible, platform } = useSyncExternalStore(
    subscribe,
    getSnapshot,
    getServerSnapshot,
  );
  const [guideOpen, setGuideOpen] = useState(false);

  if (!visible) return null;

  function handleInstallClick() {
    if (platform === "ios") {
      setGuideOpen(true);
      return;
    }
    void triggerAndroidInstall();
  }

  return (
    <>
      <div className="fixed inset-x-3 bottom-3 z-40 flex items-center gap-3 rounded-lg border border-border bg-popover p-3 shadow-lg sm:inset-x-auto sm:right-4 sm:w-sm">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/icons/icon-192.png"
          alt=""
          className="size-10 shrink-0 rounded-md"
        />
        <div className="min-w-0 flex-1">
          <p className="text-sm font-medium text-foreground">
            Instalar o app da Villeon
          </p>
          <p className="text-xs text-muted-foreground">
            Acesso rápido direto da tela inicial do celular.
          </p>
        </div>
        <Button size="sm" onClick={handleInstallClick}>
          {platform === "ios" ? "Como instalar" : "Instalar"}
        </Button>
        <Button
          variant="ghost"
          size="icon-sm"
          aria-label="Dispensar"
          onClick={dismissInstallPrompt}
        >
          <X />
        </Button>
      </div>

      <Sheet open={guideOpen} onOpenChange={setGuideOpen}>
        <SheetContent side="bottom">
          <SheetHeader>
            <SheetTitle>Instalar no iPhone</SheetTitle>
            <SheetDescription>
              O Safari não deixa instalar com um toque só — são só 3 passos.
              Os nomes dos botões abaixo seguem o idioma do seu iPhone, por
              isso mostramos as duas versões.
            </SheetDescription>
          </SheetHeader>
          <ol className="flex flex-col gap-3 px-4 pb-4 text-sm text-foreground">
            <li className="flex items-start gap-2.5">
              <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-primary/15 text-xs font-medium text-primary">
                1
              </span>
              <span>
                Toque no ícone de compartilhar{" "}
                <Share className="inline size-3.5 align-[-2px]" /> na barra do
                Safari (se não aparecer, toque em &quot;•••&quot; primeiro).
              </span>
            </li>
            <li className="flex items-start gap-2.5">
              <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-primary/15 text-xs font-medium text-primary">
                2
              </span>
              <span>
                Role a lista (ou toque em &quot;Mais&quot; / &quot;More&quot;)
                e escolha{" "}
                <strong>
                  &quot;Adicionar à Tela de Início&quot; (&quot;Add to Home
                  Screen&quot;)
                </strong>
                .
              </span>
            </li>
            <li className="flex items-start gap-2.5">
              <span className="flex size-5 shrink-0 items-center justify-center rounded-full bg-primary/15 text-xs font-medium text-primary">
                3
              </span>
              <span>
                Toque em <strong>&quot;Adicionar&quot; (&quot;Add&quot;)</strong>{" "}
                no canto superior direito.
              </span>
            </li>
          </ol>
        </SheetContent>
      </Sheet>
    </>
  );
}
