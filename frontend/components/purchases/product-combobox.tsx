"use client";

import { useState } from "react";

import { useProducts } from "@/hooks/use-products";
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
// PurchaseDetail's `items[].product` (id/name/code only) without
// fabricating a fake full Product. A real Product (from search results)
// satisfies this shape too, so both flow through the same prop untouched.
export interface ProductOption {
  id: number;
  name: string;
  code: string;
}

interface ProductComboboxProps {
  id?: string;
  value: ProductOption | null;
  onChange: (product: ProductOption | null) => void;
  disabled?: boolean;
  invalid?: boolean;
}

// Same reasoning as SupplierCombobox: 530 products is unusable as a plain
// <Select>, so this searches the existing GET /api/v1/products via `q`
// instead of loading all of them. `active: true` only — the backend gap on
// rejecting inactive products in a purchase is reported, not worked around
// here by filtering; this just keeps the picker useful (buying something
// discontinued isn't a real scenario the client asked for).
export function ProductCombobox({ id, value, onChange, disabled, invalid }: ProductComboboxProps) {
  // Same reasoning as SupplierCombobox: `inputValue` needs its own initial
  // value (matching itemToStringLabel's format below) so a programmatically
  // seeded `value` (edit form's initial item) actually shows up in the
  // input instead of rendering empty.
  const [inputValue, setInputValue] = useState(() => (value ? `${value.name} (${value.code})` : ""));
  const debouncedInput = useDebouncedValue(inputValue, 400);

  const { data, isFetching } = useProducts({
    q: debouncedInput || undefined,
    active: true,
    perPage: 20,
    sort: "name",
    order: "asc",
  });
  const products = data?.data ?? [];

  return (
    <Combobox<ProductOption>
      items={products}
      value={value}
      onValueChange={(product) => onChange(product)}
      inputValue={inputValue}
      onInputValueChange={setInputValue}
      itemToStringLabel={(product) => `${product.name} (${product.code})`}
      itemToStringValue={(product) => String(product.id)}
      isItemEqualToValue={(item, val) => item.id === val.id}
      filter={null}
      disabled={disabled}
    >
      <ComboboxInputGroup>
        <ComboboxSearchIcon />
        <ComboboxInput id={id} placeholder="Buscar produto..." aria-invalid={invalid} />
        {isFetching ? <ComboboxLoadingIcon /> : value ? <ComboboxClear /> : <ComboboxIcon />}
      </ComboboxInputGroup>
      <ComboboxContent>
        <ComboboxEmpty>Nenhum produto encontrado.</ComboboxEmpty>
        {products.map((product) => (
          <ComboboxItem key={product.id} value={product}>
            {product.name} <span className="text-muted-foreground">({product.code})</span>
          </ComboboxItem>
        ))}
      </ComboboxContent>
    </Combobox>
  );
}
