"use client";

import { useState } from "react";
import { toast } from "sonner";

import { useAuth } from "@/hooks/use-auth";
import { useUpdateProductStockPriority } from "@/hooks/use-product-stock-mutations";
import { ApiError } from "@/lib/api/client";
import { canEditStockPriority } from "@/lib/auth/permissions";
import { STOCK_PRIORITY_LABEL } from "@/lib/format-stock-status";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Field, FieldContent, FieldLabel } from "@/components/ui/field";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { ProductStock, StockPriority } from "@/types/product-stock";

const UNSET = "unset";

const priorityItems: Record<string, string> = { [UNSET]: "Não definida", ...STOCK_PRIORITY_LABEL };
const advanceOrderItems: Record<string, string> = { [UNSET]: "Não definido", true: "Sim", false: "Não" };

interface StockPriorityStepProps {
  stock: ProductStock;
  onDone: () => void;
}

// Second step of the count Sheet (Bloco 6G Parte 4) — shown by
// StockCountSheet only when the count just submitted resulted in status
// "comprar". Always optional: "Pular"/"Fechar" never blocks, mirroring the
// rule that registering a count is never held hostage by this follow-up.
export function StockPriorityStep({ stock, onDone }: StockPriorityStepProps) {
  const { user } = useAuth();
  const mutation = useUpdateProductStockPriority(stock.product.id);

  const alreadyConfigured = stock.priority !== null || stock.needs_advance_order !== null;
  const editable = canEditStockPriority(user, stock.sector?.id, alreadyConfigured);

  const [ priority, setPriority ] = useState(stock.priority ?? UNSET);
  const [ advanceOrder, setAdvanceOrder ] = useState(
    stock.needs_advance_order === null ? UNSET : String(stock.needs_advance_order),
  );

  function handleSave() {
    mutation.mutate(
      {
        priority: priority === UNSET ? null : (priority as StockPriority),
        needs_advance_order: advanceOrder === UNSET ? null : advanceOrder === "true",
      },
      {
        onSuccess: () => {
          toast.success("Configuração de prioridade salva.");
          onDone();
        },
      },
    );
  }

  const error = mutation.error;
  const errorMessage =
    error instanceof ApiError ? error.message : error ? "Erro inesperado ao salvar a prioridade." : null;

  return (
    <div className="flex flex-col gap-4">
      <Alert>
        <AlertDescription>
          Este produto ficou com status <strong>Comprar</strong>. Prioridade e antecedência são opcionais.
        </AlertDescription>
      </Alert>

      {errorMessage ? (
        <Alert variant="destructive">
          <AlertDescription>{errorMessage}</AlertDescription>
        </Alert>
      ) : null}

      {alreadyConfigured && !editable ? (
        <p className="text-sm text-muted-foreground">Já configurado — somente Felipe e Fran podem alterar.</p>
      ) : null}

      <Field>
        <FieldLabel htmlFor="priority">Prioridade</FieldLabel>
        <FieldContent>
          <Select
            value={priority}
            onValueChange={(value) => setPriority(value ?? UNSET)}
            disabled={!editable}
            items={priorityItems}
          >
            <SelectTrigger id="priority" className="h-11 w-full md:h-9">
              <SelectValue placeholder="Selecione a prioridade" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={UNSET}>Não definida</SelectItem>
              {(Object.keys(STOCK_PRIORITY_LABEL) as StockPriority[]).map((value) => (
                <SelectItem key={value} value={value}>
                  {STOCK_PRIORITY_LABEL[value]}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </FieldContent>
      </Field>

      <Field>
        <FieldLabel htmlFor="needs_advance_order">Pedir c/ antecedência?</FieldLabel>
        <FieldContent>
          <Select
            value={advanceOrder}
            onValueChange={(value) => setAdvanceOrder(value ?? UNSET)}
            disabled={!editable}
            items={advanceOrderItems}
          >
            <SelectTrigger id="needs_advance_order" className="h-11 w-full md:h-9">
              <SelectValue placeholder="Selecione" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={UNSET}>Não definido</SelectItem>
              <SelectItem value="true">Sim</SelectItem>
              <SelectItem value="false">Não</SelectItem>
            </SelectContent>
          </Select>
        </FieldContent>
      </Field>

      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" className="h-11 md:h-9" onClick={onDone}>
          {editable ? "Pular" : "Fechar"}
        </Button>
        {editable ? (
          <Button type="button" onClick={handleSave} disabled={mutation.isPending} className="h-11 md:h-9">
            {mutation.isPending ? "Salvando..." : "Salvar"}
          </Button>
        ) : null}
      </div>
    </div>
  );
}
