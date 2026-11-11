import re
from html import unescape

import httpx


COMMONS_API = "https://commons.wikimedia.org/w/api.php"
ALLOWED_LICENSES = {
    "CC0", "Public domain", "CC BY", "CC BY-SA",
    "Creative Commons Attribution", "Creative Commons Attribution-Share Alike",
}


def _plain(value: str, limit: int = 180) -> str:
    value = re.sub(r"<[^>]+>", " ", value or "")
    value = unescape(value)
    value = re.sub(r"\s+", " ", value).strip()
    return value[:limit]


async def research_design_references(prompt: str, limit: int = 4) -> list[dict]:
    """Find openly licensed Wikimedia Commons images as visual research only.

    Images are not downloaded, imported into Roblox, or redistributed by this
    service. The returned records are citations and design context for the model.
    A failure in the public search service must never block weapon generation.
    """
    terms = re.findall(r"[\wÀ-ÿ-]{3,}", prompt, flags=re.UNICODE)[:7]
    if not terms:
        return []

    params = {
        "action": "query",
        "generator": "search",
        "gsrsearch": " ".join(terms),
        "gsrnamespace": 6,
        "gsrlimit": max(1, min(limit * 2, 8)),
        "prop": "imageinfo",
        "iiprop": "url|extmetadata",
        "iiurlwidth": 480,
        "format": "json",
    }
    headers = {"User-Agent": "RobloxAICore/2.0 (visual design research)"}

    try:
        async with httpx.AsyncClient(timeout=8.0, follow_redirects=True) as client:
            response = await client.get(COMMONS_API, params=params, headers=headers)
            response.raise_for_status()
            payload = response.json()
    except (httpx.HTTPError, ValueError):
        return []

    pages = (payload.get("query") or {}).get("pages") or {}
    results: list[dict] = []
    for page in pages.values():
        info_list = page.get("imageinfo") or []
        if not info_list:
            continue
        info = info_list[0]
        metadata = info.get("extmetadata") or {}
        license_name = _plain((metadata.get("LicenseShortName") or {}).get("value", ""), 80)
        usage_terms = _plain((metadata.get("UsageTerms") or {}).get("value", ""), 100)
        if not any(allowed.lower() in license_name.lower() for allowed in ALLOWED_LICENSES):
            continue

        title = _plain(page.get("title", "Visual reference"), 120)
        results.append({
            "title": title,
            "thumbnail_url": info.get("thumburl") or info.get("url"),
            "source_url": info.get("descriptionurl"),
            "license": license_name or usage_terms,
            "artist": _plain((metadata.get("Artist") or {}).get("value", ""), 100),
            "usage_terms": usage_terms,
        })
        if len(results) >= limit:
            break

    return results
