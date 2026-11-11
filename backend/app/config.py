from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    openrouter_api_key: str
    roblox_ai_core_key: str
    openrouter_model: str = "openrouter/free"
    openrouter_site_url: str = "https://example.com"
    openrouter_app_name: str = "Roblox AI Core"
    max_requests_per_minute: int = 4
    max_requests_per_day: int = 20
    request_timeout_seconds: float = 45.0

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

settings = Settings()
