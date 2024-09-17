FROM python:3.12-slim-bullseye

COPY entrypoint.sh /entrypoint.sh
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

ENTRYPOINT ["/entrypoint.sh"]
