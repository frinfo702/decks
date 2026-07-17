import { defineConfig, type Plugin } from 'vite'
import { viteSingleFile } from 'vite-plugin-singlefile'

function removeManualChunks(): Plugin {
  return {
    name: 'slidev-single-file-compat',
    enforce: 'post',
    config(config) {
      const output = config.build?.rollupOptions?.output
      const outputs = Array.isArray(output) ? output : output ? [output] : []
      for (const item of outputs)
        delete item.manualChunks
    },
  }
}

export default defineConfig({
  base: './',
  build: {
    assetsInlineLimit: 100_000_000,
    cssCodeSplit: false,
    sourcemap: false,
  },
  plugins: [
    viteSingleFile({ removeViteModuleLoader: true }),
    removeManualChunks(),
  ],
})
