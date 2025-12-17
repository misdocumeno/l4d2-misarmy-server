import path from 'path'
import fs from 'node:fs/promises'
import { $ } from 'execa'
import { logger } from '../logger'

// TODO: try to make this faster, instead of re-downloading the entire repo
// TODO: wrap in a try/catch, we dont want the servers going down if github is down
export async function updateRepo() {
    logger.info('Updating repo and copying files.')

    const repoDir = path.resolve(process.cwd(), 'repo')
    await fs.mkdir(repoDir, { recursive: true })

    const $$ = $({ cwd: repoDir, stdio: 'inherit', reject: false })

    await $$`rm -rf .git/index.lock .git/refs/locks/* .git/AUTO_MERGE.lock`
    await $$`git fetch --prune --force origin`
    await $$`git reset --hard origin/master`
    await $$`git clean -fdx`
    await $$`git fsck --full`
    await $$`git reflog expire --expire=now --all`
    await $$`git gc --prune=now`
}

export async function copyRepoFiles() {
    const repoDir = path.resolve(process.cwd(), 'repo')
    const targetDir = path.resolve(process.cwd(), 'server', 'left4dead2')

    await fs.cp(repoDir, targetDir, {
        recursive: true,
        force: true,
        filter: (src) => !src.startsWith(path.join(repoDir, '.git')),
    })
}
