import re
import a2s
import uvicorn
import threading
import contextlib
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter
from slowapi.util import get_remote_address
from valve.rcon import RCON
from runner.args import parse_args
import runner.state


args, _ = parse_args()

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=args.api_allowed_origins,
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)
limiter = Limiter(key_func=get_remote_address)


@app.get('/ping')
@limiter.limit('10/second')
async def ping(request: Request):
    return {'ping': 'pong'}


server_conn = ('localhost', 27015)
password = ''


@app.get('/info')
@limiter.limit('2/second')
async def info(request: Request):
    with open('/dev/null', 'w') as null:
        with contextlib.redirect_stdout(null), contextlib.redirect_stderr(null):
            try:
                with RCON(server_conn, password) as rcon:
                    config = rcon.execute('sm_cvar l4d_ready_cfg_name', timeout=1.0)
            except:
                config = None

    if config is None:
        return {'status': runner.state.status.value}

    match = re.search(r'^\[SM\] Value of cvar "l4d_ready_cfg_name": "(.*)"$', config.text)
    config = None if match is None else match.group(1)

    info = a2s.info(server_conn, timeout=1.0, encoding="utf-8")

    return {
        'status': runner.state.status.value,
        'players': info.player_count,
        'maxPlayers': info.max_players,
        'map': info.map_name,
        'config': config,
    }


def start_api(server: tuple[str, int], rcon_password: str):
    global server_conn, password
    server_conn = server
    password = rcon_password
    threading.Thread(
        target=lambda: uvicorn.run(app, host='0.0.0.0', port=8080, log_level='warning'), daemon=True
    ).start()
