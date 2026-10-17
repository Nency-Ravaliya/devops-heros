from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = "LiftLog API"
    database_url: str = "postgresql+psycopg://liftlog:liftlog@localhost:5432/liftlog"
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
