from pydantic_settings import BaseSettings
from pathlib import Path


class Settings(BaseSettings):
    app_name: str = "Learn Chinese by Music"
    debug: bool = True
    database_path: str = str(Path(__file__).parent / "data" / "app.db")
    secret_key: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 7  # 7 days

    # Qiniu (China)
    qiniu_access_key: str = ""
    qiniu_secret_key: str = ""
    qiniu_bucket: str = ""
    qiniu_domain: str = ""

    # Cloudflare R2 (Overseas)
    r2_account_id: str = ""
    r2_access_key_id: str = ""
    r2_secret_access_key: str = ""
    r2_bucket: str = ""
    r2_domain: str = ""

    model_config = {"env_file": ".env", "env_prefix": "APP_"}


settings = Settings()
