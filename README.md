# apitreats

Honesty store app built with SvelteKit and Supabase.

## Development

Install dependencies:

```sh
npm install
```

Configure Supabase:

1. Copy `.env.example` to `.env`.
2. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.

Start the dev server:

```sh
npm run dev
```

## Supabase setup

Run the SQL in `supabase/schema.sql` to create tables and policies.
