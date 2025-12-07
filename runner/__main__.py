import os
import a2s
import time
import socket
from dotenv import load_dotenv
from .args import parse_args
from .server.server import start_server, stop_server
from .logger import logger
from .api import start_api
from typing import cast
import runner.state


load_dotenv(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '.env')))


def main():
    args, _ = parse_args()
    logger.setLevel(args.log_level)

    server_conn = (socket.gethostname(), cast(int, args.port))
    start_api(server_conn, args.rcon_password)
    logger.info('REST API started.')

    empty_counter = 0
    starting = True
    players_joined = False

    server = start_server()

    # restart it after 1 minutes of being empty
    # (if players had already joined since server startup)
    while True:
        try:
            time.sleep(10)
            players = a2s.players(server_conn, timeout=3.0, encoding='utf-8')

            if starting:
                runner.state.status = runner.state.ServerStatus.ONLINE
                logger.info('Server started.')
                starting = False

            if len(players) != 0:
                players_joined = True
                empty_counter = 0
            else:
                empty_counter += 1

            logger.debug(f'{len(players)=}, {players_joined=}, {empty_counter=}')

            if players_joined and empty_counter >= 6:
                logger.info('Restarting server.')
                stop_server(server)
                empty_counter = 0
                starting = True
                players_joined = False
                server = start_server()

        except TimeoutError:
            logger.debug('RCON timeout.')
        except KeyboardInterrupt:
            # TODO: send SIGTERM to server, and wait for it to exit.
            # additionally, send SIGKILL if we get another keyboard interrupt
            logger.info('Terminating...')
            stop_server(server)
            exit(0)


if __name__ == '__main__':
    main()
