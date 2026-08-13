"use client";

import { useState } from "react";
import { toast } from "sonner";

import { useCreateUser, useUpdateUser } from "@/hooks/use-user-mutations";
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
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { UserForm } from "@/components/users/user-form";
import type { User, UserInput } from "@/types/user";

const FORM_ID = "user-form";

interface UserFormSheetProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  // undefined = create mode, a User = edit mode.
  user?: User;
}

export function UserFormSheet({ open, onOpenChange, user }: UserFormSheetProps) {
  const createMutation = useCreateUser();
  // Hooks can't be called conditionally — id is only used by the mutation
  // fn when the form actually submits in edit mode, so a placeholder id
  // while creating is harmless (never sent anywhere).
  const updateMutation = useUpdateUser(user?.id ?? -1);

  const mutation = user ? updateMutation : createMutation;
  const isEditing = !!user;

  // Confirmation gate for "all_sectors=false and no sector selected" —
  // holds the already-valid input until the admin confirms or cancels.
  const [pendingInput, setPendingInput] = useState<UserInput | null>(null);

  function submit(input: UserInput) {
    mutation.mutate(input, {
      onSuccess: () => {
        toast.success(isEditing ? "Usuário atualizado com sucesso." : "Usuário criado com sucesso.");
        onOpenChange(false);
      },
    });
  }

  function handleSubmit(input: UserInput) {
    if (!input.all_sectors && input.sector_ids.length === 0) {
      setPendingInput(input);
      return;
    }
    submit(input);
  }

  const error = mutation.error;
  const errorMessage = error instanceof ApiError ? error.message : error ? "Erro inesperado ao salvar o usuário." : null;
  const errorDetails = error instanceof ApiError ? error.details : undefined;

  return (
    <>
      <Sheet
        open={open}
        onOpenChange={(next) => {
          if (!next) {
            mutation.reset();
            setPendingInput(null);
          }
          onOpenChange(next);
        }}
      >
        <SheetContent side="right" className="w-full sm:max-w-lg">
          <SheetHeader>
            <SheetTitle>{isEditing ? "Editar usuário" : "Novo usuário"}</SheetTitle>
            <SheetDescription>
              {isEditing
                ? "Altere os dados do usuário e salve para aplicar as mudanças."
                : "Preencha os dados do novo usuário."}
            </SheetDescription>
          </SheetHeader>

          <div className="flex-1 overflow-y-auto px-4 py-1">
            <UserForm
              key={open ? (user?.id ?? "new") : "closed"}
              formId={FORM_ID}
              user={user}
              onSubmit={handleSubmit}
              errorMessage={errorMessage}
              errorDetails={errorDetails}
            />
          </div>

          <SheetFooter className="flex-row justify-end gap-2">
            <Button type="button" variant="outline" className="h-11 md:h-9" onClick={() => onOpenChange(false)}>
              Cancelar
            </Button>
            <Button type="submit" form={FORM_ID} disabled={mutation.isPending} className="h-11 md:h-9">
              {mutation.isPending ? "Salvando..." : isEditing ? "Salvar alterações" : "Criar usuário"}
            </Button>
          </SheetFooter>
        </SheetContent>
      </Sheet>

      <AlertDialog open={pendingInput !== null} onOpenChange={(next) => !next && setPendingInput(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Continuar sem acesso a setores?</AlertDialogTitle>
            <AlertDialogDescription>
              Este usuário não terá acesso a nenhum setor de estoque. Deseja continuar?
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (pendingInput) submit(pendingInput);
                setPendingInput(null);
              }}
            >
              Continuar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
