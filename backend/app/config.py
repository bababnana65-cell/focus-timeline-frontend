from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Timeliness Backend"
    environment: str = "local"
    database_url: str = "sqlite:///./timeliness.db"
    auto_create_schema: bool = True
    seed_demo_data: bool = True
    secret_key: str = "dev-only-change-me"
    session_ttl_hours: int = 24 * 30
    sms_code_ttl_seconds: int = 300
    sms_debug_return_code: bool = True
    public_share_base_url: str = "https://timeliness.example.com/share"
    random_recommendation_batch_size: int = 10

    model_config = SettingsConfigDict(
        env_prefix="TIMELINESS_",
        env_file=".env",
        extra="ignore",
    )


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
