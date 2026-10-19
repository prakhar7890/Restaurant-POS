FROM python:3.12.10-slim-bookworm

COPY --from=ghcr.io/astral-sh/uv:0.8.13 /uv /uvx /bin/

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PATH="/app/.venv/bin:$PATH"

RUN groupadd --system app && useradd --system --gid app --create-home app

WORKDIR /app
COPY backend/pyproject.toml backend/uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
COPY --chown=app:app backend/app ./app
COPY --chown=app:app backend/alembic ./alembic
COPY --chown=app:app backend/alembic.ini ./

USER app
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--no-access-log"]