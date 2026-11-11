import asyncio
import json
import os
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.services.openrouter import generate_weapon


VALID_WEAPON = {
    "name": "Lâmina Solar",
    "description": "Uma espada leve que brilha ao amanhecer.",
    "weapon_type": "sword",
    "rarity": "rare",
    "ability_id": "slash",
    "damage": 25,
    "cooldown": 1.5,
    "range": 10,
    "color": "#FFAA00",
    "visual": {
        "silhouette": "ornate",
        "material": "metal",
        "pattern": "runic",
        "particle_style": "sparks",
        "accent_color": "#FFD166",
        "detail_level": 3,
        "motif": "sol",
        "animation_style": "quick_slash",
        "ui_theme": "neutral",
    },
    "combat": {
        "attack_style": "melee",
        "combo_count": 2,
        "effect_radius": 8.0,
        "knockback": 10.0,
        "ability_duration": 1.0,
    },
}


class FakeResponse:
    def __init__(self, body):
        self.body = body

    def raise_for_status(self):
        return None

    def json(self):
        return self.body


class FakeAsyncClient:
    def __init__(self, contents):
        self.contents = iter(contents)
        self.payloads = []

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, traceback):
        return False

    async def post(self, url, *, headers, json):
        self.payloads.append(json)
        content = next(self.contents)
        return FakeResponse(
            {
                "model": "openrouter/free",
                "choices": [
                    {
                        "message": {"content": content},
                        "finish_reason": "stop",
                    }
                ],
            }
        )


def response_text(data):
    return json.dumps(data, ensure_ascii=False)


class GenerateWeaponTests(unittest.TestCase):
    def generate_with(self, *contents, reference_notes=None):
        client = FakeAsyncClient(contents)
        with patch("app.services.openrouter.httpx.AsyncClient", return_value=client):
            result = asyncio.run(generate_weapon("uma espada de luz", reference_notes))
        return result, client

    def test_accepts_pure_valid_json(self):
        (weapon, model), client = self.generate_with(response_text(VALID_WEAPON))
        self.assertEqual(weapon.name, VALID_WEAPON["name"])
        self.assertEqual(model, "openrouter/free")
        self.assertEqual(len(client.payloads), 1)

    def test_accepts_json_in_markdown_fence(self):
        (weapon, _), _ = self.generate_with("```json\n" + response_text(VALID_WEAPON) + "\n```")
        self.assertEqual(weapon.color, "#FFAA00")

    def test_accepts_json_surrounded_by_text(self):
        (weapon, _), _ = self.generate_with(
            "Aqui está a ficha pedida:\n" + response_text(VALID_WEAPON) + "\nUse-a no jogo."
        )
        self.assertEqual(weapon.damage, 25)

    def test_retries_after_invalid_json_and_uses_stricter_instruction(self):
        (weapon, _), client = self.generate_with("{json quebrado", response_text(VALID_WEAPON))
        self.assertEqual(weapon.ability_id, "slash")
        self.assertEqual(len(client.payloads), 2)
        self.assertEqual(len(client.payloads[0]["messages"]), 2)
        self.assertIn("resposta anterior foi inválida", client.payloads[1]["messages"][-1]["content"])

    def test_retries_and_fails_for_empty_response(self):
        with self.assertRaisesRegex(ValueError, "três tentativas"):
            self.generate_with("", "", "")

    def test_retries_and_fails_for_schema_invalid_json(self):
        invalid = dict(VALID_WEAPON, damage=999)
        with self.assertRaisesRegex(ValueError, "três tentativas"):
            self.generate_with(response_text(invalid), response_text(invalid), response_text(invalid))

    def test_retries_and_fails_for_fields_outside_schema(self):
        invalid = dict(VALID_WEAPON, unexpected="not allowed")
        with self.assertRaisesRegex(ValueError, "três tentativas"):
            self.generate_with(response_text(invalid), response_text(invalid), response_text(invalid))

    def test_fails_after_three_consecutive_invalid_responses(self):
        with self.assertRaisesRegex(ValueError, "três tentativas"):
            self.generate_with("{", "[]", "texto sem JSON")

    def test_preserves_reference_notes_in_request(self):
        _, client = self.generate_with(
            response_text(VALID_WEAPON),
            reference_notes=["espada cerimonial azul"],
        )
        request_text = client.payloads[0]["messages"][1]["content"]
        self.assertIn("Inspiração visual pesquisada", request_text)
        self.assertIn("espada cerimonial azul", request_text)

    def test_preserves_visual_and_combat_fields(self):
        (weapon, _), _ = self.generate_with(response_text(VALID_WEAPON))
        self.assertEqual(weapon.visual.material, "metal")
        self.assertEqual(weapon.visual.detail_level, 3)
        self.assertEqual(weapon.combat.attack_style, "melee")
        self.assertEqual(weapon.combat.knockback, 10.0)


if __name__ == "__main__":
    unittest.main()
