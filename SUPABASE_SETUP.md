# Supabase — Setup del Proyecto AnestoTrack

## 1. Crear el proyecto en supabase.com

1. Ir a https://supabase.com/dashboard
2. Click **"New project"**
3. Organization: **Altumware** (o la que corresponda)
4. Project name: `anestotrack`
5. Database password: guárdalo en un lugar seguro
6. Region: **South America (São Paulo)** — us-east-1 si prefieres
7. Click **"Create new project"** — esperar ~2 minutos

---

## 2. Ejecutar las migraciones

Una vez creado el proyecto, abrir el **SQL Editor** de Supabase y ejecutar los archivos en orden:

| Orden | Archivo |
|-------|---------|
| 1 | `supabase/migrations/20260425000001_initial_schema.sql` |
| 2 | `supabase/migrations/20260425000002_rls_policies.sql` |
| 3 | `supabase/migrations/20260425000003_functions_rpc.sql` |
| 4 | `supabase/migrations/20260425000004_views.sql` |
| 5 | `supabase/migrations/20260425000005_triggers.sql` |

> **Tip**: Puedes copiar y pegar el contenido de cada archivo en el SQL Editor, o usar el Supabase CLI:
> ```powershell
> npx supabase db push --linked
> ```

---

## 3. Obtener las claves del proyecto

En Supabase Dashboard → **Project Settings** → **API**:

| Campo | Dónde está |
|-------|-----------|
| `SUPABASE_URL` | Project URL (ej: `https://xyzxyz.supabase.co`) |
| `SUPABASE_ANON_KEY` | `anon` `public` key |
| `JWT_SECRET` | Project Settings → API → JWT Settings → JWT Secret |

---

## 4. Actualizar los environments en cada repo

### anestotrack-web — `src/environments/environment.ts`
```typescript
export const environment = {
  production: false,
  supabaseUrl:     'https://TU_PROYECTO.supabase.co',
  supabaseAnonKey: 'TU_ANON_KEY',
  apiUrl:          'http://localhost:5001/api'
};
```

### anestotrack-web — `src/environments/environment.prod.ts`
```typescript
export const environment = {
  production: true,
  supabaseUrl:     'https://TU_PROYECTO.supabase.co',
  supabaseAnonKey: 'TU_ANON_KEY',
  apiUrl:          'https://api.anestotrack.altumware.com/api'
};
```

### anestotrack-api — `src/AnestoTrack.Api/appsettings.json`
```json
{
  "ConnectionStrings": {
    "Postgres": "Host=db.TU_PROYECTO.supabase.co;Port=5432;Database=postgres;Username=postgres;Password=TU_DB_PASSWORD;SSL Mode=Require;"
  },
  "Jwt": {
    "Secret": "TU_JWT_SECRET",
    "Issuer": "https://TU_PROYECTO.supabase.co/auth/v1"
  }
}
```

### anestotrack-mobile — `src/environments/environment.ts`
```typescript
export const environment = {
  production: false,
  supabaseUrl:     'https://TU_PROYECTO.supabase.co',
  supabaseAnonKey: 'TU_ANON_KEY',
  apiUrl:          'http://localhost:5001/api'
};
```

---

## 5. Crear usuario anestesista inicial

En Supabase Dashboard → **Authentication** → **Users** → **Invite user**:
- Email: `dr.colorado@altumware.com` (o el correo real del doctor)
- Enviará correo de confirmación

O vía SQL Editor:
```sql
-- Solo para testing, sin confirmación de email
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, role)
VALUES (
  gen_random_uuid(),
  'admin@anestotrack.com',
  crypt('TuPasswordSeguro123!', gen_salt('bf')),
  now(),
  'authenticated'
);
```

---

## 6. Verificar que todo funciona

1. Iniciar el API: `cd anestotrack-api; dotnet run --project src/AnestoTrack.Api`
2. Iniciar el Web: `cd anestotrack-web; ng serve`
3. Abrir http://localhost:4200 → pantalla de Login
4. Iniciar sesión con el usuario creado → debería llegar al Dashboard

---

## Notas de seguridad

- **NUNCA** commitear las keys reales al repositorio
- Usar variables de entorno en CI/CD (GitHub Secrets)
- Para Vercel: Environment Variables en el dashboard del proyecto
- Para el API en Railway/Azure: App Settings o Secret Manager
