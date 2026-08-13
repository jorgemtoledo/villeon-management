import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { formatSectorAccess } from "@/lib/format-sector-access";
import { UserStatusActions } from "@/components/users/user-status-actions";
import type { User } from "@/types/user";

const ROLE_LABELS: Record<User["role"], string> = {
  admin: "Administrador",
  manager: "Gerente",
  operator: "Operador",
};

interface UsersTableProps {
  users: User[];
  onEdit: (user: User) => void;
}

// Desktop/tablet only (≥md / 768px) — see UsersCards for the mobile
// equivalent. Only reached by admin (page-level guard), so no canManage
// branching here — every row always has actions, unlike Products/Suppliers.
export function UsersTable({ users, onEdit }: UsersTableProps) {
  return (
    <div className="hidden overflow-x-auto rounded-lg border border-border md:block">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Nome</TableHead>
            <TableHead>E-mail</TableHead>
            <TableHead>Papel</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Acesso aos setores</TableHead>
            <TableHead>Ações</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {users.map((user) => (
            <TableRow key={user.id}>
              <TableCell className="font-medium">{user.name}</TableCell>
              <TableCell className="text-muted-foreground">{user.email}</TableCell>
              <TableCell>{ROLE_LABELS[user.role]}</TableCell>
              <TableCell>
                <Badge variant={user.active ? "default" : "secondary"}>{user.active ? "Ativo" : "Inativo"}</Badge>
              </TableCell>
              <TableCell className="text-muted-foreground">{formatSectorAccess(user)}</TableCell>
              <TableCell>
                <UserStatusActions user={user} onEdit={() => onEdit(user)} />
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
