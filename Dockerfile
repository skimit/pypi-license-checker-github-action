FROM python:3.12-slim-bullseye

COPY entrypoint.sh /entrypoint.sh
COPY --from=ghcr.io/astral-sh/uv:0.4.9 /uv /bin/uv

ENTRYPOINT ["/entrypoint.sh"]
