"use client";

import { toast } from "sonner";

import { useActivateUser, useDeactivateUser } from "@/hooks/use-user-mutations";
import { ApiError } from "@/lib/api/client";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import type { User } from "@/types/user";

// Used both in the desktop table row and the mobile card. No extra
// "can't touch yourself/other admins" logic here — the backend's last-admin
// protection is the real guard; a rejected attempt just surfaces its 422
// message via the toast below, same as any other validation error.
export function UserStatusActions({ user, onEdit }: { user: User; onEdit: () => void }) {
  const activateMutation = useActivateUser();
  const deactivateMutation = useDeactivateUser();

  function errorMessage(error: unknown, fallback: string) {
    return error instanceof ApiError ? error.message : fallback;
  }

  function handleActivate() {
    activateMutation.mutate(user.id, {
      onSuccess: () => toast.success(`"${user.name}" foi ativado.`),
      onError: (error) => toast.error(errorMessage(error, "Não foi possível ativar o usuário.")),
    });
  }

  function handleDeactivate() {
    deactivateMutation.mutate(user.id, {
      onSuccess: () => toast.success(`"${user.name}" foi desativado.`),
      onError: (error) => toast.error(errorMessage(error, "Não foi possível desativar o usuário.")),
    });
  }

  return (
    <div className="flex gap-2">
      <Button type="button" variant="outline" size="sm" className="h-11 md:h-9" onClick={onEdit}>
        Editar
      </Button>

      {user.active ? (
        <AlertDialog>
          <AlertDialogTrigger
            render={
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="h-11 md:h-9"
                disabled={deactivateMutation.isPending}
              />
            }
          >
            {deactivateMutation.isPending ? "Desativando..." : "Desativar"}
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Desativar este usuário?</AlertDialogTitle>
              <AlertDialogDescription>
                &ldquo;{user.name}&rdquo; não conseguirá mais entrar no sistema até ser reativado.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Cancelar</AlertDialogCancel>
              <AlertDialogAction onClick={handleDeactivate}>Desativar</AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      ) : (
        <Button
          type="button"
          variant="outline"
          size="sm"
          className="h-11 md:h-9"
          onClick={handleActivate}
          disabled={activateMutation.isPending}
        >
          {activateMutation.isPending ? "Ativando..." : "Ativar"}
        </Button>
      )}
    </div>
  );
}
