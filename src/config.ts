import { z } from 'zod'
import yargs from 'yargs'
import { hideBin } from 'yargs/helpers'

const booleanLike = z.union([z.boolean(), z.string(), z.number()]).transform((val) => {
    if (typeof val === 'boolean') return val
    if (typeof val === 'number') return val !== 0
    return ['true', '1', 'yes', 'on'].includes(val.toLowerCase())
})

const numberLike = z.union([z.number(), z.string()]).transform((val) => (typeof val === 'number' ? val : Number(val)))

const stringList = z
    .union([z.string(), z.array(z.string())])
    .optional()
    .default('')
    .transform((v) => (Array.isArray(v) ? v : v ? v.split(',') : []))

const configSchema = z.object({
    LOG_LEVEL: z.enum(['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']).default('INFO').describe('Log level'),

    PORT: numberLike.default(27015).describe('Server port'),
    MAX_PLAYERS: numberLike.default(32).describe('Maximum players'),
    TICKRATE: numberLike.default(100).describe('Server tickrate'),
    SERVER_NAME: z.string().default('L4D2').describe('Server name'),

    SERVER_CFG_MODE: z.enum(['replace', 'append']).default('replace').describe('Server cfg mode'),

    AUTO_LOAD_CFG: z.string().optional().describe('Config to autoload'),
    AUTO_LOAD_MODE: z.enum(['none', 'connection', 'lobby']).default('none').describe('Autoload mode'),

    MATCHMODES_CFGS: stringList.describe('Matchmodes configs'),
    EXCLUDE_MATCHMODES_CFGS: stringList.describe('Excluded matchmodes'),

    METAMOD_VERSION: z.string().default('2.0').describe('Metamod version'),
    SOURCEMOD_VERSION: z.string().default('1.12').describe('Sourcemod version'),

    AUTO_UPDATE: booleanLike.default(true).describe('Auto update on startup'),

    RCON_PASSWORD: z.string().default('').describe('RCON password'),
    STEAM_GROUP: stringList.describe('Steam groups'),
    SOURCEBANS_ID: numberLike.default(1).describe('SourceBans server ID'),

    TV_ENABLE: booleanLike.default(false).describe('Enable SourceTV'),
    TV_NAME: z.string().default('SourceTV').describe('SourceTV name'),

    DEMOS_API_ENDPOINT: z.string().default('localhost').describe('Demos API endpoint'),
    DEMOS_API_TOKEN: z.string().default('api_token').describe('Demos API token'),

    SB_HOST: z.string().default('localhost'),
    SB_DATABASE: z.string().default('sourcebans'),
    SB_USER: z.string().default('user'),
    SB_PASS: z.string().default('pass'),
    SB_PORT: numberLike.default(3306),
    SB_SERVER_ID: numberLike.default(1),
    SB_WEBSITE: z.string().default('http://yourwebsite.com'),

    API_ALLOWED_ORIGINS: z
        .string()
        .default('*')
        .transform((v) => v.split(' '))
        .describe('Allowed API origins'),

    UPDATE_MAPS: booleanLike.default(true).describe('Update maps'),
    EXCEPT_MAPS: z
        .string()
        .default('')
        .transform((v) => (v ? v.split(' ') : []))
        .describe('Maps to exclude'),
})

export type Config = z.infer<typeof configSchema>

const parser = yargs(hideBin(process.argv))
    .parserConfiguration({
        'unknown-options-as-args': true,
        'populate--': true,
    })
    .env(false)
    .version(false)
    .help(true)

for (const [key, schema] of Object.entries(configSchema.shape)) {
    const cliName = key.toLowerCase().replace(/_/g, '-')

    parser.option(cliName, {
        type: 'string',
        description: schema.description,
    })
}

const argv = parser.parseSync()

const input: Record<string, unknown> = {}

for (const key of Object.keys(configSchema.shape)) {
    const cliKey = key.toLowerCase().replace(/_/g, '-')
    const camelKey = cliKey.replace(/-([a-z])/g, (_, c) => c.toUpperCase())

    const cliValue = argv[camelKey]

    if (cliValue !== undefined) {
        input[key] = cliValue
    } else if (process.env[key] !== undefined) {
        input[key] = process.env[key]
    }
}

export const config = configSchema.parse(input)
export const extraArgs = argv._ as string[]
