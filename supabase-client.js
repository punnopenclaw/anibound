// ─────────────────────────────────────────────────────────
//  Anibound · Supabase client
//  🔧 ใส่ค่าของคุณที่ Supabase Dashboard → Project Settings → API
// ─────────────────────────────────────────────────────────

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm'

const SUPABASE_URL      = 'https://obfvftmhyejbcbqhxnlh.supabase.co'
const SUPABASE_ANON_KEY = 'sb_publishable_P97WCpAzyayF1v7I_UmLhQ_FJryHWII'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  }
})

// ─── Auth helpers ─────────────────────────────────────────

/** เข้าสู่ระบบด้วย Google → redirect ไป auth-callback.html */
export async function signInWithGoogle() {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${window.location.origin}/auth-callback.html`,
      queryParams: { access_type: 'offline', prompt: 'consent' },
    }
  })
  if (error) throw error
}

/** สมัคร/เข้าสู่ระบบด้วย Email + Password */
export async function signInWithEmail(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
  return data
}

export async function signUpWithEmail(email, password, meta = {}) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: meta }
  })
  if (error) throw error
  return data
}

/** รีเซ็ตรหัสผ่าน */
export async function resetPassword(email) {
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/reset-password.html`
  })
  if (error) throw error
}

/** ออกจากระบบ */
export async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
  window.location.href = '/index.html'
}

/** ดึง session ปัจจุบัน */
export async function getSession() {
  const { data: { session } } = await supabase.auth.getSession()
  return session
}

/** ดึง profile ของ user */
export async function getProfile(userId) {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single()
  if (error && error.code !== 'PGRST116') throw error
  return data
}

/** สร้าง profile ครั้งแรก (หลัง Google OAuth) */
export async function upsertProfile(user) {
  const profile = {
    id:           user.id,
    display_name: user.user_metadata?.full_name ?? user.email?.split('@')[0] ?? 'Anibound Member',
    avatar_url:   user.user_metadata?.avatar_url ?? null,
    email:        user.email,
    updated_at:   new Date().toISOString(),
  }
  const { error } = await supabase.from('profiles').upsert(profile)
  if (error) throw error
  return profile
}
