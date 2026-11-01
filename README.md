# モグラ叩き 60秒チャレンジ

スマホで遊べる、1回60秒のモグラ叩きゲームです。HTMLファイル1つだけで動き、インストールは要りません。

## ファイル構成

| ファイル | 内容 |
|---|---|
| `index.html` | ゲーム本体（HTML・CSS・JavaScript） |
| `config.js` | まるおゲーム共通：ランキングサーバーの接続情報 |
| `maruo-opening.js` | まるおゲーム共通オープニング（配布物・改変禁止） |
| `maruo-ranking.js` | まるおゲーム共通ランキング（配布物・改変禁止） |
| `icon.svg` | アイコンの元データ（`index.html` に埋め込み済み） |

## 遊び方

`index.html` をブラウザで開くと、すぐに遊べます。GitHub Pages で公開すれば、スマホからURLを開くだけで遊べます。

| キャラクター | 内容 |
|---|---|
| 🟤 モグラ | 1回叩くと +10点 |
| 🟡 金モグラ | +50点。出ている時間が短い |
| 👨‍👦‍👦 3兄弟モグラ | 1回叩くごとに1匹ずつ引っ込む。+10 → +20 → +30 で、3匹とも叩くと合計 +60点（コンボ倍率はかからない） |
| 👶 赤ちゃんモグラ | ピンクのずきんで寝ている。**叩いちゃダメ**。叩くと −30点で、コンボも切れる |

- **コンボ**：5回続けて当てるごとに得点の倍率が上がる（最大3倍）
- **ミッション**：ランダムに出るお題を時間内にクリアすると、ボーナス点がもらえる
- **ラストラッシュ**：ミッションを4つクリアすると、残り10秒でラッシュが始まる（モグラが一気に増え、得点は1.5倍）
- **ランク称号**：スコアに応じて8段階の称号がもらえる
- **ベストスコア**：遊んだ端末のブラウザに保存される
- **全体ランキング**：まるおゲーム共通ランキングで、全員の自己ベストで順位を競える。オフライン中の記録は端末に保留し、あとで自動送信

## まるおゲーム共通キット

オープニングとランキングは、まるおゲーム共通キットを使っています（「まるおゲーム共通ランキング 組み込み仕様書」に準拠）。

| 項目 | 内容 |
|---|---|
| オープニング | 起動すると「まるおゲーム」のロゴが流れ、そのあとタイトル画面が出る（タップでスキップ可） |
| ランキング | 全ゲーム共通の Supabase に保存。gameId は **`mogura-tataki`**（公開後は変えない） |
| 記録 | ゲーム終了時に `ranking.reportScore(点数)` を呼ぶだけ。自己ベストの判定・保存・送信はキットが行う |
| 表示 | タイトルと結果画面に「自己ベスト ○ ／ 全体 ○位」と通信状況。「🏆 ランキング」でキット標準の画面を開く |
| 入力 | オープニング中とランキング表示中は、ゲームの入力を受け付けない |
| 旧データ | 以前の版で端末に保存した自己ベスト・ニックネームは、初回起動時に自動で引き継ぐ |

- `maruo-opening.js`・`maruo-ranking.js` は配布物のまま使います。**改変しないでください。**
- `config.js` は全ゲーム共通のものをそのまま使います（`window.MARUO_CONFIG`）。GitHubに上げたあとは、中身が入っているかを確かめてください。
- Supabase 側の準備は済んでいます（`maruo_submit_score`・`maruo_get_leaderboard`・`maruo_get_rank`）。このゲームのためにSQLを実行する必要はありません。
- ランキング画面の色は、`index.html` の CSS 変数（`--maruo-accent` など）でゲームに合わせています。

### 以前の版の後片付け（任意）

以前の版で作った `mogura_` で始まるテーブルと関数は、もう使っていません。消したいときは、Supabase の SQL Editor で次を実行してください。共通キットや他のゲームのテーブルには影響しません。

```sql
drop function if exists public.mogura_submit_score(uuid, text, text, integer);
drop function if exists public.mogura_get_leaderboard(integer);
drop function if exists public.mogura_get_rank(integer);
drop function if exists public.mogura_clean_name(text);
drop table if exists public.mogura_scores;
drop table if exists public.mogura_scores_old_v1;
```

## バランス調整

`index.html` の `<script>` の最初にある `CONFIG` の数字を変えると調整できます。

| 項目 | 内容 |
|---|---|
| `duration` | プレイ時間（秒） |
| `spawnInterval` / `upTime` / `maxActive` | モグラが出る間隔・出ている時間・同時に出る最大数（開始時 → 終了時） |
| `rates` | 金モグラ・赤ちゃんモグラ・3兄弟モグラの出やすさ |
| `points` | それぞれの点数 |
| `comboStep` / `comboMaxMult` | コンボ倍率が上がる間隔と上限 |
| `rushNeed` / `rushSeconds` / `rush` | ラッシュに必要なミッション数、始まるタイミング、ラッシュ中の設定 |
| `ranks` | 称号と、もらえる点数 |

ミッションの種類は、`MISSIONS` の配列で追加・変更できます。

## 技術メモ

- 外部ライブラリは使っていません（HTML・CSS・JavaScriptのみ。フォントは Google Fonts から読み込み）
- キャラクターはすべて SVG で描いたオリジナルです
- 効果音は Web Audio API で、その場で生成しています
