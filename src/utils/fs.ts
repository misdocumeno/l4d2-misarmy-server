import fs from 'node:fs/promises'

export async function exists(path: string): Promise<boolean> {
    try {
        await fs.access(path)
        return true
    } catch {
        return false
    }
}

export async function readJson<T = any>(path: string): Promise<T> {
    const content = await fs.readFile(path, 'utf-8')
    return JSON.parse(content)
}

export async function writeJson(path: string, data: any, options?: { spaces?: number }): Promise<void> {
    const spaces = options?.spaces || 0
    const content = JSON.stringify(data, null, spaces)
    await fs.writeFile(path, content, 'utf-8')
}
