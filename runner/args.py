import configargparse


def parse_args() -> tuple[configargparse.Namespace, list[str]]:
    parser = configargparse.get_arg_parser()

    parser.add_argument(
        '--log-level',
        env_var='LOG_LEVEL',
        default='INFO',
        type=str.upper,
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
    )

    parser.add_argument('--port', env_var='PORT', type=int, default=27015, help='The port to use for the server.')

    parser.add_argument(
        '--max-players', env_var='MAX_PLAYERS', type=int, default=32, help='The maximum number of players.'
    )

    parser.add_argument(
        '--tickrate', env_var='TICKRATE', type=int, default=100, help='The tickrate to use for the server.'
    )

    parser.add_argument(
        '--server-name',
        env_var='SERVER_NAME',
        default='L4D2',
        help='The name of the server. Can contain env variables in curly braces.',
    )

    parser.add_argument(
        '--server-cfg-mode',
        env_var='SERVER_CFG_MODE',
        default='replace',
        choices=['replace', 'append'],
        help='Whether to replace the server.cfg file with the one in the custom files, or append its content.',
    )

    parser.add_argument(
        '--auto-load-cfg',
        env_var='AUTO_LOAD_CFG',
        type=str,
        help='Config to load automatically when connecting to the server.',
    )

    parser.add_argument(
        '--auto-load-mode',
        env_var='AUTO_LOAD_MODE',
        default='none',
        choices=['none', 'connection', 'lobby'],
        help="none: don't load any cfg automatically, "
        'connection: load the cfg when a player connects to the server, '
        'lobby: load it a match is started from the lobby.',
    )

    parser.add_argument(
        '--matchmodes-cfgs',
        env_var='MATCHMODES_CFGS',
        type=str,
        nargs='+',
        help='List of configs from cfg/cfgogl to use when generating matchmodes.txt. '
        'If not specified, all configs will be used.',
    )

    parser.add_argument(
        '--exclude-matchmodes-cfgs',
        env_var='EXCLUDE_MATCHMODES_CFGS',
        type=str,
        nargs='+',
        help='List of configs from cfg/cfgogl to exclude when generating matchmodes.txt. '
        'If not specified, no configs will be excluded.',
    )

    parser.add_argument(
        '--metamod-version',
        env_var='METAMOD_VERSION',
        type=str,
        default='2.0',
        help='The major metamod version to use.',
    )

    parser.add_argument(
        '--sourcemod-version',
        env_var='SOURCEMOD_VERSION',
        type=str,
        default='1.12',
        help='The major sourcemod version to use.',
    )

    parser.add_argument(
        '--auto-update',
        env_var='AUTO_UPDATE',
        type=int,
        default=1,
        help='Whether to auto update the server on startup.',
    )

    parser.add_argument(
        '--rcon-password', env_var='RCON_PASSWORD', type=str, default='', help='The password of the rcon server.'
    )

    parser.add_argument(
        '--steam-group', env_var='STEAM_GROUP', type=str, nargs='+', default='', help='The steam group of the server.'
    )

    parser.add_argument(
        '--sourcebans-id', env_var='SOURCEBANS_ID', type=int, default=1, help='The ID of the SourceBans server to use.'
    )

    parser.add_argument('--tv-enable', env_var='TV_ENABLE', type=int, default=0, help='Whether to enable the tv.')

    parser.add_argument('--tv-name', env_var='TV_NAME', type=str, default='SourceTV', help='The name of the tv.')

    parser.add_argument(
        '--demos-api-endpoint',
        env_var='DEMOS_API_ENDPOINT',
        type=str,
        default='localhost',
        help='The endpoint of the demos api.',
    )

    parser.add_argument(
        '--demos-api-token',
        env_var='DEMOS_API_TOKEN',
        type=str,
        default='api_token',
        help='The token of the demos api.',
    )

    parser.add_argument(
        '--sb-host', env_var='SB_HOST', type=str, default='localhost', help='The host of the sourcebans database.'
    )

    parser.add_argument(
        '--sb-database',
        env_var='SB_DATABASE',
        type=str,
        default='sourcebans',
        help='The database of the sourcebans database.',
    )

    parser.add_argument(
        '--sb-user', env_var='SB_USER', type=str, default='user', help='The user of the sourcebans database.'
    )

    parser.add_argument(
        '--sb-pass', env_var='SB_PASS', type=str, default='pass', help='The password of the sourcebans database.'
    )

    parser.add_argument(
        '--sb-port', env_var='SB_PORT', type=int, default=3306, help='The port of the sourcebans database.'
    )

    parser.add_argument('--sb-server-id', env_var='SB_SERVER_ID', type=int, default=1, help="The sourcebans server id.")

    parser.add_argument(
        '--sb-website', env_var='SB_WEBSITE', type=str, default='http://yourwebsite.com', help="The sourcebans website."
    )

    parser.add_argument(
        '--api-allowed-origins',
        env_var='API_ALLOWED_ORIGINS',
        nargs='+',
        type=str,
        default=['*'],
        help='The allowed origins for the API.',
    )

    parser.add_argument('--update-maps', env_var='UPDATE_MAPS', type=bool, default=True, help='Whether to update maps.')

    parser.add_argument(
        '--except-maps',
        env_var='EXCEPT_MAPS',
        nargs='+',
        type=str,
        default=[],
        help='Maps to exclude from syncing with l4d2center.',
    )

    args, extra = parser.parse_known_args()

    if args.auto_load_mode not in (None, 'none') and args.auto_load_cfg is None:
        parser.error(f'--auto-load-cfg is required when --auto-load-mode is not "none".')

    return args, extra
