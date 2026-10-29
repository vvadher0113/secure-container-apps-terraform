FROM python:3.12-slim@sha256:aa943ce411423c7582288f18707ff66eddcbaeb510502d747a72aeb34f30d159 AS builder

WORKDIR /build
COPY requirements.txt .
RUN python -m venv /venv \
    && /venv/bin/pip install --no-cache-dir --upgrade pip \
    && /venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim@sha256:aa943ce411423c7582288f18707ff66eddcbaeb510502d747a72aeb34f30d159

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
