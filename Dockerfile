FROM steamcmd/steamcmd:ubuntu-22

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && apt-get update -y && \
    apt-get install -y git pipx lib32z1 curl unzip ca-certificates libicu70 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m srcds

USER srcds

ENV HOME=/home/srcds

WORKDIR $HOME

# avoid steamcmd's "Missing configuration" and "Invalid platform" errors
RUN curl -sSL https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_3.4.0/DepotDownloader-linux-x64.zip -o /tmp/depotdownloader.zip && \
    unzip -q /tmp/depotdownloader.zip -d /tmp/depotdownloader && \
    chmod +x /tmp/depotdownloader/DepotDownloader && \
    /tmp/depotdownloader/DepotDownloader -app 222860 -os linux -dir $HOME/server -max-downloads 4 && \
    rm -rf /tmp/depotdownloader /tmp/depotdownloader.zip

# make steamcmd recognize the installation
RUN mkdir -p $HOME/server/steamapps
COPY --chown=srcds:srcds appmanifest_222860.acf $HOME/server/steamapps/appmanifest_222860.acf

# prevent crash on first startup
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
