from contextlib import asynccontextmanager
from uuid import uuid4
import httpx
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.security import verify_roblox_key
from app.rate_limit import check_player_limit
from app.schemas.weapon import GenerateWeaponRequest, GenerateWeaponResponse
from app.services.openrouter import generate_weapon

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield

app = FastAPI(title="Roblox AI Core", version="0.1.0", lifespan=lifespan)
# Roblox server-to-server requests do not need browser CORS. No wildcard CORS is enabled.

@app.get("/health")
async def health():
    return {"ok": True, "service": "Roblox AI Core", "version": "0.1.0"}

@app.post("/v1/weapons/generate", response_model=GenerateWeaponResponse, dependencies=[Depends(verify_roblox_key)])
async def create_weapon(data: GenerateWeaponRequest):
    check_player_limit(data.player_id, settings.max_requests_per_minute, settings.max_requests_per_day)
    request_id = str(uuid4())
    try:
        weapon, model = await generate_weapon(data.prompt)
        return GenerateWeaponResponse(ok=True, weapon=weapon, model=model, request_id=request_id)
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="A IA demorou demais para responder. Tente novamente.")
    except httpx.HTTPStatusError as exc:
        status = exc.response.status_code
        if status == 429:
            raise HTTPException(status_code=503, detail="Provedor de IA temporariamente limitado. Tente novamente mais tarde.")
        raise HTTPException(status_code=502, detail="O provedor de IA retornou um erro.")
    except (KeyError, IndexError, TypeError, ValueError) as exc:
        # Exibe apenas a mensagem de validação controlada, nunca tokens ou payloads.
        raise HTTPException(
            status_code=502,
            detail=f"Falha ao processar resposta da IA: {str(exc)[:300]}",
        )
