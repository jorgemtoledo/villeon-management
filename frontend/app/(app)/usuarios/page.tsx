"use client";

import { useState } from "react";
import { Plus } from "lucide-react";

import { useUsers } from "@/hooks/use-users";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { useAuth } from "@/hooks/use-auth";
import { canManageUsers } from "@/lib/auth/permissions";
import { Button } from "@/components/ui/button";
import { Pagination } from "@/components/shared/pagination";
import { UsersFilters, type RoleFilter, type StatusFilter } from "@/components/users/users-filters";
import { UsersTable } from "@/components/users/users-table";
import { UsersCards } from "@/components/users/users-cards";
import { UserFormSheet } from "@/components/users/user-form-sheet";
import {
  UsersEmptyState,
  UsersErrorState,
  UsersForbiddenState,
  UsersLoadingState,
} from "@/components/users/users-states";
import type { User } from "@/types/user";

const PER_PAGE = 25;

// undefined = Sheet closed; "new" = create mode; a User = edit mode.
type SheetTarget = User | "new" | undefined;

export default function UsuariosPage() {
  const { user } = useAuth();
  const canManage = canManageUsers(user);

  const [search, setSearch] = useState("");
  const [role, setRole] = useState<RoleFilter>("all");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [page, setPage] = useState(1);
  const [sheetTarget, setSheetTarget] = useState<SheetTarget>(undefined);
  const debouncedSearch = useDebouncedValue(search, 400);

  const [appliedFilters, setAppliedFilters] = useState({ search: debouncedSearch, role, status });
  if (
    appliedFilters.search !== debouncedSearch ||
    appliedFilters.role !== role ||
    appliedFilters.status !== status
  ) {
    setAppliedFilters({ search: debouncedSearch, role, status });
    setPage(1);
  }

  // Page-level guard: a manager/operator who navigates here directly never
  // even triggers the users list request (enabled: canManage) — the real
  // protection is still the backend's 403 (BaseController#authorize!), this
  // just avoids a pointless round trip and shows a clear message instead of
  // an error state.
  const { data, isPending, isError, isPlaceholderData, refetch } = useUsers(
    {
      q: debouncedSearch || undefined,
      role: role === "all" ? undefined : role,
      active: status === "all" ? undefined : status === "active",
      page,
      perPage: PER_PAGE,
      sort: "name",
      order: "asc",
    },
    { enabled: canManage },
  );

  if (!canManage) {
    return <UsersForbiddenState />;
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold text-foreground">Usuários</h1>
          <p className="text-sm text-muted-foreground">Gestão de usuários — papéis, acesso a setores e status.</p>
        </div>
        <Button type="button" className="h-11 md:h-9" onClick={() => setSheetTarget("new")}>
          <Plus className="size-4" />
          Novo usuário
        </Button>
      </div>

      <UsersFilters
        search={search}
        onSearchChange={setSearch}
        role={role}
        onRoleChange={setRole}
        status={status}
        onStatusChange={setStatus}
      />

      {isPending ? <UsersLoadingState /> : null}

      {isError ? <UsersErrorState onRetry={() => refetch()} /> : null}

      {!isPending && !isError && data ? (
        data.data.length === 0 ? (
          <UsersEmptyState />
        ) : (
          <div className={isPlaceholderData ? "opacity-60 transition-opacity" : undefined}>
            <UsersTable users={data.data} onEdit={setSheetTarget} />
            <UsersCards users={data.data} onEdit={setSheetTarget} />
            <Pagination meta={data.meta} onPageChange={setPage} itemLabel="usuários" />
          </div>
        )
      ) : null}

      <UserFormSheet
        open={sheetTarget !== undefined}
        onOpenChange={(open) => {
          if (!open) setSheetTarget(undefined);
        }}
        user={sheetTarget === "new" ? undefined : sheetTarget}
      />
    </div>
  );
}
