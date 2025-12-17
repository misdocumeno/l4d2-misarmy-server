FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY src src

COPY tsconfig.json .

COPY esbuild.config.js .

RUN npm run build

FROM steamcmd/steamcmd:ubuntu-22 AS download

# TODO: use DepotDownloader
RUN --mount=type=cache,target=/root/Steam \
    steamcmd +force_install_dir /server +@sSteamCmdForcePlatformType windows +login anonymous +app_update 222860 validate +quit && \
    steamcmd +force_install_dir /server +@sSteamCmdForcePlatformType linux +login anonymous +app_update 222860 validate +quit

FROM steamcmd/steamcmd:ubuntu-22 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && apt-get update -y && \
    apt-get install -y curl git pipx lib32z1 p7zip-full && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m srcds

USER srcds

ENV HOME=/home/srcds

WORKDIR $HOME

COPY --from=download --chown=srcds:srcds /server $HOME/server

RUN mkdir -p $HOME/.steam/sdk32 && \
    cp $HOME/server/bin/steamclient.so $HOME/.steam/sdk32/steamclient.so

ENV PATH="$PATH:$HOME/.local/bin"

RUN pipx install poetry==1.8.3

RUN git clone https://github.com/sirPlease/L4D2-Competitive-Rework repo/

ENV PYTHONUNBUFFERED=1

COPY pyproject.toml poetry.lock* ./

RUN poetry install --no-interaction --no-root

COPY scripts scripts

COPY package*.json ./

RUN npm ci --only=production

ARG CUSTOM_MAPS=true

ENV BUILD_HAS_CUSTOM_MAPS=${CUSTOM_MAPS}

RUN if [ "$CUSTOM_MAPS" = "true" ]; then poetry run python scripts/download_maps.py; fi

COPY --from=builder /app/dist dist

COPY --chmod=+x --chown=srcds:srcds docker-entrypoint.sh .

COPY --chown=srcds:srcds cfg cfg

COPY --chown=srcds:srcds addons addons

ENTRYPOINT [ "./docker-entrypoint.sh" ]
