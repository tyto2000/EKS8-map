# ESK8 mapa – tvoje HTML předělané na Supabase

## Co je změněné
- `index.html` už nečte GeoJSON z Google Drive, ale z tabulky `public.map_features` v Supabase.
- `tool.html` nechává původní GPS logger, povrchy, kvalitu i ikony, ale přidává tlačítko **Uložit do mapy**.
- Přihlášený uživatel může přidávat body a úseky.
- Admin může ve vieweru kliknout na bod/úsek a smazat ho.
- Realtime změny se propisují do mapy bez ručního refreshování.

## Zapojení
1. V Supabase vytvoř nový projekt.
2. V SQL Editoru spusť `supabase.sql`.
3. V `index.html` i `tool.html` doplň:

```js
const SUPABASE_URL = "https://sjmylzrhqrwoggowimtq.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_F3RaL5kYzaJY8iHzLxRKpw_R3lJGLvf";
```

4. Zapni Authentication > Email provider.
5. Zapni Realtime pro tabulku `public.map_features`.
6. Nahraj `index.html` a `tool.html` na GitHub Pages / Vercel / Netlify.

## Nastavení admina
Po registraci vlastního účtu spusť:

```sql
update public.profiles
set role = 'admin'
where email = 'tvuj@email.cz';
```

## Pozor
Do HTML patří pouze **anon public key**. Nikdy tam nedávej `service_role` key.
