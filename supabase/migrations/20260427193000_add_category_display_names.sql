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
