"use client";

import { useState } from "react";

import { useSuppliers } from "@/hooks/use-suppliers";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import {
  Combobox,
  ComboboxClear,
  ComboboxContent,
  ComboboxEmpty,
  ComboboxIcon,
  ComboboxInput,
  ComboboxInputGroup,
  ComboboxItem,
  ComboboxLoadingIcon,
  ComboboxSearchIcon,
} from "@/components/ui/combobox";

// Only what the combobox actually needs to display/compare a selection —
// lets the edit form (Bloco 6H.3) seed the initial value from
// PurchaseDetail's `supplier: NamedReference` (id/name only) without
// fabricating a fake full Supplier. A real Supplier (from search results)
// satisfies this shape too, so both flow through the same prop untouched.
export interface SupplierOption {
  id: number;
  name: string;
}

interface SupplierComboboxProps {
  id?: string;
  value: SupplierOption | null;
  onChange: (supplier: SupplierOption | null) => void;
  disabled?: boolean;
  invalid?: boolean;
}

// 101 suppliers is too many for a plain <Select> (see the comment this
// replaces in purchases-filters.tsx) — searches the existing GET
// /api/v1/suppliers via `q`, debounced the same way every filter bar in the
// app already does. No supplier is ever created here (out of scope).
export function SupplierCombobox({ id, value, onChange, disabled, invalid }: SupplierComboboxProps) {
  // `inputValue` is a separate, fully-controlled prop from `value` (Base UI
  // combobox design) — it's normally kept in sync by onInputValueChange as
  // the user types/selects, but that never fires for a value seeded
  // programmatically (edit form's initial supplier). Without this lazy
  // initializer the input would render empty even though `value` (and thus
  // the actual form field) is correctly pre-filled.
  const [inputValue, setInputValue] = useState(() => value?.name ?? "");
  const debouncedInput = useDebouncedValue(inputValue, 400);

  const { data, isFetching } = useSuppliers({
    q: debouncedInput || undefined,
    active: true,
    perPage: 20,
    sort: "name",
    order: "asc",
  });
  const suppliers = data?.data ?? [];

  return (
    <Combobox<SupplierOption>
      items={suppliers}
      value={value}
      onValueChange={(supplier) => onChange(supplier)}
      inputValue={inputValue}
      onInputValueChange={setInputValue}
      itemToStringLabel={(supplier) => supplier.name}
      itemToStringValue={(supplier) => String(supplier.id)}
      isItemEqualToValue={(item, val) => item.id === val.id}
      filter={null}
      disabled={disabled}
    >
      <ComboboxInputGroup>
        <ComboboxSearchIcon />
        <ComboboxInput id={id} placeholder="Buscar fornecedor..." aria-invalid={invalid} />
        {isFetching ? <ComboboxLoadingIcon /> : value ? <ComboboxClear /> : <ComboboxIcon />}
      </ComboboxInputGroup>
      <ComboboxContent>
        <ComboboxEmpty>Nenhum fornecedor encontrado.</ComboboxEmpty>
        {suppliers.map((supplier) => (
          <ComboboxItem key={supplier.id} value={supplier}>
            {supplier.name}
          </ComboboxItem>
        ))}
      </ComboboxContent>
    </Combobox>
  );
}
