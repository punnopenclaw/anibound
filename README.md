# Anibound — ร้านสินค้าสัตว์เลี้ยง 🐾

เว็บร้านค้าออนไลน์ธีมธรรมชาติ 5 ฉาก (ป่า / ทะเล / บึง / ทุ่ง / เขาสูง)
สร้างด้วย HTML/CSS/JS ล้วน + Supabase เป็น backend, deploy บน Vercel

🔗 **Production:** https://anibound.vercel.app
📦 **Repo:** https://github.com/punnopenclaw/anibound

---

## โครงสร้างไฟล์

| ไฟล์ | หน้าที่ |
|------|---------|
| `index.html` | หน้าร้าน — 5 ฉาก + การ์ดสินค้า + modal รายละเอียด + ตะกร้า |
| `admin.html` | หลังบ้าน — จัดการสินค้า/ออเดอร์/สมาชิก (**ต้อง login + เป็น admin**) |
| `login.html` / `signup.html` | เข้าสู่ระบบ / สมัคร (Google หรือ email) |
| `auth-callback.html` | รับ redirect หลัง Google OAuth |
| `supabase-client.js` | ตั้งค่า Supabase + ฟังก์ชัน auth (URL/anon key อยู่ที่นี่) |
| `supabase-schema.sql` | **schema ฉบับจริง (source of truth)** — รันซ้ำได้ |
| `fonts/` | ฟอนต์ self-hosted (Crimson Text, Satoshi, Mitr, IBM Plex Sans Thai) |
| `.github/workflows/keep-supabase-alive.yml` | กัน Supabase free pause (ยิง query รายวัน) |
| `supabase-products-migration.sql`, `supabase-security-fix.sql` | **ประวัติเท่านั้น** — ของจริงรวมใน `supabase-schema.sql` แล้ว |

---

## การ deploy

- **Frontend:** push ขึ้น GitHub `main` → Vercel auto-deploy เอง (ไม่ต้องทำอะไรเพิ่ม)
- **Backend (Supabase):** แก้ schema → เอา SQL ไปรันใน Supabase Dashboard → SQL Editor เอง

```bash
git add . && git commit -m "..." && git push   # = deploy หน้าเว็บ
```

รันในเครื่อง (static ล้วน ไม่ต้อง build):
```bash
python3 -m http.server 8000      # หรือ  npx serve .
```

---

## ความปลอดภัย (security model)

- `anon key` ใน `supabase-client.js` **เปิดเผยได้** (ออกแบบมาให้ public) — ความปลอดภัยจริงอยู่ที่ **RLS** ใน DB
- **สินค้า + รูป:** ทุกคนอ่าน/ดูได้ แต่ **เพิ่ม/แก้/ลบ ได้เฉพาะ admin** (`profiles.is_admin = true`)
- **ออเดอร์ + โปรไฟล์:** user เห็นเฉพาะของตัวเอง, admin เห็นหมด
- **`admin.html`** มี gate: ไม่ login → เด้งไป login, ไม่ใช่ admin → ขึ้น "⛔ ไม่มีสิทธิ์"
- ข้อมูลทุกอย่างที่ผู้ใช้กรอกถูก **escape ก่อน render** (กัน stored XSS)

### ตั้งตัวเองเป็น admin
1. login เว็บ 1 ครั้งด้วยอีเมลที่ต้องการ (เพื่อให้มี row ใน `profiles`)
2. Supabase → SQL Editor → รัน:
   ```sql
   update public.profiles set is_admin = true where email = 'อีเมลคุณ';
   ```

---

## กัน Supabase ถูก pause

Supabase free tier จะ **pause เมื่อไม่มี activity เกิน 7 วัน** → เว็บทั้งหมดล่ม
GitHub Actions (`keep-supabase-alive.yml`) ยิง query รายวัน ~10:17 น. กันไว้แล้ว

> ⚠️ GitHub จะปิด scheduled workflow ถ้า repo ไม่มี commit เกิน 60 วัน — ปกติ push บ่อยอยู่แล้วไม่มีปัญหา ถ้าหยุดนานจะมีอีเมลเตือนให้กดเปิดใหม่

ถ้าโดน pause: Supabase Dashboard → โปรเจกต์ → **Resume project** (รอ ~2-3 นาที)

---

## หมายเหตุข้อมูล (gotchas)

- **`category`** เก็บเป็น **ข้อความไทย** (อาหาร/ของใช้/ของเล่น/เสื้อ) ไม่ใช่โค้ดอังกฤษ
- **`biome`** เก็บเป็น scene id: `jungle / sea / wetland / meadow / highland` (ตรงกับ 5 ฉากในหน้าร้าน) — เพิ่มฉากใหม่ต้องแก้ทั้ง HTML และ `products_biome_check` ใน `supabase-schema.sql`
- **รูปสินค้า** เก็บใน Supabase Storage bucket `product-images` แล้วเก็บ public URL ไว้ในคอลัมน์ `images` (jsonb array) — ไม่เก็บ base64

---

## งานที่ยังเหลือ (อนาคต)

- [ ] ตะกร้า/checkout ยังเป็น demo ฝั่ง client — ยังไม่บันทึกออเดอร์จริงลง `orders`
- [ ] `index.html` / `admin.html` เป็นไฟล์เดียวขนาดใหญ่ (2,000–4,000 บรรทัด) — ถ้าโตขึ้นมากค่อยพิจารณาแยก CSS/JS ออกไฟล์

---

© 2026 Anibound — A bond with the wild
