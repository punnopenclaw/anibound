-- ═══════════════════════════════════════════════════════
--  Anibound · Supabase Schema (ฉบับจริง / canonical)
--  วิธีใช้: Supabase Dashboard → SQL Editor → New query → วาง → Run
--
--  ไฟล์นี้คือ "แหล่งความจริงเดียว" (source of truth) ของฐานข้อมูล
--  รันซ้ำได้ปลอดภัย (idempotent) — ใช้ reconcile DB ที่มีอยู่ให้ตรงสเปคได้
--
--  ⚠️ แทนที่ไฟล์เก่าทั้ง 2:
--     - supabase-products-migration.sql  (เก็บไว้เป็นประวัติ)
--     - supabase-security-fix.sql          (เก็บไว้เป็นประวัติ)
-- ═══════════════════════════════════════════════════════

create extension if not exists "uuid-ossp";

-- ─── helper: เช็คว่า user ปัจจุบันเป็น admin ไหม ───────────
create or replace function public.is_admin()
returns boolean language sql security definer stable
set search_path = public as $$
  select exists (select 1 from public.profiles
                 where id = auth.uid() and is_admin = true);
$$;

-- ═══ 1. PROFILES ═════════════════════════════════════════
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text,
  avatar_url    text,
  email         text,
  phone         text,
  address       text,
  pet_name      text,
  pet_species   text,
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

-- ═══ 2. PRODUCTS ═════════════════════════════════════════
--  หมายเหตุ: category เก็บเป็น "ข้อความไทย" (อาหาร/ของใช้/ของเล่น/เสื้อ)
--            biome เก็บเป็น scene id ของหน้าร้าน (5 ฉาก)
create table if not exists public.products (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  name_th     text,
  description text,
  price       numeric(10,2) not null default 0,
  category    text,
  biome       text,
  tag         text,
  pet_type    text,
  image_url   text,                       -- legacy (ไม่ใช้แล้ว ใช้ images แทน)
  images      jsonb not null default '[]', -- array ของ public URL รูปสินค้า
  stock       integer not null default 0,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

-- เติมคอลัมน์ที่อาจขาด (กรณี table มีอยู่ก่อนแล้ว)
alter table public.products add column if not exists tag      text;
alter table public.products add column if not exists pet_type text;
alter table public.products add column if not exists images   jsonb not null default '[]';

-- ─── Validation (ไม่ strict กับ category เพราะเป็น free text ไทย) ───
alter table public.products drop constraint if exists products_category_check;
alter table public.products drop constraint if exists products_biome_check;
alter table public.products drop constraint if exists products_price_check;

-- biome: จำกัดเป็น 5 ฉากของเว็บ (NULL อนุญาต) — ถ้าเพิ่มฉากใหม่ต้องแก้ที่นี่ด้วย
alter table public.products add constraint products_biome_check
  check (biome is null or biome in ('jungle','sea','wetland','meadow','highland'));
-- ราคาต้องไม่ติดลบ
alter table public.products add constraint products_price_check
  check (price >= 0);

-- ═══ 3. CART ═════════════════════════════════════════════
create table if not exists public.cart (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  product_id  uuid not null references public.products(id) on delete cascade,
  quantity    integer not null default 1 check (quantity > 0),
  created_at  timestamptz not null default now(),
  unique(user_id, product_id)
);

-- ═══ 4. ORDERS ═══════════════════════════════════════════
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

-- ═══ 5. ORDER ITEMS ══════════════════════════════════════
create table if not exists public.order_items (
  id           uuid primary key default uuid_generate_v4(),
  order_id     uuid not null references public.orders(id) on delete cascade,
  product_id   uuid references public.products(id),
  product_name text not null,
  quantity     integer not null default 1,
  price        numeric(10,2) not null,
  created_at   timestamptz not null default now()
);

-- ═══════════════════════════════════════════════════════
--  Row Level Security (RLS)
-- ═══════════════════════════════════════════════════════

-- ─── PROFILES ───
alter table public.profiles enable row level security;
drop policy if exists "Users can view own profile"   on public.profiles;
drop policy if exists "Users can update own profile"  on public.profiles;
drop policy if exists "Service can insert profile"    on public.profiles;
create policy "Users can view own profile"   on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Service can insert profile"   on public.profiles for insert with check (true);

-- ─── PRODUCTS — ทุกคนอ่าน / เฉพาะ admin เขียน-ลบ ───
alter table public.products enable row level security;
drop policy if exists "Anyone can view products"        on public.products;
drop policy if exists "Anyone can view active products"  on public.products;
drop policy if exists "Anyone can insert products"       on public.products;
drop policy if exists "Anyone can update products"       on public.products;
drop policy if exists "Anyone can delete products"       on public.products;
drop policy if exists "Admin full access products"       on public.products;
drop policy if exists "Public read products"             on public.products;
drop policy if exists "Admin insert products"            on public.products;
drop policy if exists "Admin update products"            on public.products;
drop policy if exists "Admin delete products"            on public.products;
create policy "Public read products"  on public.products for select using (true);
create policy "Admin insert products" on public.products for insert with check (public.is_admin());
create policy "Admin update products" on public.products for update using (public.is_admin()) with check (public.is_admin());
create policy "Admin delete products" on public.products for delete using (public.is_admin());

-- ─── CART — แต่ละ user เห็นแค่ตะกร้าตัวเอง ───
alter table public.cart enable row level security;
drop policy if exists "Users manage own cart" on public.cart;
create policy "Users manage own cart" on public.cart for all using (auth.uid() = user_id);

-- ─── ORDERS — user เห็น order ตัวเอง / admin เห็นหมด ───
alter table public.orders enable row level security;
drop policy if exists "Users view own orders" on public.orders;
drop policy if exists "Users insert own order" on public.orders;
drop policy if exists "Admin update orders"    on public.orders;
create policy "Users view own orders"  on public.orders for select
  using (auth.uid() = user_id or public.is_admin());
create policy "Users insert own order" on public.orders for insert with check (auth.uid() = user_id);
create policy "Admin update orders"    on public.orders for update using (public.is_admin());

-- ─── ORDER ITEMS ───
alter table public.order_items enable row level security;
drop policy if exists "Users view own order items" on public.order_items;
drop policy if exists "Users insert order items"   on public.order_items;
create policy "Users view own order items" on public.order_items for select
  using (exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid())
      or public.is_admin());
create policy "Users insert order items" on public.order_items for insert with check (
  exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid()));

-- ═══════════════════════════════════════════════════════
--  STORAGE — รูปสินค้า: ทุกคนดูได้ / เฉพาะ admin จัดการ
-- ═══════════════════════════════════════════════════════
insert into storage.buckets (id, name, public)
  values ('product-images', 'product-images', true)
  on conflict (id) do nothing;

drop policy if exists "Public read product images"  on storage.objects;
drop policy if exists "Anon upload product images"  on storage.objects;
drop policy if exists "Anon delete product images"  on storage.objects;
drop policy if exists "Admin upload product images" on storage.objects;
drop policy if exists "Admin update product images" on storage.objects;
drop policy if exists "Admin delete product images" on storage.objects;
create policy "Public read product images"  on storage.objects for select using (bucket_id = 'product-images');
create policy "Admin upload product images" on storage.objects for insert with check (bucket_id = 'product-images' and public.is_admin());
create policy "Admin update product images" on storage.objects for update using (bucket_id = 'product-images' and public.is_admin());
create policy "Admin delete product images" on storage.objects for delete using (bucket_id = 'product-images' and public.is_admin());

-- ═══════════════════════════════════════════════════════
--  ตั้งตัวคุณเองเป็น Admin (ต้อง login เว็บ 1 ครั้งก่อน)
--  แก้อีเมลให้ตรงกับที่คุณใช้ login แล้ว uncomment + Run
-- ═══════════════════════════════════════════════════════
-- update public.profiles set is_admin = true where email = 'punn.openclaw@gmail.com';
