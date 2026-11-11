import hmac
from fastapi import Header, HTTPException
from app.config import settings

async def verify_roblox_key(x_api_key: str | None = Header(default=None)):
    if not x_api_key or not hmac.compare_digest(x_api_key, settings.roblox_ai_core_key):
        raise HTTPException(status_code=401, detail="Credencial inválida.")
