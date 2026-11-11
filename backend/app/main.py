from contextlib import asynccontextmanager
from uuid import uuid4

import httpx
from fastapi import FastAPI, Depends, HTTPException

from app.config import settings
from app.security import verify_roblox_key
from app.rate_limit import check_player_limit
from app.schemas.weapon import GenerateWeaponRequest, GenerateWeaponResponse
from app.services.design_research import research_design_references
from app.services.openrouter import generate_weapon


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="Roblox AI Core", version="2.0.0", lifespan=lifespan)


@app.get("/health")
async def health():
    return {"ok": True, "service": "Roblox AI Core", "version": "2.0.0"}


@app.post(
    "/v1/weapons/generate",
    response_model=GenerateWeaponResponse,
    dependencies=[Depends(verify_roblox_key)],
)
async def create_weapon(data: GenerateWeaponRequest):
    check_player_limit(
        data.player_id,
        settings.max_requests_per_minute,
        settings.max_requests_per_day,
    )
    request_id = str(uuid4())

    # Hybrid research: public, openly licensed image metadata + procedural design.
    # Search failure is non-fatal; generation continues without references.
    references = await research_design_references(data.prompt, limit=4)
    reference_notes = [
        f"{item.get('title', '')}; {item.get('description', '')}; license: {item.get('license', '')}"
        for item in references
    ]

    try:
        weapon, model = await generate_weapon(data.prompt, reference_notes)
        return GenerateWeaponResponse(
            ok=True,
            weapon=weapon,
            model=model,
            request_id=request_id,
            design_references=references,
        )
    except httpx.TimeoutException:
        raise HTTPException(
            status_code=504,
            detail="A IA demorou demais para responder. Tente novamente.",
        )
    except httpx.HTTPStatusError as exc:
        status = exc.response.status_code
        if status == 429:
            raise HTTPException(
                status_code=503,
                detail="Provedor de IA temporariamente limitado. Tente novamente mais tarde.",
            )
        raise HTTPException(
            status_code=502,
            detail="O provedor de IA retornou um erro.",
        )
    except (KeyError, IndexError, TypeError, ValueError) as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Falha ao processar resposta da IA: {str(exc)[:300]}",
        )
