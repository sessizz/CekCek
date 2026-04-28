-- Allow anonymous (unauthenticated) downloads to be recorded.
-- user_id becomes nullable; the unique constraint only applies when user_id is present.

ALTER TABLE public.downloads ALTER COLUMN user_id DROP NOT NULL;

-- Drop the old constraint (required both columns to be non-null)
ALTER TABLE public.downloads DROP CONSTRAINT IF EXISTS downloads_user_id_checklist_id_key;

-- Partial unique index: one row per authenticated user per checklist;
-- anonymous rows (user_id IS NULL) are always inserted as new rows.
CREATE UNIQUE INDEX IF NOT EXISTS downloads_authenticated_unique
  ON public.downloads (user_id, checklist_id)
  WHERE user_id IS NOT NULL;
