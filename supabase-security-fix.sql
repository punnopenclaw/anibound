-- ═══════════════════════════════════════════════════════
--  Anibound · Security fix — คืน RLS ที่ปลอดภัย
--  วิธีใช้: Supabase Dashboard → SQL Editor → New query → วาง → Run
--
--  ⚠️ ก่อนรัน: ต้อง login เข้าเว็บ (login.html) อย่างน้อย 1 ครั้ง
--     เพื่อให้มี row ใน public.profiles ก่อน (trigger สร้างให้อัตโนมัติ)
-- ═══════════════════════════════════════════════════════

-- ── 0. helper: เช็คว่า user ปัจจุบันเป็น admin ไหม ──────────
--     security definer = bypass RLS ของ profiles กัน recursion
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and is_admin = true
  );
$$;

-- ── 1. PRODUCTS: ทุกคนอ่านได้ / เฉพาะ admin เขียน-ลบ ───────
alter table public.products enable row level security;

drop policy if exists "Anyone can view products"        on public.products;
drop policy if exists "Anyone can view active products"  on public.products;
drop policy if exists "Anyone can insert products"       on public.products;
drop policy if exists "Anyone can update products"       on public.products;
drop policy if exists "Anyone can delete products"       on public.products;
drop policy if exists "Admin full access products"       on public.products;

create policy "Public read products"  on public.products
  for select using (true);
create policy "Admin insert products" on public.products
  for insert with check (public.is_admin());
create policy "Admin update products" on public.products
  for update using (public.is_admin()) with check (public.is_admin());
create policy "Admin delete products" on public.products
  for delete using (public.is_admin());

-- ── 2. STORAGE: ทุกคนดูรูปได้ / เฉพาะ admin upload-ลบ ──────
drop policy if exists "Public read product images"  on storage.objects;
drop policy if exists "Anon upload product images"  on storage.objects;
drop policy if exists "Anon delete product images"  on storage.objects;
drop policy if exists "Admin upload product images" on storage.objects;
drop policy if exists "Admin update product images" on storage.objects;
drop policy if exists "Admin delete product images" on storage.objects;

create policy "Public read product images"  on storage.objects
  for select using (bucket_id = 'product-images');
create policy "Admin upload product images" on storage.objects
  for insert with check (bucket_id = 'product-images' and public.is_admin());
create policy "Admin update product images" on storage.objects
  for update using (bucket_id = 'product-images' and public.is_admin());
create policy "Admin delete product images" on storage.objects
  for delete using (bucket_id = 'product-images' and public.is_admin());

-- ── 3. ORDER ITEMS: insert ได้เฉพาะ item ของออเดอร์ตัวเอง ──
drop policy if exists "Users insert order items" on public.order_items;
create policy "Users insert order items" on public.order_items
  for insert with check (
    exists (select 1 from public.orders o
            where o.id = order_id and o.user_id = auth.uid())
  );

-- ── 4. ตั้งตัวคุณเองเป็น admin ─────────────────────────────
--     ⚠️ แก้อีเมลให้ตรงกับอีเมลที่คุณใช้ login เว็บ
update public.profiles set is_admin = true
where email = 'punn.openclaw@gmail.com';

-- ตรวจสอบผล: ควรเห็น is_admin = true
-- select email, is_admin from public.profiles;
