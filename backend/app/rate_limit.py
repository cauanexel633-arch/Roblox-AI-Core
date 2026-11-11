from collections import defaultdict, deque
from datetime import datetime, timezone
from threading import Lock
from fastapi import HTTPException

_lock = Lock()
_requests_minute = defaultdict(deque)
_requests_day = defaultdict(deque)

def check_player_limit(player_id: int, per_minute: int, per_day: int):
    now = datetime.now(timezone.utc).timestamp()
    minute_cutoff = now - 60
    day_cutoff = now - 86400
    key = str(player_id)
    with _lock:
        minute = _requests_minute[key]
        daily = _requests_day[key]
        while minute and minute[0] < minute_cutoff:
            minute.popleft()
        while daily and daily[0] < day_cutoff:
            daily.popleft()
        if len(minute) >= per_minute:
            raise HTTPException(status_code=429, detail="Limite por minuto atingido. Aguarde um pouco.")
        if len(daily) >= per_day:
            raise HTTPException(status_code=429, detail="Limite diário de criações atingido.")
        minute.append(now)
        daily.append(now)
