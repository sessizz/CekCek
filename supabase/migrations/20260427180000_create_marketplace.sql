create extension if not exists pgcrypto;

do $$
begin
    if not exists (select 1 from pg_type where typname = 'marketplace_checklist_status') then
        create type public.marketplace_checklist_status as enum (
            'pending_review',
            'published',
            'rejected',
            'removed'
        );
    end if;

    if not exists (select 1 from pg_type where typname = 'marketplace_review_status') then
        create type public.marketplace_review_status as enum (
            'visible',
            'hidden',
            'removed'
        );
    end if;

    if not exists (select 1 from pg_type where typname = 'marketplace_report_reason') then
        create type public.marketplace_report_reason as enum (
            'spam',
            'offensive',
            'misleading',
            'copyright',
            'other'
        );
    end if;

    if not exists (select 1 from pg_type where typname = 'marketplace_report_status') then
        create type public.marketplace_report_status as enum (
            'pending',
            'reviewed',
            'actioned',
            'dismissed'
        );
    end if;
end $$;

create table if not exists public.users (
    id uuid primary key default gen_random_uuid(),
    cloudkit_user_id text not null unique,
    display_name text not null default 'Anonymous',
    avatar_url text,
    is_banned boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint users_display_name_length check (char_length(display_name) between 1 and 80)
);

create table if not exists public.categories (
    id uuid primary key default gen_random_uuid(),
    name_key text not null unique,
    display_name_tr text,
    display_name_en text,
    icon_name text not null,
    sort_order integer not null default 0,
    is_active boolean not null default true,
    constraint categories_display_name_tr_length check (
        display_name_tr is null or char_length(display_name_tr) between 1 and 80
    ),
    constraint categories_display_name_en_length check (
        display_name_en is null or char_length(display_name_en) between 1 and 80
    )
);

create table if not exists public.marketplace_checklists (
    id uuid primary key default gen_random_uuid(),
    author_id uuid not null references public.users(id) on delete cascade,
    category_id uuid references public.categories(id) on delete set null,
    title text not null,
    description text,
    icon_name text not null default 'checklist',
    language text not null default 'en',
    item_count integer not null default 0,
    download_count integer not null default 0,
    average_rating numeric(3, 2) not null default 0,
    rating_count integer not null default 0,
    status public.marketplace_checklist_status not null default 'pending_review',
    version integer not null default 1,
    source_checklist_id uuid,
    fts tsvector generated always as (
        to_tsvector(
            'simple',
            coalesce(title, '') || ' ' || coalesce(description, '')
        )
    ) stored,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint marketplace_checklists_title_length check (char_length(title) between 1 and 120),
    constraint marketplace_checklists_description_length check (
        description is null or char_length(description) <= 1000
    ),
    constraint marketplace_checklists_language_length check (char_length(language) between 2 and 8),
    constraint marketplace_checklists_item_count_positive check (item_count >= 0),
    constraint marketplace_checklists_download_count_positive check (download_count >= 0),
    constraint marketplace_checklists_rating_count_positive check (rating_count >= 0),
    constraint marketplace_checklists_average_rating_range check (
        average_rating >= 0 and average_rating <= 5
    )
);

create table if not exists public.marketplace_checklist_items (
    id uuid primary key default gen_random_uuid(),
    checklist_id uuid not null references public.marketplace_checklists(id) on delete cascade,
    title text not null,
    sort_order integer not null default 0,
    constraint marketplace_items_title_length check (char_length(title) between 1 and 240)
);

create table if not exists public.ratings (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    checklist_id uuid not null references public.marketplace_checklists(id) on delete cascade,
    score integer not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint ratings_score_range check (score between 1 and 5),
    unique (user_id, checklist_id)
);

create table if not exists public.reviews (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    checklist_id uuid not null references public.marketplace_checklists(id) on delete cascade,
    body text not null,
    status public.marketplace_review_status not null default 'visible',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint reviews_body_length check (char_length(body) between 10 and 1000),
    unique (user_id, checklist_id)
);

create table if not exists public.downloads (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references public.users(id) on delete cascade,
    checklist_id uuid not null references public.marketplace_checklists(id) on delete cascade,
    downloaded_at timestamptz not null default now(),
    unique (user_id, checklist_id)
);

create table if not exists public.reports (
    id uuid primary key default gen_random_uuid(),
    reporter_id uuid not null references public.users(id) on delete cascade,
    checklist_id uuid references public.marketplace_checklists(id) on delete cascade,
    review_id uuid references public.reviews(id) on delete cascade,
    reason public.marketplace_report_reason not null,
    details text,
    status public.marketplace_report_status not null default 'pending',
    created_at timestamptz not null default now(),
    constraint reports_target_required check (
        (checklist_id is not null and review_id is null)
        or (checklist_id is null and review_id is not null)
    ),
    constraint reports_details_length check (details is null or char_length(details) <= 1000)
);

create index if not exists categories_active_sort_idx
    on public.categories (is_active, sort_order);

alter table public.categories
    add column if not exists display_name_tr text,
    add column if not exists display_name_en text;

do $$
begin
    if not exists (
        select 1 from pg_constraint where conname = 'categories_display_name_tr_length'
    ) then
        alter table public.categories
            add constraint categories_display_name_tr_length check (
                display_name_tr is null or char_length(display_name_tr) between 1 and 80
            );
    end if;

    if not exists (
        select 1 from pg_constraint where conname = 'categories_display_name_en_length'
    ) then
        alter table public.categories
            add constraint categories_display_name_en_length check (
                display_name_en is null or char_length(display_name_en) between 1 and 80
            );
    end if;
end $$;

create index if not exists marketplace_checklists_published_idx
    on public.marketplace_checklists (status, average_rating desc, download_count desc, created_at desc);

create index if not exists marketplace_checklists_category_idx
    on public.marketplace_checklists (category_id, status, created_at desc);

create index if not exists marketplace_checklists_author_idx
    on public.marketplace_checklists (author_id, created_at desc);

create index if not exists marketplace_checklists_fts_idx
    on public.marketplace_checklists using gin (fts);

create index if not exists marketplace_items_checklist_sort_idx
    on public.marketplace_checklist_items (checklist_id, sort_order);

create index if not exists ratings_checklist_idx
    on public.ratings (checklist_id);

create index if not exists reviews_checklist_visible_idx
    on public.reviews (checklist_id, status, created_at desc);

create index if not exists downloads_checklist_idx
    on public.downloads (checklist_id);

create index if not exists reports_checklist_pending_idx
    on public.reports (checklist_id, status);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
before update on public.users
for each row execute function public.set_updated_at();

drop trigger if exists marketplace_checklists_set_updated_at on public.marketplace_checklists;
create trigger marketplace_checklists_set_updated_at
before update on public.marketplace_checklists
for each row execute function public.set_updated_at();

drop trigger if exists ratings_set_updated_at on public.ratings;
create trigger ratings_set_updated_at
before update on public.ratings
for each row execute function public.set_updated_at();

drop trigger if exists reviews_set_updated_at on public.reviews;
create trigger reviews_set_updated_at
before update on public.reviews
for each row execute function public.set_updated_at();

create or replace function public.refresh_marketplace_rating_summary()
returns trigger
language plpgsql
as $$
declare
    target_checklist_id uuid;
begin
    target_checklist_id = coalesce(new.checklist_id, old.checklist_id);

    update public.marketplace_checklists
    set
        average_rating = coalesce((
            select round(avg(score)::numeric, 2)
            from public.ratings
            where checklist_id = target_checklist_id
        ), 0),
        rating_count = (
            select count(*)::integer
            from public.ratings
            where checklist_id = target_checklist_id
        )
    where id = target_checklist_id;

    return null;
end;
$$;

drop trigger if exists ratings_refresh_summary_insert on public.ratings;
create trigger ratings_refresh_summary_insert
after insert on public.ratings
for each row execute function public.refresh_marketplace_rating_summary();

drop trigger if exists ratings_refresh_summary_update on public.ratings;
create trigger ratings_refresh_summary_update
after update on public.ratings
for each row execute function public.refresh_marketplace_rating_summary();

drop trigger if exists ratings_refresh_summary_delete on public.ratings;
create trigger ratings_refresh_summary_delete
after delete on public.ratings
for each row execute function public.refresh_marketplace_rating_summary();

create or replace function public.increment_marketplace_download_count()
returns trigger
language plpgsql
as $$
begin
    update public.marketplace_checklists
    set download_count = download_count + 1
    where id = new.checklist_id;

    return new;
end;
$$;

drop trigger if exists downloads_increment_count on public.downloads;
create trigger downloads_increment_count
after insert on public.downloads
for each row execute function public.increment_marketplace_download_count();

create or replace function public.hide_reported_marketplace_content()
returns trigger
language plpgsql
as $$
begin
    if new.checklist_id is not null then
        update public.marketplace_checklists
        set status = 'pending_review'
        where id = new.checklist_id
          and status = 'published'
          and (
              select count(*)
              from public.reports
              where checklist_id = new.checklist_id
                and status = 'pending'
          ) >= 3;
    end if;

    if new.review_id is not null then
        update public.reviews
        set status = 'hidden'
        where id = new.review_id
          and status = 'visible'
          and (
              select count(*)
              from public.reports
              where review_id = new.review_id
                and status = 'pending'
          ) >= 3;
    end if;

    return new;
end;
$$;

drop trigger if exists reports_hide_content on public.reports;
create trigger reports_hide_content
after insert on public.reports
for each row execute function public.hide_reported_marketplace_content();

alter table public.users enable row level security;
alter table public.categories enable row level security;
alter table public.marketplace_checklists enable row level security;
alter table public.marketplace_checklist_items enable row level security;
alter table public.ratings enable row level security;
alter table public.reviews enable row level security;
alter table public.downloads enable row level security;
alter table public.reports enable row level security;

drop policy if exists users_read_own_or_published_author on public.users;
create policy users_read_own_or_published_author
on public.users for select
using (
    id = auth.uid()
    or exists (
        select 1
        from public.marketplace_checklists checklist
        where checklist.author_id = users.id
          and checklist.status = 'published'
    )
);

drop policy if exists users_update_own_profile on public.users;
create policy users_update_own_profile
on public.users for update
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists categories_read_active on public.categories;
create policy categories_read_active
on public.categories for select
using (is_active = true);

drop policy if exists checklists_read_published_or_own on public.marketplace_checklists;
create policy checklists_read_published_or_own
on public.marketplace_checklists for select
using (status = 'published' or author_id = auth.uid());

drop policy if exists checklists_insert_own on public.marketplace_checklists;
create policy checklists_insert_own
on public.marketplace_checklists for insert
with check (
    author_id = auth.uid()
    and exists (
        select 1 from public.users
        where id = auth.uid()
          and is_banned = false
    )
);

drop policy if exists checklists_update_own on public.marketplace_checklists;
create policy checklists_update_own
on public.marketplace_checklists for update
using (author_id = auth.uid())
with check (author_id = auth.uid());

drop policy if exists checklists_delete_own on public.marketplace_checklists;
create policy checklists_delete_own
on public.marketplace_checklists for delete
using (author_id = auth.uid());

drop policy if exists checklist_items_read_published_or_own on public.marketplace_checklist_items;
create policy checklist_items_read_published_or_own
on public.marketplace_checklist_items for select
using (
    exists (
        select 1
        from public.marketplace_checklists checklist
        where checklist.id = marketplace_checklist_items.checklist_id
          and (checklist.status = 'published' or checklist.author_id = auth.uid())
    )
);

drop policy if exists checklist_items_write_own on public.marketplace_checklist_items;
create policy checklist_items_write_own
on public.marketplace_checklist_items for all
using (
    exists (
        select 1
        from public.marketplace_checklists checklist
        where checklist.id = marketplace_checklist_items.checklist_id
          and checklist.author_id = auth.uid()
    )
)
with check (
    exists (
        select 1
        from public.marketplace_checklists checklist
        where checklist.id = marketplace_checklist_items.checklist_id
          and checklist.author_id = auth.uid()
    )
);

drop policy if exists ratings_read_published on public.ratings;
create policy ratings_read_published
on public.ratings for select
using (
    exists (
        select 1
        from public.marketplace_checklists checklist
        where checklist.id = ratings.checklist_id
          and checklist.status = 'published'
    )
);

drop policy if exists ratings_write_own on public.ratings;
create policy ratings_write_own
on public.ratings for all
using (user_id = auth.uid())
with check (
    user_id = auth.uid()
    and exists (
        select 1 from public.users
        where id = auth.uid()
          and is_banned = false
    )
    and exists (
        select 1
        from public.marketplace_checklists checklist
        where checklist.id = ratings.checklist_id
          and checklist.status = 'published'
    )
);

drop policy if exists reviews_read_visible on public.reviews;
create policy reviews_read_visible
on public.reviews for select
using (
    status = 'visible'
    and exists (
        select 1
        from public.marketplace_checklists checklist
        where checklist.id = reviews.checklist_id
          and checklist.status = 'published'
    )
);

drop policy if exists reviews_write_own on public.reviews;
create policy reviews_write_own
on public.reviews for all
using (user_id = auth.uid())
with check (
    user_id = auth.uid()
    and exists (
        select 1 from public.users
        where id = auth.uid()
          and is_banned = false
    )
    and exists (
        select 1
        from public.marketplace_checklists checklist
        where checklist.id = reviews.checklist_id
          and checklist.status = 'published'
    )
);

drop policy if exists downloads_read_own on public.downloads;
create policy downloads_read_own
on public.downloads for select
using (user_id = auth.uid());

drop policy if exists downloads_insert_own on public.downloads;
create policy downloads_insert_own
on public.downloads for insert
with check (
    user_id = auth.uid()
    and exists (
        select 1 from public.users
        where id = auth.uid()
          and is_banned = false
    )
    and exists (
        select 1
        from public.marketplace_checklists checklist
        where checklist.id = downloads.checklist_id
          and checklist.status = 'published'
    )
);

drop policy if exists reports_insert_own on public.reports;
create policy reports_insert_own
on public.reports for insert
with check (
    reporter_id = auth.uid()
    and exists (
        select 1 from public.users
        where id = auth.uid()
          and is_banned = false
    )
);

grant usage on schema public to anon, authenticated;
grant select on public.users to anon, authenticated;
grant select on public.categories to anon, authenticated;
grant select on public.marketplace_checklists to anon, authenticated;
grant select on public.marketplace_checklist_items to anon, authenticated;
grant select on public.ratings to anon, authenticated;
grant select on public.reviews to anon, authenticated;
grant insert, update, delete on public.marketplace_checklists to authenticated;
grant insert, update, delete on public.marketplace_checklist_items to authenticated;
grant insert, update, delete on public.ratings to authenticated;
grant insert, update, delete on public.reviews to authenticated;
grant insert, select on public.downloads to authenticated;
grant insert on public.reports to authenticated;
grant update on public.users to authenticated;

insert into public.categories (id, name_key, display_name_tr, display_name_en, icon_name, sort_order, is_active)
values
    ('92eea4ed-8d85-4e86-a08f-8a4f037a1e01', 'marketplace.category.rv', 'Karavan', 'RV', 'car.side', 0, true),
    ('88c8f636-68a7-4c62-baf0-8eca55c0b12a', 'marketplace.category.camping', 'Kamp', 'Camping', 'tent', 1, true),
    ('2a06b90f-7af5-43dd-936c-18bb845e09f8', 'marketplace.category.travel', 'Seyahat', 'Travel', 'map', 2, true),
    ('8b38e06f-2652-49e2-a015-df3b9332f650', 'marketplace.category.aviation', 'Havacılık', 'Aviation', 'airplane', 3, true),
    ('7231b0d0-8045-4d77-a018-842dc5fc1a2c', 'marketplace.category.marine', 'Denizcilik', 'Marine', 'ferry', 4, true),
    ('0529798d-2f25-454f-b1a4-4421e2a3f693', 'marketplace.category.home', 'Ev', 'Home', 'house', 5, true),
    ('3c6047c3-50b6-43c2-8ed6-df109688ed92', 'marketplace.category.vehicle', 'Araç', 'Vehicle', 'wrench.and.screwdriver', 6, true),
    ('f38b10a0-071b-41d3-a556-bfb60c46ef86', 'marketplace.category.other', 'Diğer', 'Other', 'square.grid.2x2', 7, true)
on conflict (id) do update
set
    name_key = excluded.name_key,
    display_name_tr = excluded.display_name_tr,
    display_name_en = excluded.display_name_en,
    icon_name = excluded.icon_name,
    sort_order = excluded.sort_order,
    is_active = excluded.is_active;
