// ランキングサーバー（Supabase）の接続情報
//   Supabase の「Project Settings → API Keys」から Project URL と公開用キー（Publishable key）をコピーして入れてください。
//   空のままだとランキングは無効になり、自己ベストだけが端末に記録されます。
//   ※ 入れるのは公開用キー（sb_publishable_… または anon public）だけ。
//     秘密のキー（sb_secret_…、service_role）は絶対に入れないでください。
window.MOGURA_CONFIG = {
  SUPABASE_URL: 'https://ghhvpkfngtgmwzuvjfda.supabase.co'
  SUPABASE_ANON_KEY: 'sb_publishable_htKvFnnY-3Tcc4eEEQKwEg_zMju3PZK'
