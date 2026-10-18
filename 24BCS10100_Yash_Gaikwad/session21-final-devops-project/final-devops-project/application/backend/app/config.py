import os


def get_database_url() -> str:
    """Database connection string, taken from the DATABASE_URL environment variable.

    There is deliberately no default: a URL with a username and password does not
    belong in source code. Docker Compose and the Helm chart both provide it.
    """
    url = os.getenv("DATABASE_URL")
    if not url:
        raise RuntimeError(
            "DATABASE_URL is not set. Example: postgresql+psycopg://USER:PASSWORD@HOST:5432/DBNAME"
        )
    return url
