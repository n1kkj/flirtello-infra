FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential curl \
    && rm -rf /var/lib/apt/lists/*

COPY flirtello-chats/ /app/
RUN pip install --no-cache-dir -r requirements-streamlit.txt -r requirements-fastapi.txt -r requirements-llm.txt -r requirements-test.txt -r requirements-common.txt -r requirements-dev.txt

EXPOSE 8502
CMD ["streamlit", "run", "/app/src/test_real_app.py", "--server.port=8502", "--server.address=0.0.0.0", "--server.headless=true"]



