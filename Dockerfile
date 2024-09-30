FROM python:3.10-slim-bookworm

COPY entrypoint.sh /entrypoint.sh
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

ENTRYPOINT ["/entrypoint.sh"]
