# README

## commands

```shell
typst compile <your-file>.typ
```

```shell
# watch compile
typst watch <your-file>.typ
```

You need to setup uv venv and run `uv add --dev touying` in advance.

```shell
# compile with html format
uv run touying compile <your-file>.typ --format html
```

## Slidev: create a single HTML file

各 Slidev フォルダーで依存関係をインストールしておきます。トップディレクトリへの Bun 依存関係の追加は不要です。

```shell
cd path/to/deck
bun install
cd /path/to/decks
```

任意の Slidev フォルダーを指定して、HTML、CSS、JavaScript、画像、フォント、動画を一つの HTML ファイルへまとめます。

```shell
./scripts/slidev-single-html.sh <deck-directory> [output.html]
```

例：

```shell
./scripts/slidev-single-html.sh ritsumeikan/seminar_260714/slidev-test spatial-relation-search.html
```

第1引数には `slides.md` 自体も指定できます。

```shell
./scripts/slidev-single-html.sh path/to/deck/slides.md presentation.html
```

出力名を省略した場合は、指定したフォルダー名に `.html` を付けたファイルを、そのフォルダー内に生成します。

このシェルスクリプトは、指定したデッキフォルダーの `node_modules` を使用します。`decks` のトップには `package.json`、`bun.lock`、`node_modules` を置きません。
