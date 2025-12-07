import os
import sys
import signal
import psutil
import subprocess
from .update.server import update_server
from runner.args import parse_args
from runner.logger import logger
import runner.state


def start_server() -> subprocess.Popen:
    args, srcds_args = parse_args()

    runner.state.status = runner.state.ServerStatus.UPDATING
    update_server()

    runner.state.status = runner.state.ServerStatus.STARTING
    logger.info(f'starting server, port: {args.port}')

    print(srcds_args)

    return subprocess.Popen(
        [
            f'{os.getcwd()}/server/srcds_run',
            '-tickrate',
            str(args.tickrate),
            '-port',
            str(args.port),
            '-maxplayers',
            str(args.max_players),
            '+sv_clockcorrection_msecs',
            '25',
            '-timeout',
            '10',
            *(('+map', 'c2m1_highway') if '+map' not in srcds_args else ()),
            *(('+tv_enable', '1') if args.tv_enable else ()),
            *(('+tv_name', args.tv_name) if args.tv_name else ()),
            *srcds_args,
        ],
        stdin=sys.stdin,
        stdout=sys.stdout,
        stderr=sys.stderr,
        preexec_fn=os.setsid,
    )


def stop_server(process: subprocess.Popen):
    if process.poll() is None:
        pgid = os.getpgid(process.pid)
        os.killpg(pgid, signal.SIGTERM)
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(pgid, signal.SIGKILL)
    reap_children()


def reap_children():
    for child in psutil.Process(os.getpid()).children(recursive=True):
        try:
            child.terminate()
            child.wait(timeout=5)
            logger.debug(f"Terminated and reaped child {child.pid}")
        except psutil.TimeoutExpired:
            logger.debug(f"Timeout waiting for child {child.pid}, trying to kill")
            try:
                child.kill()
                child.wait(timeout=5)
                logger.debug(f"Killed and reaped child {child.pid}")
            except Exception as e:
                logger.error(f"Failed to kill child {child.pid}: {e}")
        except psutil.NoSuchProcess:
            logger.debug(f"Child {child.pid} already gone")
