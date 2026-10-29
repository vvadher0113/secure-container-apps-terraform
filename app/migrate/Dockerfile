# Update the digest by running: docker pull python:3.12-slim and copying "Digest: sha256:..."
ARG PYTHON_IMAGE=python:3.12-slim@sha256:b2e3a4f5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3

FROM ${PYTHON_IMAGE} AS builder

WORKDIR /build
COPY requirements.txt .
RUN python -m venv /venv \
    && /venv/bin/pip install --no-cache-dir --upgrade pip \
    && /venv/bin/pip install --no-cache-dir -r requirements.txt

FROM ${PYTHON_IMAGE}

RUN addgroup --system --gid 1001 app \
    && adduser --system --uid 1001 --gid 1001 --no-create-home app

WORKDIR /app
COPY --from=builder /venv /venv
COPY migrate.py .

ENV PATH="/venv/bin:$PATH"

USER app

HEALTHCHECK NONE

CMD ["python", "migrate.py"]
