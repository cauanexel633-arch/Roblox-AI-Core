from app.schemas.weapon import WeaponSpec

ALLOWED_ABILITIES = {
    "slash", "fire_burst", "ice_bolt", "dash_strike", "poison_orb", "chain_lightning"
}

WEAPON_SPEC_FIELDS = set(WeaponSpec.model_fields)

def validate_weapon(data: dict) -> WeaponSpec:
    if not isinstance(data, dict):
        raise ValueError("A resposta da IA deve ser um objeto JSON.")

    unknown_fields = set(data) - WEAPON_SPEC_FIELDS
    if unknown_fields:
        raise ValueError(
            "A resposta da IA contém campos fora do esquema: "
            + ", ".join(sorted(unknown_fields))
        )

    # Pydantic validates required fields, types, and the configured bounds.
    weapon = WeaponSpec.model_validate(data)
    if weapon.ability_id not in ALLOWED_ABILITIES:
        raise ValueError("Habilidade não permitida.")
    return weapon
