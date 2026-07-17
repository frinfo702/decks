import { readFile, readdir, stat, writeFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'

const source = new URL('../dist/index.html', import.meta.url)
const destination = new URL('../spatial-relation-search.html', import.meta.url)
const assetsDirectory = new URL('../assets/', import.meta.url)

const mimeTypes = {
  '.gif': 'image/gif',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
}

let html = await readFile(source, 'utf8')

for (const name of await readdir(assetsDirectory)) {
  const extension = name.slice(name.lastIndexOf('.')).toLowerCase()
  const mime = mimeTypes[extension]
  if (!mime)
    continue

  const data = await readFile(new URL(name, assetsDirectory))
  const dataUri = `data:${mime};base64,${data.toString('base64')}`

  html = html.replaceAll(`./assets/${name}`, dataUri)
  html = html.replaceAll(`/assets/${name}`, dataUri)
}

await writeFile(destination, html)

const { size } = await stat(destination)
console.log(`Created ${fileURLToPath(destination)} (${(size / 1024 / 1024).toFixed(1)} MB)`)
