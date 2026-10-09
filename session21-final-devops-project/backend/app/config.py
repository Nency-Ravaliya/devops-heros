from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = "LabTrack API"
    app_env: str = "development"
    log_level: str = "INFO"
    database_url: str = "postgresql+psycopg://labtrack:labtrack@localhost:5432/labtrack"
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
