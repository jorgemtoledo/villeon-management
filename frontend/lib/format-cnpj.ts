// Supplier#cnpj is always either null or already normalized to 14 digits
// (see backend Supplier#normalize_cnpj) — this only formats for display,
// it never masks/invents a value and never changes what's sent back to the API.
export function formatCnpj(cnpj: string | null): string {
  if (!cnpj) return "CNPJ não informado";

  const digits = cnpj.replace(/\D/g, "");
  if (digits.length !== 14) return cnpj;

  return digits.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, "$1.$2.$3/$4-$5");
}
