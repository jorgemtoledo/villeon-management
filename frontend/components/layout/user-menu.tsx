"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { LogOut, User as UserIcon } from "lucide-react";
import { toast } from "sonner";

import { useAuth } from "@/hooks/use-auth";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

const ROLE_LABELS: Record<string, string> = {
  admin: "Administrador",
  manager: "Gerente",
  operator: "Operador",
};

function initials(name: string): string {
  return name
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("");
}

export function UserMenu() {
  const { user, logout } = useAuth();
  const router = useRouter();
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  if (!user) return null;

  async function handleLogout() {
    setIsLoggingOut(true);
    try {
      await logout();
      router.replace("/login");
    } catch {
      toast.error("Não foi possível encerrar a sessão no servidor, mas você foi desconectado.");
      router.replace("/login");
    } finally {
      setIsLoggingOut(false);
    }
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger
        render={
          <Button
            variant="ghost"
            className="h-11 gap-2 px-2"
            aria-label="Menu do usuário"
          />
        }
      >
        <Avatar className="size-8">
          <AvatarFallback className="bg-villeon-gold-100 text-villeon-green-900">
            {initials(user.name) || <UserIcon className="size-4" />}
          </AvatarFallback>
        </Avatar>
        <span className="hidden text-sm font-medium sm:inline">{user.name}</span>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <DropdownMenuGroup>
          <DropdownMenuLabel className="flex flex-col">
            <span className="font-medium">{user.name}</span>
            <span className="text-xs font-normal text-muted-foreground">
              {ROLE_LABELS[user.role] ?? user.role} · {user.email}
            </span>
          </DropdownMenuLabel>
        </DropdownMenuGroup>
        <DropdownMenuSeparator />
        <DropdownMenuGroup>
          <DropdownMenuItem
            variant="destructive"
            disabled={isLoggingOut}
            onClick={handleLogout}
          >
            <LogOut className="size-4" aria-hidden="true" />
            {isLoggingOut ? "Saindo..." : "Sair"}
          </DropdownMenuItem>
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
