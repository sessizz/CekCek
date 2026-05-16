-- Callable RPC for atomically incrementing a checklist's download_count.
-- Used by the edge function for anonymous downloads (authenticated downloads
-- are handled by the downloads_increment_count trigger on the downloads table).
create or replace function public.rpc_increment_download_count(p_checklist_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.marketplace_checklists
  set download_count = download_count + 1
  where id = p_checklist_id;
$$;

grant execute on function public.rpc_increment_download_count(uuid) to service_role;
