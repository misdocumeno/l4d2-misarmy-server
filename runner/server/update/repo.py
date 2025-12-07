import os
import shutil


def update_repo():
    os.system(f'''
        cd {os.getcwd()}/repo
        rm -rf .git/index.lock .git/refs/locks/* .git/AUTO_MERGE.lock
        git fetch --prune --force origin
        git reset --hard origin/master
        git clean -fdx
        git fsck --full
        git reflog expire --expire=now --all
        git gc --prune=now
    ''')


def copy_repo_files():
    shutil.copytree(f'{os.getcwd()}/repo/', f'{os.getcwd()}/server/left4dead2/',
                    dirs_exist_ok=True, ignore=shutil.ignore_patterns('.git'))
