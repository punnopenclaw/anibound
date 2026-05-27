-- ═══════════════════════════════════════════════════════
--  Anibound · Products table migration
--  วิธีใช้: Supabase Dashboard → SQL Editor → New query → วาง → Run
-- ═══════════════════════════════════════════════════════

-- 1. เพิ่ม columns ที่ admin panel ใช้
alter table public.products
  add column if not exists tag       text,
  add column if not exists pet_type  text,
  add column if not exists images    jsonb not null default '[]';

-- 2. ลบ check constraint ที่ block ค่าภาษาไทย/ค่าใหม่
alter table public.products drop constraint if exists products_category_check;
alter table public.products drop constraint if exists products_biome_check;

-- 3. อนุญาตให้ admin panel (anon key) จัดการสินค้าได้
--    (ป้องกันด้วย URL ของ admin.html แทน RLS ในขั้นตอนนี้)
drop policy if exists "Admin full access products" on public.products;
drop policy if exists "Anon can manage products"   on public.products;
drop policy if exists "Anyone can view active products" on public.products;

create policy "Anyone can view products"    on public.products for select using (true);
create policy "Anyone can insert products"  on public.products for insert with check (true);
create policy "Anyone can update products"  on public.products for update using (true);
create policy "Anyone can delete products"  on public.products for delete using (true);

-- 4. Storage bucket สำหรับรูปสินค้า (ถ้ายังไม่มี)
insert into storage.buckets (id, name, public)
  values ('product-images', 'product-images', true)
  on conflict (id) do nothing;

drop policy if exists "Public read product images"  on storage.objects;
drop policy if exists "Anon upload product images"  on storage.objects;
drop policy if exists "Anon delete product images"  on storage.objects;

create policy "Public read product images"
  on storage.objects for select using (bucket_id = 'product-images');
create policy "Anon upload product images"
  on storage.objects for insert with check (bucket_id = 'product-images');
create policy "Anon delete product images"
  on storage.objects for delete using (bucket_id = 'product-images');
