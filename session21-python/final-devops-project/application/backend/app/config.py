from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "TaskBoard API"
    database_url: str = "postgresql+psycopg://taskboard:taskboard@localhost:5432/taskboard"
    # The UI calls the API same-origin through nginx (/api), so CORS is only needed for
    # local dev servers. Override with CORS_ORIGINS='["https://taskboard.example.com"]'.
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:5173"]
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
