-- =====================================================================
-- モグラ叩き 60秒チャレンジ：全体ランキング用のテーブルと関数
--
-- 使い方：ブラウザの自動翻訳をオフにしてから、Supabase の「SQL Editor」に
-- このファイルを全文貼り付けて「Run」してください。
-- 「Success. No rows returned」と出れば成功です。何度実行しても大丈夫です。
--
-- 1人1行で自己ベストを保存します。公開用キー（Publishable key / anon key）から
-- 呼べるのは submit_score / get_leaderboard / get_rank の3関数だけで、
-- テーブルへの直接アクセスはできません。
-- =====================================================================

-- 0) 以前の版（1プレイ1行の scores テーブル）があれば、消さずに scores_old_v1 へ退避する
do $$
begin
  if exists (
       select 1 from information_schema.tables
       where table_schema = 'public' and table_name = 'scores')
     and not exists (
       select 1 from information_schema.columns
       where table_schema = 'public' and table_name = 'scores' and column_name = 'player_id')
  then
    drop function if exists public.submit_score(text, integer, integer, integer);
    alter table public.scores rename to scores_old_v1;
    revoke all on public.scores_old_v1 from anon, authenticated;
  end if;
end $$;

-- 1) テーブル ----------------------------------------------------------
create table if not exists public.scores (
  player_id   uuid        primary key,                       -- 書き込み用の秘密ID（ランキングには出さない）
  pub_id      text        not null unique check (pub_id ~ '^[0-9a-f]{12}$'),  -- 表示用の公開ID
  name        text        not null check (char_length(name) between 1 and 12),
  best        integer     not null check (best between 0 and 20000),
  updated_at  timestamptz not null default now()             -- 自己ベストを更新した時刻
);

create index if not exists scores_best_idx on public.scores (best desc, updated_at asc);

-- 2) アクセス制限：テーブルへの直接アクセスは禁止 -----------------------
alter table public.scores enable row level security;
revoke all on public.scores from anon, authenticated;
-- （ポリシーを1つも作らないので、公開用キーからは読み書きとも不可。下の関数だけが触れる）

-- 3) 名前の整形：制御文字と < > を取り除き、前後の空白を削る ---------------
create or replace function public._clean_name(p_name text)
returns text
language sql
immutable
as $$
  select btrim(regexp_replace(coalesce(p_name, ''), '[[:cntrl:]<>]', '', 'g'));
$$;

-- 4) 記録の送信 --------------------------------------------------------
--   未登録なら追加。登録済みなら名前は毎回更新し、記録は今より高いときだけ更新
--   （更新時刻もそのときだけ変わる）。
create or replace function public.submit_score(
  p_player_id uuid,
  p_pub_id    text,
  p_name      text,
  p_best      integer
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := public._clean_name(p_name);
begin
  if p_player_id is null then
    raise exception 'player_id がありません' using errcode = '22023';
  end if;
  if p_pub_id is null or p_pub_id !~ '^[0-9a-f]{12}$' then
    raise exception '公開IDの形式が正しくありません' using errcode = '22023';
  end if;
  if char_length(v_name) < 1 or char_length(v_name) > 12 then
    raise exception 'ニックネームは1〜12文字にしてください' using errcode = '22023';
  end if;
  if p_best is null or p_best < 0 or p_best > 20000 then
    raise exception '記録が正しくありません' using errcode = '22023';
  end if;

  insert into public.scores as s (player_id, pub_id, name, best, updated_at)
  values (p_player_id, p_pub_id, v_name, p_best, now())
  on conflict (player_id) do update
    set name       = excluded.name,
        best       = greatest(s.best, excluded.best),
        updated_at = case when excluded.best > s.best then now() else s.updated_at end;
end;
$$;

-- 5) 上位の取得：記録の高い順、同点は先に記録した人が上 ---------------------
create or replace function public.get_leaderboard(p_limit integer default 50)
returns table (pub_id text, name text, best integer, updated_at timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select s.pub_id, s.name, s.best, s.updated_at
  from public.scores s
  order by s.best desc, s.updated_at asc
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

-- 6) 順位の取得：その記録より高い人数＋1 ---------------------------------
create or replace function public.get_rank(p_best integer)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select (count(*) + 1)::integer from public.scores s where s.best > coalesce(p_best, 0);
$$;

-- 7) 実行権限：3関数を anon・authenticated にだけ与える --------------------
revoke all on function public._clean_name(text) from public, anon, authenticated;
revoke all on function public.submit_score(uuid, text, text, integer) from public;
revoke all on function public.get_leaderboard(integer) from public;
revoke all on function public.get_rank(integer) from public;
grant execute on function public.submit_score(uuid, text, text, integer) to anon, authenticated;
grant execute on function public.get_leaderboard(integer) to anon, authenticated;
grant execute on function public.get_rank(integer) to anon, authenticated;
