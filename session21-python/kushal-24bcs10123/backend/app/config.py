from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration. Every value can be overridden with an env var,
    which is how the ConfigMap / Secret reach the pod in Kubernetes."""

    app_name: str = "StudyTrack API"
    app_env: str = "development"
    app_version: str = "0.1.0"
    database_url: str = "postgresql+psycopg://studytrack:studytrack@localhost:5432/studytrack"
    daily_goal_minutes: int = 120
    # comma separated list; empty means the API is only called same-origin (nginx / Ingress proxy /api)
    cors_origins: str = ""

    model_config = SettingsConfigDict(env_prefix="", env_file=".env", extra="ignore")


settings = Settings()
