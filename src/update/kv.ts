import { execa } from 'execa'

// TODO: use $`poetry ...` instead
export async function generateKv() {
    console.log('Generating campaigns.cfg (Python script)...')
    try {
        await execa('poetry', ['run', 'python', 'scripts/generate_kv.py'], {
            stdio: 'inherit',
        })
    } catch (e) {
        console.error('Failed to generate KV:', e)
    }
}
