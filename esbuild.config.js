const esbuild = require('esbuild')

esbuild
    .build({
        entryPoints: ['src/index.ts'],
        bundle: true,
        platform: 'node',
        target: 'node22',
        packages: 'external',
        outfile: 'dist/index.js',
        sourcemap: true,
        sourcesContent: false,
    })
    .catch(() => process.exit(1))
