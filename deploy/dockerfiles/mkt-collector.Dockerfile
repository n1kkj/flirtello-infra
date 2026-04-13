FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential curl \
    && rm -rf /var/lib/apt/lists/*

COPY flirtello-mkt-collector/ /app/
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi
RUN if [ -f src/requirements.txt ]; then pip install --no-cache-dir -r src/requirements.txt; fi
RUN if [ -f pyproject.toml ]; then pip install --no-cache-dir .; fi
RUN python -m pip install --no-cache-dir uvicorn

EXPOSE 8001
CMD ["sh", "-c", "if [ -f /app/src/main.py ]; then cd /app/src; fi; python -m uvicorn main:app --host 0.0.0.0 --port 8001"]
