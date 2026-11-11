from typing import Literal
import re

from pydantic import BaseModel, Field, field_validator


WeaponType = Literal["sword", "staff", "bow", "gauntlet"]
Rarity = Literal["common", "uncommon", "rare", "epic", "legendary"]
Ability = Literal[
    "slash", "fire_burst", "ice_bolt", "dash_strike",
    "poison_orb", "chain_lightning"
]


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


class WeaponVisualSpec(BaseModel):
    silhouette: Literal["slim", "heavy", "curved", "double", "ornate", "segmented", "organic"] = "ornate"
    material: Literal["metal", "obsidian", "wood", "crystal", "stone"] = "metal"
    pattern: Literal["plain", "runic", "serrated", "flame", "frost", "lightning"] = "plain"
    particle_style: Literal["fire", "ice", "sparks", "poison", "arcane", "lightning", "none"] = "sparks"
    accent_color: str = Field(default="#FFD166", pattern=r"^#[0-9A-Fa-f]{6}$")
    detail_level: int = Field(default=3, ge=1, le=5)
    motif: str = Field(default="fantasy", min_length=2, max_length=40)
    animation_style: Literal["quick_slash", "heavy_swing", "thrust", "cast", "punch"] = "quick_slash"
    ui_theme: Literal["inferno", "frost", "arcane", "nature", "storm", "neutral"] = "neutral"


class WeaponCombatSpec(BaseModel):
    attack_style: Literal["melee", "projectile", "dash"] = "melee"
    combo_count: int = Field(default=2, ge=1, le=4)
    effect_radius: float = Field(default=8, ge=0, le=20)
    knockback: float = Field(default=0, ge=0, le=40)
    ability_duration: float = Field(default=1.0, ge=0.2, le=8.0)


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
    visual: WeaponVisualSpec = Field(default_factory=WeaponVisualSpec)
    combat: WeaponCombatSpec = Field(default_factory=WeaponCombatSpec)


class GenerateWeaponResponse(BaseModel):
    ok: bool = True
    weapon: WeaponSpec
    model: str
    request_id: str
    design_references: list[dict] = Field(default_factory=list)
