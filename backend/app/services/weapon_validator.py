from app.schemas.weapon import WeaponSpec

ALLOWED_ABILITIES = {
    "slash", "fire_burst", "ice_bolt", "dash_strike", "poison_orb", "chain_lightning"
}

def validate_weapon(data: dict) -> WeaponSpec:
    # Pydantic rejects unknown abilities, invalid types, and out-of-range stats.
    weapon = WeaponSpec.model_validate(data)
    if weapon.ability_id not in ALLOWED_ABILITIES:
        raise ValueError("Habilidade não permitida.")
    return weapon
