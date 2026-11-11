from typing import Literal
from pydantic import BaseModel, Field, field_validator
import re

WeaponType = Literal["sword", "staff", "bow", "gauntlet"]
Rarity = Literal["common", "uncommon", "rare", "epic", "legendary"]
Ability = Literal["slash", "fire_burst", "ice_bolt", "dash_strike", "poison_orb", "chain_lightning"]

class GenerateWeaponRequest(BaseModel):
    prompt: str = Field(min_length=5, max_length=240)
    player_id: int = Field(gt=0)
    game_id: str = Field(min_length=1, max_length=40)

    @field_validator("prompt")
    @classmethod
    def clean_prompt(cls, value: str) -> str:
        value = re.sub(r"[\x00-\x1f\x7f]", " ", value)
        value = re.sub(r"\s+", " ", value).strip()
        if len(value) < 5:
            raise ValueError("Descreva melhor a arma.")
        return value

class WeaponSpec(BaseModel):
    name: str = Field(min_length=2, max_length=32)
    description: str = Field(min_length=5, max_length=140)
    weapon_type: WeaponType
    rarity: Rarity
    ability_id: Ability
    damage: int = Field(ge=5, le=60)
    cooldown: float = Field(ge=0.8, le=5.0)
    range: int = Field(ge=6, le=30)
    color: str = Field(pattern=r"^#[0-9A-Fa-f]{6}$")

class GenerateWeaponResponse(BaseModel):
    ok: bool = True
    weapon: WeaponSpec
    model: str
    request_id: str
