# Anibound 縁

> ของดีที่เหมาะกับเจ้าตัวเล็กของคุณ —
> ร้านอาหารและของใช้สำหรับน้องหมา น้องแมว และคนเลี้ยง
> ในแนวคิด zen-minimal สไตล์ญี่ปุ่น

**Anibound** มาจาก *Ani(mal)* + **縁 (en)** — คันจิที่หมายถึง "สายใย / พรหมลิขิต" สื่อถึงความเชื่อว่าการได้พบกับน้องสักตัวคือพรหมลิขิตอย่างหนึ่ง

---

## 📁 โครงสร้างโปรเจกต์

```
anibound/
├── index.html          ← redirect → anibound.html
├── anibound.html       ← หน้าร้านหลัก (homepage)
├── login.html          ← เข้าสู่ระบบ
├── signup.html         ← สมัครสมาชิก
├── auth.css            ← สไตล์ร่วมของหน้า auth
├── image-slot.js       ← Web component สำหรับลากรูปวาง
├── tweaks-panel.jsx    ← Live theme tweaker (พาเลท · ฟอนต์)
└── README.md
```

---

## ✨ ฟีเจอร์

### Homepage (`anibound.html`)
- 🪵 **Hero**: วงกลม *enso* (円相) วาดด้วยพู่กัน ห่อรูปน้อง + คันจิประดับ 縁
- 🏷️ **4 หมวดสินค้า**: 食 อาหาร · 器 ของใช้ · 遊 ของเล่น · 服 เสื้อยืดคู่
- 🎌 **Noren divider** — รั้วลายดั้งเดิมเป็นช่องคั่นส่วน
- 🛒 **6 สินค้าเด่น** พร้อม badge, hover-to-add-to-cart, kanji watermark
- 📖 **Story section** — ปรัชญา 4 ข้อ + ตราประทับ (since 2024)
- 👕 **Matching merch** — เสื้อยืดคู่คน × น้อง
- 📰 Journal · Newsletter · Footer หลายภาษา

### Login & Signup (`login.html`, `signup.html`)
- 🪞 **Split-screen**: ฟอร์มซ้าย · enso วงใหญ่ + รูปน้องของคุณ + ตรา MEMBER ขวา
- 🔐 Social login: **LINE · Google · Apple**
- ✅ Validation จริง + แสดง error สวย
- 👁️ Password reveal toggle (SHOW / HIDE)
- 💪 Password strength meter (อ่อน → แข็งแกร่ง)
- 🐶🐱 Species toggle (犬 หมา / 猫 แมว)
- 🎉 Success state พร้อมตราประทับ 縁

### 🎛️ Tweaks Panel
ผู้ใช้ปรับ live ได้:
- **พาเลทสี**: Sage · Sunset · Stone · Matcha
- **ฟอนต์**: Shippori Mincho · Noto Serif JP · DM Serif Display
- คันจิประดับ · ขอบ noren · ความหนาเส้นพู่กัน enso

### 🖼️ Image Slots
ทุกที่ที่เป็น placeholder รูป — **ลากรูปจริงวาง** ได้เลย (บันทึกถาวรหลังรีเฟรช)

---

## 🚀 รันในเครื่อง

โปรเจกต์เป็น **static HTML** ล้วน ไม่ต้อง build:

```bash
# ใช้ Python
python3 -m http.server 8000

# หรือ Node
npx serve .

# หรือเปิดไฟล์ตรง ๆ
open index.html
```

---

## ☁️ Deploy

### Vercel (แนะนำ)
1. Import repo นี้ที่ https://vercel.com/new
2. Framework Preset: **Other**
3. Build/Output: ปล่อยว่าง
4. Deploy

### Netlify, Cloudflare Pages, GitHub Pages
ใช้ root directory เป็น output ได้เลย ไม่ต้อง config build

---

## 🎨 Design System

| Token | ค่า |
|-------|-----|
| Background | `#f0ebe0` (cream sand) |
| Ink | `#2b2820` (dark espresso) |
| Accent | `#c97a4a` (terracotta) |
| Sage | `#d8e8d0` |
| Peach | `#f5d8b8` |
| Serif | Shippori Mincho · DM Serif Display |
| Sans | Inter · Noto Sans Thai |

---

## 📝 License

© 2026 Anibound — ทำด้วยใจในกรุงเทพ ฯ · 縁を大切に
