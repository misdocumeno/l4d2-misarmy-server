declare module 'source-server-query' {
    export interface SourcePlayer {
        name: string
        score: number
        duration: number
    }

    export function players(host: string, port: number, timeout?: number): Promise<SourcePlayer[]>
}
