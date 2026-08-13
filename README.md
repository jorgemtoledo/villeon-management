# VILLEON Gestão

Sistema de gestão (produtos, fornecedores, compras, estoque, fichas técnicas, cardápio) desenvolvido
sob medida para o restaurante Villeon. Projeto de cliente único, sem multi-tenant.

> Status atual: **fundação do backend (Bloco 1)** concluída. Ainda não há models, autenticação nem
> frontend — isso vem em blocos seguintes, aprovados um de cada vez.

## Stack

- **Backend**: Ruby 3.3 · Rails 8 (API only) · PostgreSQL 16 · Redis 7 · Sidekiq
- **Frontend**: Next.js / React / TypeScript / Tailwind (ainda não iniciado)
- **Infra**: Docker Compose

## Pré-requisitos

- Docker Desktop instalado e rodando

Não é necessário ter Ruby, PostgreSQL ou Redis instalados na máquina — tudo roda em container.

## Subindo o ambiente

```bash
cp .env.example .env      # ajuste se precisar; valores padrão já funcionam localmente
docker compose build
docker compose up -d
```

Isso sobe 4 serviços:

| Serviço   | O que é                   | Porta no host    |
| --------- | ------------------------- | ---------------- |
| `backend` | API Rails                 | `localhost:3000` |
| `sidekiq` | Worker de background jobs | —                |
| `db`      | PostgreSQL 16             | `localhost:5432` |
| `redis`   | Redis 7                   | `localhost:6379` |

Primeira vez, criar os bancos:

```bash
docker compose exec backend bin/rails db:prepare
```

## Verificando que subiu

```bash
curl http://localhost:3000/up               # health check de infra (não toca em DB/Redis)
curl http://localhost:3000/api/v1/health     # health check da aplicação (confirma DB + Redis reais)
```

A segunda rota deve responder `{"status":"ok","checks":{"database":true,"redis":true},...}`.

## Rodando os testes, lint e análise de segurança

Tudo de uma vez (RSpec, RuboCop, bundler-audit, Brakeman — mesma sequência que rodaria em CI):

```bash
docker compose exec backend bin/ci
```

Ou individualmente:

```bash
docker compose exec -e RAILS_ENV=test backend bundle exec rspec
docker compose exec backend bin/rubocop
docker compose exec backend bin/brakeman
docker compose exec backend bin/bundler-audit
```

⚠️ O container `backend` roda com `RAILS_ENV=development` por padrão (definido no `.env`). Rodando
o RSpec direto (fora do `bin/ci`, que já cuida disso) é preciso sobrescrever com
`-e RAILS_ENV=test`, senão ele roda contra a configuração errada.

## Parando o ambiente

```bash
docker compose down          # para os containers, mantém os dados (volumes)
docker compose down -v       # para e apaga os dados do Postgres/Redis também
```

## Estrutura do repositório

```
villeon-management/
├── backend/            → API Rails (controllers/models/services/serializers/workers/jobs/...)
├── frontend/            → (ainda não criado)
├── brand/               → identidade visual fornecida pelo cliente
├── docs/data/            → planilha original do cliente (MAPA COMPRAS.xlsx) — nunca editar
├── docker-compose.yml
└── .env.example
```
