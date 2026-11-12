FROM python:3.15-slim@sha256:65a65fc7b30b06cb6df4930fd4650697cb23f4c2698ab81fc87e4b031bc36928 AS builder

WORKDIR /build
COPY requirements.txt .
RUN python -m venv /venv \
    && /venv/bin/pip install --no-cache-dir --upgrade pip "setuptools>=78.1.1" \
    && /venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python:3.15-slim@sha256:65a65fc7b30b06cb6df4930fd4650697cb23f4c2698ab81fc87e4b031bc36928

RUN addgroup --system --gid 1001 app \
    && adduser --system --uid 1001 --gid 1001 --no-create-home app

WORKDIR /app
COPY --from=builder /venv /venv
COPY main.py .

RUN pip install --no-cache-dir "setuptools>=78.1.1" "msgpack>=1.2.3" "urllib3>=2.8.0"

ENV PATH="/venv/bin:$PATH"

USER app

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
