import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { formatSectorAccess } from "@/lib/format-sector-access";
import { UserStatusActions } from "@/components/users/user-status-actions";
import type { User } from "@/types/user";

const ROLE_LABELS: Record<User["role"], string> = {
  admin: "Administrador",
  manager: "Gerente",
  operator: "Operador",
};

interface UsersCardsProps {
  users: User[];
  onEdit: (user: User) => void;
}

// Mobile only (<md / 768px) — see UsersTable for desktop/tablet.
export function UsersCards({ users, onEdit }: UsersCardsProps) {
  return (
    <div className="flex flex-col gap-3 md:hidden">
      {users.map((user) => (
        <Card key={user.id}>
          <CardContent className="flex flex-col gap-3 px-4">
            <div className="flex items-start justify-between gap-2">
              <div>
                <p className="font-medium text-foreground">{user.name}</p>
                <p className="text-xs text-muted-foreground">{user.email}</p>
              </div>
              <Badge variant={user.active ? "default" : "secondary"}>{user.active ? "Ativo" : "Inativo"}</Badge>
            </div>
            <dl className="grid grid-cols-2 gap-x-3 gap-y-1 text-sm">
              <dt className="text-muted-foreground">Papel</dt>
              <dd>{ROLE_LABELS[user.role]}</dd>
              <dt className="text-muted-foreground">Acesso aos setores</dt>
              <dd>{formatSectorAccess(user)}</dd>
            </dl>
            <div className="pt-1">
              <UserStatusActions user={user} onEdit={() => onEdit(user)} />
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
