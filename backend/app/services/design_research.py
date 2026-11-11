import re
from html import unescape

import httpx


COMMONS_API = "https://commons.wikimedia.org/w/api.php"


def _plain(value: str, limit: int = 180) -> str:
    value = re.sub(r"<[^>]+>", " ", value or "")
    value = unescape(value)
    value = re.sub(r"\s+", " ", value).strip()
    return value[:limit]


def _license_is_reusable(name: str) -> bool:
    normalized = (name or "").strip().upper()
    if "NONCOMMERCIAL" in normalized or "NC" in normalized.split():
        return False
    if "NODERIVATIVES" in normalized or "NO DERIVATIVES" in normalized or "ND" in normalized.split():
        return False
    return (
        normalized.startswith("CC0")
        or normalized.startswith("PUBLIC DOMAIN")
        or normalized.startswith("CC BY ")
        or normalized.startswith("CC BY-SA ")
    )


async def research_design_references(prompt: str, limit: int = 4) -> list[dict]:
    """Find openly licensed Wikimedia Commons images as research citations.

    The service returns image links and attribution metadata only. It does not
    download, republish, or import reference images into a Roblox experience.
    Search failure is non-fatal and never blocks weapon generation.
    """
    terms = re.findall(r"[\wÀ-ÿ-]{3,}", prompt, flags=re.UNICODE)[:7]
    if not terms:
        return []

    params = {
        "action": "query",
        "generator": "search",
        "gsrsearch": " ".join(terms),
        "gsrnamespace": 6,
        "gsrlimit": max(1, min(limit * 3, 10)),
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
        if not _license_is_reusable(license_name):
            continue

        title = _plain(page.get("title", "Visual reference"), 120)
        description = _plain((metadata.get("ImageDescription") or {}).get("value", ""), 240)
        results.append({
            "title": title,
            "description": description,
            "thumbnail_url": info.get("thumburl") or info.get("url"),
            "source_url": info.get("descriptionurl"),
            "license": license_name or usage_terms,
            "artist": _plain((metadata.get("Artist") or {}).get("value", ""), 100),
            "usage_terms": usage_terms,
        })
        if len(results) >= limit:
            break

    return results
