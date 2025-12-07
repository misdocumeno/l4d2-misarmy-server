FROM steamcmd/steamcmd:ubuntu-22

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && apt-get update -y && \
    apt-get install -y git pipx lib32z1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m srcds

USER srcds

ENV HOME=/home/srcds

WORKDIR $HOME

RUN steamcmd +force_install_dir $HOME/server +@sSteamCmdForcePlatformType windows +login anonymous +app_update 222860 validate +quit && \
    steamcmd +force_install_dir $HOME/server +@sSteamCmdForcePlatformType linux +login anonymous +app_update 222860 validate +quit

RUN mkdir -p $HOME/.steam/sdk32 && \
    cp $HOME/server/bin/steamclient.so $HOME/.steam/sdk32/steamclient.so

ENV PATH="$PATH:$HOME/.local/bin"

RUN pipx install poetry==1.8.3

RUN git clone https://github.com/sirPlease/L4D2-Competitive-Rework repo/

COPY pyproject.toml poetry.lock* ./

RUN poetry install --no-interaction --no-root

ENV PYTHONUNBUFFERED=1

COPY custom_maps.py ./

ARG CUSTOM_MAPS=true

ENV BUILD_HAS_CUSTOM_MAPS=${CUSTOM_MAPS}

RUN if [ "$CUSTOM_MAPS" = "true" ]; then poetry run python custom_maps.py; fi

COPY runner runner

COPY --chown=srcds:srcds cfg cfg

COPY --chown=srcds:srcds addons addons

ENTRYPOINT [ "poetry", "run", "python", "-m", "runner" ]
