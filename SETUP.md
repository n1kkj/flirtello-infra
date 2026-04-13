# Docker setup

Этот документ описывает:
- что делает каждый репозиторий в монорепо;
- как поднять весь стек целиком;
- как запускать сервисы по отдельности;
- с какими внешними системами сервисы взаимодействуют.

---

## 1) Состав монорепозитория и назначение

| Репозиторий / папка | Что это | Порт в docker-compose |
|---|---|---|
| `flirtello-backend-service` | Основной FastAPI backend (бизнес-логика, API, интеграции). | `8000` |
| `flirtello-mkt-collector` | FastAPI сервис маркетинговых событий / постбеков. | `8001` |
| `flirtello-chats` | Streamlit UI (чаты), запускается через `test_real_app.py`. | `8502` |
| `context-images-microservice` | Отдельный сервис для контекстных изображений. | `8010` |
| `flirtello-bi` | BI-frontend (готовый `build`, отдается через nginx внутри контейнера). | `8082` |
| `nginx` | Reverse proxy для `/api`, `/mkt`, `/chats`; `/bi` редиректится на порт BI. | `${NGINX_PORT:-80}` |

---

## 2) Как сервисы маршрутизируются

Через основной nginx:

- `/api/` → `backend:8000`
- `/mkt/` → `mkt-collector:8001`
- `/chats/` → `chats:8502`
- `/bi/` → `302` редирект на `http://<host>:8083/`
- `/` → редирект на внешний frontend `https://dt3lboegqhuu2.cloudfront.net`

> BI вынесен на отдельный порт специально: так избегаются конфликты абсолютных SPA-путей (`/_app/*`, `/data/*`, `/api/*.json`) с общими роутами reverse proxy.

---

## 3) Запуск всего стека одновременно

Из корня репозитория:

```bash
docker compose -f docker-compose.yaml up --build -d
```

Остановка:

```bash
docker compose -f docker-compose.yaml down
```

Если порт `80` на хосте занят:

```bash
NGINX_PORT=8088 docker compose -f docker-compose.yaml up --build -d
```

---

## 4) Запуск сервисов по отдельности

Из корня репозитория можно поднимать любой сервис отдельным compose-файлом:

```bash
docker compose -f deploy/compose/backend-compose.yaml up --build -d
docker compose -f deploy/compose/mkt-collector-compose.yaml up --build -d
docker compose -f deploy/compose/chats-compose.yaml up --build -d
docker compose -f deploy/compose/context-images-compose.yaml up --build -d
docker compose -f deploy/compose/bi-compose.yaml up --build -d
docker compose -f deploy/compose/nginx-compose.yaml up --build -d
```

---

## 5) С какими внешними сервисами взаимодействуют

Ниже — практическая карта интеграций для деплоя (по текущей конфигурации и переменным окружения).

### `flirtello-backend-service`

Основные внешние зависимости:
- **Supabase / Postgres** (`API_URL`, `ANON_KEY`, `SERVICE_ROLE_KEY`, `DB_URL`, `ASYNC_DB_URL`);
- **Sentry** (`SENTRY_DSN`, `SENTRY_ENVIRONMENT`);
- **Telegram Bot API** (`TELEGRAM_BOT_TOKEN`);
- **Roleplay / LLM endpoint** (`ROLEPLAY_API_URL`, `TRANSLATOR_LLM_URL`);
- **Маркетинг-коллектор** (`MKT_COLLECTOR_URL`, `MKT_COLLECTOR_API_KEY`);
- **Deepgram** (`DEEPGRAM_API_KEY`);
- опционально **Grafana Cloud metrics** (`GRAFANA_*`).

### `flirtello-mkt-collector`

Обычно работает с:
- входящими postback/webhook событиями;
- внешней БД/хранилищем (через `.env`);
- внешними URL постбеков и API-ключами (через `.env`).

### `flirtello-chats`

Обычно работает с:
- backend API (`/api`) для данных/действий;
- внешними ключами/URL из `flirtello-chats/.env`.

### `context-images-microservice`

Обычно работает с:
- backend или отдельными API генерации/хранения изображений;
- внешними ключами/URL из `context-images-microservice/.env`.

### `flirtello-bi`

- обслуживает **готовый статический build**;
- внешний доступ рекомендуется по `http://<host>:8083/`.

---

## 6) Быстрая проверка после деплоя

```bash
curl -I http://<host>/api/docs
curl -I http://<host>/mkt/docs
curl -I http://<host>/chats/
curl -I http://<host>/bi/
curl -I http://<host>:8083/
```

---

## 7) Частые проблемы

### Nginx подхватил старый конфиг

```bash
docker compose -f docker-compose.yaml down
docker compose -f docker-compose.yaml up -d --force-recreate
docker exec -it flirtello-stack-nginx-1 sh -lc 'nginx -t'
```

### Порт 80 занят

```bash
NGINX_PORT=8088 docker compose -f docker-compose.yaml up --build -d
```
