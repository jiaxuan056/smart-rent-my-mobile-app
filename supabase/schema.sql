create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text not null default '',
  phone text,
  avatar_url text,
  role text not null default 'customer' check (role in ('customer', 'admin')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cars (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references public.profiles(id) on delete set null,
  brand text not null,
  model text not null,
  year integer not null check (year between 1990 and 2100),
  category text not null,
  powertrain text not null check (
    powertrain in ('petrol_ron95', 'petrol_ron97', 'diesel', 'hybrid_petrol', 'electric')
  ),
  transmission text not null,
  seats integer not null check (seats between 1 and 20),
  daily_rate numeric(10, 2) not null check (daily_rate > 0),
  branch text not null,
  catalogue_rating numeric(2, 1) not null default 0 check (catalogue_rating between 0 and 5),
  description text not null default '',
  color_value bigint not null default 4284926270,
  fuel_efficiency_km_l numeric(6, 2),
  energy_kwh_100km numeric(6, 2),
  image_url text,
  source_name text,
  source_url text,
  availability text not null default 'available' check (
    availability in ('available', 'unavailable', 'maintenance', 'deactivated')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_vehicle_efficiency check (
    (
      powertrain = 'electric'
      and energy_kwh_100km is not null
      and energy_kwh_100km > 0
    )
    or
    (
      powertrain <> 'electric'
      and fuel_efficiency_km_l is not null
      and fuel_efficiency_km_l > 0
    )
  )
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  car_id uuid not null references public.cars(id) on delete restrict,
  pickup_date date not null,
  return_date date not null,
  expected_distance_km numeric(10, 2) not null check (expected_distance_km between 1 and 5000),
  rental_days integer not null check (rental_days > 0),
  rental_cost numeric(10, 2) not null check (rental_cost >= 0),
  energy_rate_snapshot numeric(10, 4) not null check (energy_rate_snapshot >= 0),
  energy_quantity numeric(10, 2) not null check (energy_quantity >= 0),
  estimated_energy_cost numeric(10, 2) not null check (estimated_energy_cost >= 0),
  insurance_cost numeric(10, 2) not null check (insurance_cost >= 0),
  service_fee numeric(10, 2) not null check (service_fee >= 0),
  estimated_total numeric(10, 2) not null check (estimated_total >= 0),
  fuel_price_snapshot jsonb not null default '{}'::jsonb,
  payment_reference text,
  status text not null default 'confirmed' check (
    status in ('confirmed', 'ongoing', 'completed', 'cancelled')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint valid_booking_dates check (return_date > pickup_date)
);

create table if not exists public.favourites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  car_id uuid not null references public.cars(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, car_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete cascade,
  title text not null,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  car_id uuid not null references public.cars(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text not null check (char_length(comment) between 5 and 500),
  is_hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists bookings_car_dates_idx
  on public.bookings (car_id, pickup_date, return_date);
create index if not exists bookings_user_idx
  on public.bookings (user_id, created_at desc);
create index if not exists cars_search_idx
  on public.cars (brand, model, branch, powertrain, availability);
create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);
create index if not exists reviews_car_idx
  on public.reviews (car_id, created_at desc);

alter table public.bookings
  drop constraint if exists no_overlapping_active_bookings;
alter table public.bookings
  add constraint no_overlapping_active_bookings
  exclude using gist (
    car_id with =,
    daterange(pickup_date, return_date, '[)') with &&
  )
  where (status in ('confirmed', 'ongoing'));

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.email, '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and is_active
  );
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.cars enable row level security;
alter table public.bookings enable row level security;
alter table public.favourites enable row level security;
alter table public.notifications enable row level security;
alter table public.reviews enable row level security;

drop policy if exists "profiles_read_own_or_admin" on public.profiles;
create policy "profiles_read_own_or_admin"
  on public.profiles for select to authenticated
  using (auth.uid() = id or public.is_admin());

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin"
  on public.profiles for update to authenticated
  using (auth.uid() = id or public.is_admin())
  with check (auth.uid() = id or public.is_admin());

drop policy if exists "cars_read_catalogue" on public.cars;
create policy "cars_read_catalogue"
  on public.cars for select to authenticated
  using (availability <> 'deactivated' or public.is_admin());

drop policy if exists "cars_admin_manage" on public.cars;
create policy "cars_admin_manage"
  on public.cars for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "bookings_read_own_or_admin" on public.bookings;
create policy "bookings_read_own_or_admin"
  on public.bookings for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "bookings_customer_insert" on public.bookings;
create policy "bookings_customer_insert"
  on public.bookings for insert to authenticated
  with check (user_id = auth.uid() and status = 'confirmed');

drop policy if exists "bookings_admin_update" on public.bookings;
create policy "bookings_admin_update"
  on public.bookings for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "favourites_manage_own" on public.favourites;
create policy "favourites_manage_own"
  on public.favourites for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "notifications_read_own" on public.notifications;
create policy "notifications_read_own"
  on public.notifications for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
  on public.notifications for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "notifications_admin_insert" on public.notifications;
create policy "notifications_admin_insert"
  on public.notifications for insert to authenticated
  with check (public.is_admin());

drop policy if exists "reviews_read_visible_or_admin" on public.reviews;
create policy "reviews_read_visible_or_admin"
  on public.reviews for select to authenticated
  using (not is_hidden or user_id = auth.uid() or public.is_admin());

drop policy if exists "reviews_customer_insert_completed" on public.reviews;
create policy "reviews_customer_insert_completed"
  on public.reviews for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.bookings
      where bookings.id = reviews.booking_id
        and bookings.user_id = auth.uid()
        and bookings.car_id = reviews.car_id
        and bookings.status = 'completed'
    )
  );

drop policy if exists "reviews_admin_update" on public.reviews;
create policy "reviews_admin_update"
  on public.reviews for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());
