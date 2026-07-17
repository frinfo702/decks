import { mkdtemp, readFile, readdir, stat, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { basename, dirname, extname, isAbsolute, join, relative, resolve, sep } from 'node:path'
import { pathToFileURL } from 'node:url'

const MAX_INLINE_SIZE = 100_000_000
const CONFIG_NAMES = [
  'vite.config.js',
  'vite.config.mjs',
  'vite.config.mts',
  'vite.config.ts',
]

const mimeTypes: Record<string, string> = {
  '.gif': 'image/gif',
  '.jpeg': 'image/jpeg',
  '.jpg': 'image/jpeg',
  '.mp4': 'video/mp4',
  '.otf': 'font/otf',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.webm': 'video/webm',
  '.webp': 'image/webp',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
}

function usage(): never {
  console.error(`Usage:
  ./scripts/slidev-single-html.sh <deck-directory|slides.md> [output.html]

Examples:
  ./scripts/slidev-single-html.sh ritsumeikan/seminar_260714/slidev-test
  ./scripts/slidev-single-html.sh ritsumeikan/seminar_260714/slidev-test spatial-relation-search.html`)
  process.exit(1)
}

async function pathExists(path: string) {
  return stat(path).then(() => true).catch(() => false)
}

async function listEmbeddableFiles(directory: string, outputPath: string) {
  const files: string[] = []

  async function visit(current: string) {
    for (const entry of await readdir(current, { withFileTypes: true })) {
      if (entry.name === '.git' || entry.name === 'dist' || entry.name === 'node_modules')
        continue

      const path = join(current, entry.name)
      if (entry.isDirectory()) {
        await visit(path)
        continue
      }

      if (path === outputPath)
        continue
      if (mimeTypes[extname(entry.name).toLowerCase()])
        files.push(path)
    }
  }

  await visit(directory)
  return files
}

async function hasSingleFilePlugin(deckDirectory: string) {
  for (const name of CONFIG_NAMES) {
    const path = join(deckDirectory, name)
    if (!await pathExists(path))
      continue
    const source = await readFile(path, 'utf8')
    if (source.includes('vite-plugin-singlefile') || source.includes('viteSingleFile'))
      return true
  }
  return false
}

function escapeRegExp(value: string) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

function createSingleFilePlugin(viteMajor: number) {
  return {
    name: 'decks:single-file',
    enforce: 'post',
    config(config: Record<string, any>) {
      config.base = './'
      config.build ??= {}
      config.build.assetsDir = ''
      config.build.assetsInlineLimit = () => true
      config.build.chunkSizeWarningLimit = MAX_INLINE_SIZE
      config.build.cssCodeSplit = false
      config.build.rollupOptions ??= {}
      config.build.rollupOptions.output ??= {}

      const output = config.build.rollupOptions.output
      const outputs = Array.isArray(output) ? output : [output]
      for (const item of outputs) {
        delete item.manualChunks
        if (viteMajor >= 8)
          item.codeSplitting = false
        else
          item.inlineDynamicImports = true
      }
    },
    generateBundle(_options: unknown, bundle: Record<string, any>) {
      const htmlFiles = Object.keys(bundle).filter(name => /\.html?$/.test(name))
      const jsFiles = Object.keys(bundle).filter(name => /\.[mc]?js$/.test(name))
      const cssFiles = Object.keys(bundle).filter(name => /\.css$/.test(name))

      for (const htmlName of htmlFiles) {
        const htmlAsset = bundle[htmlName]
        let html = String(htmlAsset.source)

        for (const filename of jsFiles) {
          const chunk = bundle[filename]
          if (typeof chunk.code !== 'string')
            continue

          const escapedFilename = escapeRegExp(filename)
          const scriptPattern = new RegExp(`<script([^>]*?) src="(?:[^"]*?/)?${escapedFilename}"([^>]*)></script>`)
          const code = chunk.code
            .replace(/"?__VITE_PRELOAD__"?/g, 'void 0')
            .replace(/<(\/script>|!--)/g, '\\x3C$1')

          html = html.replace(scriptPattern, (_match, before, after) =>
            `<script${before}${after}>${code.trim()}</script>`)
          delete bundle[filename]
        }

        for (const filename of cssFiles) {
          const asset = bundle[filename]
          const escapedFilename = escapeRegExp(filename)
          const stylePattern = new RegExp(`<link([^>]*?) href="(?:[^"]*?/)?${escapedFilename}"([^>]*)>`)
          const css = String(asset.source).replace('@charset "UTF-8";', '').trim()

          html = html.replace(stylePattern, (_match, before, after) =>
            `<style${before}${after}>${css}</style>`)
          delete bundle[filename]
        }

        htmlAsset.source = html.replace(
          /(<script type="module" crossorigin>\s*)\(function(?: polyfill)?\(\)\s*\{[\s\S]*?\}\)\(\);/,
          '<script type="module">',
        )
      }
    },
  }
}

function resolveDeckDependency(specifier: string, deckDirectory: string) {
  try {
    return Bun.resolveSync(specifier, deckDirectory)
  }
  catch {
    throw new Error(
      `Missing ${specifier} in ${deckDirectory}. Run "bun install" in the deck directory first.`,
    )
  }
}

async function loadSlidevBuild(cliEntry: string) {
  const cliDist = dirname(cliEntry)
  const buildModule = (await readdir(cliDist)).find(name => /^build-.*\.mjs$/.test(name))

  if (!buildModule)
    throw new Error('Could not locate the Slidev build module.')

  return import(pathToFileURL(join(cliDist, buildModule)).href) as Promise<{
    build: (options: unknown, viteConfig: unknown, args: unknown) => Promise<void>
  }>
}

const input = process.argv[2]
if (!input)
  usage()

const inputPath = resolve(process.cwd(), input)
if (!await pathExists(inputPath))
  throw new Error(`Deck path does not exist: ${inputPath}`)

const inputStats = await stat(inputPath)
const entry = inputStats.isDirectory() ? join(inputPath, 'slides.md') : inputPath
if (!await pathExists(entry))
  throw new Error(`Slidev entry does not exist: ${entry}`)

const deckDirectory = dirname(entry)
const requestedOutput = process.argv[3] || `${basename(deckDirectory)}.html`
const outputPath = isAbsolute(requestedOutput)
  ? requestedOutput
  : resolve(deckDirectory, requestedOutput)
const temporaryOutput = await mkdtemp(join(tmpdir(), 'slidev-single-html-'))

const slidevEntry = resolveDeckDependency('@slidev/cli', deckDirectory)
const { resolveOptions } = await import(pathToFileURL(slidevEntry).href)

const options = await resolveOptions({
  entry,
  routerMode: 'hash',
}, 'build')

const plugins: unknown[] = []
if (!await hasSingleFilePlugin(deckDirectory)) {
  const viteEntry = resolveDeckDependency('vite', deckDirectory)
  const { version } = await import(pathToFileURL(viteEntry).href)
  plugins.push(createSingleFilePlugin(Number.parseInt(version.split('.')[0], 10)))
}

const { build } = await loadSlidevBuild(slidevEntry)
await build(options, {
  base: './',
  plugins,
  build: {
    outDir: temporaryOutput,
    assetsInlineLimit: MAX_INLINE_SIZE,
    cssCodeSplit: false,
    sourcemap: false,
  },
}, {
  entry,
  dark: false,
  timeout: 30_000,
})

let html = await readFile(join(temporaryOutput, 'index.html'), 'utf8')

for (const assetPath of await listEmbeddableFiles(deckDirectory, outputPath)) {
  const extension = extname(assetPath).toLowerCase()
  const mime = mimeTypes[extension]
  const deckRelativePath = relative(deckDirectory, assetPath).split(sep).join('/')
  const encodedPath = deckRelativePath.split('/').map(encodeURIComponent).join('/')
  const data = await readFile(assetPath)
  const dataUri = `data:${mime};base64,${data.toString('base64')}`

  for (const path of [deckRelativePath, encodedPath]) {
    html = html.replaceAll(`./${path}`, dataUri)
    html = html.replaceAll(`/${path}`, dataUri)
  }
}

await writeFile(outputPath, html)

const { size } = await stat(outputPath)
console.log(`Created ${outputPath} (${(size / 1024 / 1024).toFixed(1)} MB)`)
