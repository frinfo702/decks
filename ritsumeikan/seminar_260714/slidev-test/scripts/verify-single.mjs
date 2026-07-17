import { copyFile, mkdtemp } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'
import { chromium } from 'playwright-chromium'

const source = new URL('../spatial-relation-search.html', import.meta.url)
const isolatedDirectory = await mkdtemp(join(tmpdir(), 'ritsumeikan-slidev-'))
const isolatedFile = join(isolatedDirectory, 'deck.html')
await copyFile(source, isolatedFile)

const browser = await chromium.launch({ headless: true })
const page = await browser.newPage({ viewport: { width: 980, height: 552 } })
const pageErrors = []
const failedRequests = []

page.on('pageerror', error => pageErrors.push(error.message))
page.on('requestfailed', request => failedRequests.push(request.url()))

await page.goto(pathToFileURL(isolatedFile).href, { waitUntil: 'load' })
await page.waitForTimeout(900)

const coverVisible = await page.getByText('Spatial Relation Search', { exact: false }).first().isVisible()

for (let step = 0; step < 80; step += 1) {
  await page.keyboard.press('ArrowRight')
  await page.waitForTimeout(25)
}

const finalVisible = await page.getByText('Progress and remaining work', { exact: false }).first().isVisible().catch(() => false)
const brokenImages = await page.locator('img').evaluateAll(images => images
  .filter(image => !image.complete || image.naturalWidth === 0)
  .map(image => image.getAttribute('alt') || image.getAttribute('src')))
await browser.close()

const unexpectedPageErrors = pageErrors.filter(
  message => !message.includes('Wake Lock permission request denied'),
)
const unexpectedFailedRequests = [...new Set(failedRequests.filter(
  url => !url.includes('/data:image/'),
))]

if (!coverVisible)
  throw new Error('The cover slide did not render from the isolated HTML file.')
if (!finalVisible)
  throw new Error('Keyboard navigation did not reach the final slide.')
if (brokenImages.length)
  throw new Error(`Broken images: ${brokenImages.join(' | ')}`)
if (unexpectedPageErrors.length)
  throw new Error(`Browser errors: ${unexpectedPageErrors.join(' | ')}`)
if (unexpectedFailedRequests.length)
  throw new Error(`Failed requests: ${unexpectedFailedRequests.join(' | ')}`)

console.log('Standalone HTML verified: cover, navigation, and embedded assets are working.')
