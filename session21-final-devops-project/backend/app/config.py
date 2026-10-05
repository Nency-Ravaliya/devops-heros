from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = "TaskBoard API"
    app_env: str = "development"
    log_level: str = "INFO"
    database_url: str = "postgresql+psycopg://taskboard:taskboard@localhost:5432/taskboard"
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
