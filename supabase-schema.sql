-- ═══════════════════════════════════════════════════════
--  Anibound · Supabase Database Schema
--  วิธีใช้: Supabase Dashboard → SQL Editor → New query → วาง → Run
-- ═══════════════════════════════════════════════════════

-- ─── Extensions ──────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ─── 1. PROFILES ─────────────────────────────────────────
--  ขยายข้อมูลจาก auth.users (สร้างอัตโนมัติหลัง Google login)
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text,
  avatar_url    text,
  email         text,
  phone         text,
  address       text,
  pet_name      text,
  pet_species   text check (pet_species in ('dog','cat','other','none')),
  is_admin      boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- auto-create profile ทันทีที่ user สมัคร/login ครั้งแรก
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name, avatar_url, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    new.raw_user_meta_data->>'avatar_url',
    new.email
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ─── 2. PRODUCTS ─────────────────────────────────────────
create table if not exists public.products (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  name_th     text,
  description text,
  price       numeric(10,2) not null default 0,
  category    text not null check (category in ('food','toy','care','acc','plant','home')),
  biome       text check (biome in ('forest','river','coast','highland')),
  image_url   text,
  stock       integer not null default 0,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

-- ─── 3. CART ─────────────────────────────────────────────
create table if not exists public.cart (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  product_id  uuid not null references public.products(id) on delete cascade,
  quantity    integer not null default 1 check (quantity > 0),
  created_at  timestamptz not null default now(),
  unique(user_id, product_id)
);

-- ─── 4. ORDERS ───────────────────────────────────────────
create table if not exists public.orders (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references auth.users(id),
  status          text not null default 'pending'
                  check (status in ('pending','confirmed','shipped','delivered','cancelled')),
  total           numeric(10,2) not null default 0,
  shipping_name   text,
  shipping_phone  text,
  shipping_address text,
  note            text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- ─── 5. ORDER ITEMS ──────────────────────────────────────
create table if not exists public.order_items (
  id          uuid primary key default uuid_generate_v4(),
  order_id    uuid not null references public.orders(id) on delete cascade,
  product_id  uuid references public.products(id),
  product_name text not null,   -- snapshot ชื่อสินค้าตอนสั่ง
  quantity    integer not null default 1,
  price       numeric(10,2) not null,
  created_at  timestamptz not null default now()
);

-- ═══════════════════════════════════════════════════════
--  Row Level Security (RLS)
-- ═══════════════════════════════════════════════════════

-- PROFILES
alter table public.profiles enable row level security;
create policy "Users can view own profile"   on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Service can insert profile"   on public.profiles for insert with check (true);

-- PRODUCTS  (ทุกคนดูได้, admin เท่านั้น insert/update/delete)
alter table public.products enable row level security;
create policy "Anyone can view active products" on public.products for select using (active = true);
create policy "Admin full access products"      on public.products for all
  using (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- CART  (แต่ละ user เห็นแค่ตะกร้าตัวเอง)
alter table public.cart enable row level security;
create policy "Users manage own cart" on public.cart for all using (auth.uid() = user_id);

-- ORDERS  (user เห็น order ตัวเอง, admin เห็นทั้งหมด)
alter table public.orders enable row level security;
create policy "Users view own orders" on public.orders for select
  using (auth.uid() = user_id or
    exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));
create policy "Users insert own order" on public.orders for insert with check (auth.uid() = user_id);
create policy "Admin update orders"    on public.orders for update
  using (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- ORDER ITEMS
alter table public.order_items enable row level security;
create policy "Users view own order items" on public.order_items for select
  using (exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid())
      or exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));
create policy "Users insert order items" on public.order_items for insert with check (true);

-- ═══════════════════════════════════════════════════════
--  ตั้งตัวคุณเองเป็น Admin
--  แก้ email ด้านล่างเป็นอีเมลของคุณ แล้ว Run
-- ═══════════════════════════════════════════════════════
-- update public.profiles set is_admin = true
-- where email = 'your-email@gmail.com';
