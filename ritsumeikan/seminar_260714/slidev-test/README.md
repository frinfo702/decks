# Spatial Relation Search in 3D Scenes

`ritsumeikan/seminar_260714/goto_mini_seminar.typ` を Slidev で再構成した資料です。

## Run with Bun

```bash
cd ritsumeikan/seminar_260714/slidev-test
bun install
bun run dev
```

## Create a single HTML file

単一 HTML の生成スクリプトは `decks/scripts/` にあります。トップへ移動して、このデッキのフォルダーと出力名を指定します。

```bash
cd ../../..
./scripts/slidev-single-html.sh ritsumeikan/seminar_260714/slidev-test spatial-relation-search.html
```

生成物は `ritsumeikan/seminar_260714/slidev-test/spatial-relation-search.html` です。このファイルだけを Google Drive などで共有できます。

同じコマンドは、別の Slidev フォルダーにも使用できます。

```bash
./scripts/slidev-single-html.sh path/to/another-deck optional-output-name.html
```

## Standard build

通常の複数ファイル形式でビルドする場合は、デッキのフォルダー内で次を実行します。

```bash
bun run build
```

通常ビルドの生成先は `dist/` です。デザインは `dark-vercel.css` に分離しています。
