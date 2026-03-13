# turAventura MVP

Marketplace de experiencias turísticas de aventura en Argentina.

## Stack

| | Tecnología |
|---|---|
| Web | Next.js 14 (App Router) + Tailwind CSS v4 |
| Mobile | Expo (React Native) |
| Backend/DB | Supabase (PostgreSQL + Auth + Storage) |
| Monorepo | Turborepo |
| Lenguaje | TypeScript |

## Estructura

```
turAventura/
├── apps/
│   ├── web/              # Next.js — marketplace web
│   └── mobile/           # Expo — app iOS/Android
├── packages/
│   ├── types/            # Tipos TypeScript compartidos
│   └── supabase/         # Cliente Supabase compartido
└── supabase/
    └── migrations/       # Schema SQL
```

## Setup rápido

### 1. Supabase

1. Crear proyecto en [supabase.com](https://supabase.com)
2. Ir a **SQL Editor** y ejecutar `supabase/migrations/001_initial_schema.sql`
3. En **Storage** → crear bucket `activity-images` (público)
4. En **Authentication → Providers** → activar Google OAuth (opcional)
5. Copiar `Project URL` y `anon key` de Settings → API

### 2. App Web

```bash
cd apps/web
cp .env.local.example .env.local
# Editar .env.local con tus credenciales Supabase

npm run dev
# → http://localhost:3000
```

### 3. App Mobile

```bash
cd apps/mobile
cp .env.example .env
# Editar .env con tus credenciales Supabase

npm run ios     # iOS (requiere Xcode)
npm run android # Android (requiere Android Studio)
# o
npx expo start  # Expo Go (más rápido para desarrollo)
```

## Flujos MVP

### Turista
1. Registrarse → elegir rol "turista"
2. Explorar actividades con filtros
3. Ver detalle → elegir fecha → reservar
4. Ver mis reservas y estado
5. Dejar reseña cuando la actividad esté completada

### Prestador
1. Registrarse → elegir rol "prestador" → completar perfil empresa
2. Panel → crear actividades con fotos y disponibilidad
3. Gestionar reservas (confirmar / rechazar)
4. Ver métricas del dashboard

## Variables de entorno

### Web (`apps/web/.env.local`)
```
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
```

### Mobile (`apps/mobile/.env`)
```
EXPO_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
```

## Próximos pasos (post-MVP)

- [ ] Integración MercadoPago (pagos reales)
- [ ] Notificaciones email con Resend
- [ ] Chat in-app prestador ↔ turista
- [ ] Mapbox para ubicaciones
- [ ] Verificación de prestadores (panel admin)
- [ ] Push notifications mobile
