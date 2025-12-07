from enum import Enum


class ServerStatus(Enum):
    OFFLINE = 'offline'
    UPDATING = 'updating'
    STARTING = 'starting'
    ONLINE = 'online'


status: ServerStatus = ServerStatus.OFFLINE
