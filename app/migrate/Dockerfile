FROM python:3.12-slim@sha256:1148dbb014615300fa7e713b2f94f550c0d1c69780c0805f84f093ceee34dd0b AS builder

WORKDIR /build
COPY requirements.txt .
RUN python -m venv /venv \
    && /venv/bin/pip install --no-cache-dir --upgrade pip "setuptools>=78.1.1" \
    && /venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim@sha256:1148dbb014615300fa7e713b2f94f550c0d1c69780c0805f84f093ceee34dd0b

RUN addgroup --system --gid 1001 app \
    && adduser --system --uid 1001 --gid 1001 --no-create-home app

WORKDIR /app
COPY --from=builder /venv /venv
COPY migrate.py .

RUN pip install --no-cache-dir "setuptools>=78.1.1" "msgpack>=1.2.3" "urllib3>=2.8.0"

ENV PATH="/venv/bin:$PATH"

USER app

HEALTHCHECK NONE

CMD ["python", "migrate.py"]
