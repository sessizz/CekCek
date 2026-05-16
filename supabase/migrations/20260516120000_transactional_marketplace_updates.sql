-- Replace marketplace checklist metadata and items atomically.
-- Supabase Edge Functions call this RPC so updates cannot leave a checklist with
-- refreshed metadata but missing items if item replacement fails.

create or replace function public.update_marketplace_checklist_transaction(
    p_user_id uuid,
    p_checklist_id uuid,
    p_title text,
    p_description text,
    p_icon_name text,
    p_category_id uuid,
    p_language text,
    p_items jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
    existing_author uuid;
    existing_version integer;
begin
    select author_id, version
      into existing_author, existing_version
      from public.marketplace_checklists
     where id = p_checklist_id
     for update;

    if existing_author is null then
        raise exception 'Checklist not found.' using errcode = 'P0002';
    end if;

    if existing_author <> p_user_id then
        raise exception 'Not authorized.' using errcode = '42501';
    end if;

    update public.marketplace_checklists
       set title = p_title,
           description = nullif(p_description, ''),
           icon_name = coalesce(nullif(p_icon_name, ''), 'checklist'),
           category_id = p_category_id,
           language = coalesce(nullif(p_language, ''), 'en'),
           item_count = jsonb_array_length(p_items),
           version = existing_version + 1,
           status = 'published'
     where id = p_checklist_id;

    delete from public.marketplace_checklist_items
     where checklist_id = p_checklist_id;

    insert into public.marketplace_checklist_items (checklist_id, title, sort_order)
    select
        p_checklist_id,
        item->>'title',
        coalesce((item->>'sort_order')::integer, ordinal::integer - 1)
    from jsonb_array_elements(p_items) with ordinality as source(item, ordinal);

    return p_checklist_id;
end;
$$;
