# turAventura — Contexto del proyecto

## Qué es

Marketplace de experiencias turísticas de aventura. Modelo P2B2C:
- **Prestadores** publican actividades (trekking, rafting, ski, etc.)
- **Turistas** exploran, reservan y dejan reseñas
- **Admin** gestiona la plataforma (pendiente de implementar)

Inspiración: "Mercado Libre de aventuras turísticas" — foco en Argentina.

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Monorepo | Turborepo |
| Web | Next.js 16 (App Router, Turbopack) |
| Mobile | Expo (React Native) |
| Backend | Supabase (PostgreSQL + Auth + Storage + RLS) |
| Estilos | Tailwind CSS v4 |
| Tipado compartido | `packages/types` |
| Cliente Supabase compartido | `packages/supabase` |

---

## Estructura del monorepo

```
turAventura/
├── apps/
│   ├── web/          → Next.js 16 (puerto 3000)
│   └── mobile/       → Expo React Native
├── packages/
│   ├── types/        → Interfaces TypeScript compartidas
│   └── supabase/     → Cliente Supabase compartido
├── supabase/
│   ├── migrations/
│   │   └── 001_initial_schema.sql   → Schema completo
│   └── seed.sql                     → Datos de ejemplo (22 actividades)
└── CLAUDE.md
```

---

## Comandos frecuentes

```bash
# Iniciar desarrollo web
cd apps/web && npm run dev

# Si hay error de lock file
pkill -f "next dev" && rm -f apps/web/.next/dev/lock

# Copiar seed al clipboard
cat supabase/seed.sql | pbcopy
```

---

## Supabase

- **Proyecto:** `wwdddvdfmqhrbpwcswrc`
- **URL:** `https://wwdddvdfmqhrbpwcswrc.supabase.co`
- **Dashboard:** `https://supabase.com/dashboard/project/wwdddvdfmqhrbpwcswrc`
- **SQL Editor:** `https://supabase.com/dashboard/project/wwdddvdfmqhrbpwcswrc/sql/new`
- **Auth Providers:** `https://supabase.com/dashboard/project/wwdddvdfmqhrbpwcswrc/auth/providers`
- **La clave pública** usa el nuevo formato `sb_publishable_...` (no `eyJhbG...`)
- **Email confirmation** está desactivada en dev → registro funciona sin confirmar email

### Clave en `.env.local`
```
NEXT_PUBLIC_SUPABASE_URL=https://wwdddvdfmqhrbpwcswrc.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=sb_publishable_...
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_...   ← alias necesario para @supabase/ssr
```

---

## Base de datos — Tablas

| Tabla | Descripción |
|---|---|
| `profiles` | FK → `auth.users`. Roles: `tourist`, `provider`, `admin` |
| `providers` | Datos de empresa del prestador (1:1 con profiles) |
| `activities` | Actividades publicadas por providers |
| `activity_images` | Imágenes de cada actividad |
| `availability` | Slots de fecha/hora/cupos por actividad |
| `bookings` | Reservas (tourist → activity + availability) |
| `reviews` | Reseñas de reservas completadas |

### Triggers importantes
- `handle_new_user()` — crea profile con `role='tourist'` al registrarse
- `update_provider_rating()` — recalcula rating del provider al insertar review

### FK sin CASCADE (importante para el seed)
`reviews.tourist_id` y `bookings.tourist_id` referencian `profiles.id` **sin CASCADE**.
Al limpiar datos hay que borrar en orden: reviews → bookings → auth.users.

---

## Roles de usuario

| Rol | Capacidades |
|---|---|
| `tourist` | Explorar, reservar, reseñar |
| `provider` | Todo lo de tourist + publicar actividades + dashboard + gestionar reservas |
| `admin` | Pendiente de implementar |

Un turista puede convertirse en prestador desde la navbar ("Ser prestador" → `/onboarding`).

---

## Flujo de autenticación

```
Registro email → /auth/callback?next=/onboarding → /onboarding
Registro Google → /auth/callback?next=/onboarding → /onboarding
Login email/password → redirige según rol (provider→/dashboard, tourist→/)
Login Google → /auth/callback → redirige según rol
```

### Onboarding
- Nuevo usuario → 2 cards: "Soy turista" / "Soy prestador"
- Turista existente que entra → solo muestra card "Convertirme en prestador"
- Provider existente que entra → redirect directo a /dashboard

---

## Archivos clave — Web (`apps/web/src`)

```
app/
├── (marketing)/
│   ├── page.tsx                    → Home (hero, categorías, actividades destacadas)
│   ├── activities/page.tsx         → Browse con filtros
│   └── activities/[id]/page.tsx    → Detalle + widget de reserva
├── auth/
│   ├── callback/route.ts           → Intercambia code → sesión, redirige según rol
│   ├── login/page.tsx              → Login email + Google
│   └── register/page.tsx           → Registro email + Google
├── onboarding/page.tsx             → Selección de rol (nuevo usuario o upgrade)
├── dashboard/
│   ├── layout.tsx                  → Solo providers; redirige turistas a /onboarding
│   ├── page.tsx                    → Métricas del prestador
│   ├── activities/                 → CRUD de actividades
│   └── bookings/page.tsx           → Gestión de reservas del prestador
└── bookings/page.tsx               → Historial de reservas del turista

components/
└── layout/Navbar.tsx               → Navbar con lógica de rol

lib/
├── supabase/
│   ├── client.ts                   → Cliente browser (con fallback para dev sin .env)
│   └── server.ts                   → Cliente server (con fallback para dev sin .env)
proxy.ts                            → Middleware de auth (rutas protegidas)
```

---

## Configuración Next.js — Quirks

```ts
// next.config.ts — puntos importantes:
turbopack: {
  resolveAlias: { "@turAventura/types": ..., "@turAventura/supabase": ... }
  // Necesario porque Turbopack (default en Next 16) no usa webpack
}
images: {
  remotePatterns: [
    { hostname: "*.supabase.co", pathname: "/storage/v1/object/public/**" },
    { hostname: "images.unsplash.com" }  // Para el seed
  ]
}
allowedDevOrigins: ["127.0.0.1", "localhost"]
```

- El archivo de middleware se llama `proxy.ts` (no `middleware.ts` — deprecado en Next 16)
- Tailwind v4 usa `@import "tailwindcss"` (no `@tailwind base/components/utilities`)

---

## Datos de ejemplo (seed)

Ejecutar `supabase/seed.sql` en el SQL Editor de Supabase.
El script es idempotente: limpia los datos demo antes de recrearlos.

### Cuentas demo (contraseña: `Demo1234!`)

| Email | Rol | Empresa |
|---|---|---|
| `patagonia@demo.com` | prestador | Patagonia Adventures (Bariloche) |
| `andesextreme@demo.com` | prestador | Andes Extreme (Mendoza) |
| `ushuaia@demo.com` | prestador | Fin del Mundo Tours (Ushuaia) |
| `nortaventura@demo.com` | prestador | Norte Aventura (Salta) |
| `turista1@demo.com` | turista | Lucía Pérez (2 reservas) |
| `turista2@demo.com` | turista | Martín López (3 reservas) |

**22 actividades** en total (6 por prestador, excepto Norte Aventura con 4).
**Categorías:** trekking, kayak, rafting, escalada, ski, parapente, ciclismo, cabalgata, buceo.

---

## Errores conocidos y soluciones

| Error | Solución |
|---|---|
| `Unable to acquire lock at .next/dev/lock` | `pkill -f "next dev" && rm -f apps/web/.next/dev/lock` |
| `This build is using Turbopack with a webpack config` | Usar `turbopack.resolveAlias` en vez de `webpack()` |
| `The "middleware" file convention is deprecated` | El archivo se llama `proxy.ts` y exporta `proxy` |
| `Your project's URL and Key are required` | Los clientes tienen fallback `?? 'placeholder...'` para dev sin .env |
| `Invalid src prop on next/image` | Agregar hostname a `images.remotePatterns` en next.config.ts |
| Email rate limit exceeded (Supabase) | Desactivar "Confirm email" en Auth Providers durante dev |
| FK violation al ejecutar seed | El seed borra en orden: reviews → bookings → auth.users |

---

## Pendientes / Backlog

- [ ] Google OAuth: configurar credenciales en Google Cloud Console
- [ ] Storage: crear bucket `activity-images` (público) en Supabase Storage
- [ ] Pagos: integrar pasarela (MercadoPago o Stripe) — actualmente simulado
- [ ] Panel admin
- [ ] App mobile (Expo) — estructura creada, pendiente de conectar con Supabase
- [ ] Notificaciones (email al confirmar reserva)
- [ ] Sistema de favoritos
- [ ] Búsqueda full-text (ya hay índice GIN en `activities.search_vector`)
