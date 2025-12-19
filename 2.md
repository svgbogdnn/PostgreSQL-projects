# Технологический стек и архитектура проекта ITAM

---

## 1) Система

**ITAM** — веб-приложение для управления учебными данными в едином интерфейсе: **курсы, занятия, посещаемость, фидбэк, экспорт, аналитика, профиль**.

Фронтенд отображает интерфейс (страницы “Курсы”, “Посещаемость”, “Фидбэк”, “Экспорт”, “Аналитика”, “Профиль”) и общается с бэкендом по HTTP API.

Примеры интерфейса в репоз (скриншоты):

* Курсы: `imgs/Courses/Courses1.png` … `imgs/Courses/Courses7.png`
* Посещаемость: `imgs/Attendance/Attendance1.png` … `imgs/Attendance/Attendance5.png`
* Фидбэк: `imgs/Feedback/Feedback1.png` … `imgs/Feedback/Feedback6.png`
* Экспорт: `imgs/Export/Export1.png` … `imgs/Export/Export4.png`
* Авторизация/регистрация: `imgs/Login/Login1.png` … `imgs/Login/Login6.png`
* Профиль: `imgs/Profile/Profile1.png` … `imgs/Profile/Profile4.png`

---

## 2) Высокоуровневая схема взаимодействия

### 2.1. Компоненты

* **Frontend (React + TypeScript + UI библиотека)**
  Отрисовка страниц, формы, таблицы, фильтры, модальные окна, вызовы API.
* **Backend (FastAPI)**
  REST API: маршруты, валидация входных данных, бизнес-логика, авторизация, экспорт.
* **Database (SQL через SQLAlchemy + миграции Alembic)**
  Хранение пользователей, курсов, уроков, посещаемости, отзывов.
* **Docker / GitHub Actions**
  Сборка контейнеров и воспроизводимый запуск (локально или в окружении).

### 2.2. Поток запроса (пример)

1. Пользователь открывает страницу “Курсы” на фронтенде.
2. Фронтенд делает запрос к API бэкенда (например, получить список курсов).
3. Бэкенд валидирует параметры, читает данные из БД через ORM и возвращает JSON.
4. Фронтенд рендерит таблицу/карточки, применяет фильтры/сортировку, показывает статистику.

---

## 3) Технологии: что используется и зачем

### 3.1. Backend: FastAPI + экосистема

**FastAPI** — фреймворк для HTTP API: роутинг, зависимости, валидация, документация OpenAPI/Swagger. Он хорошо подходит под архитектуру “много модулей / много ресурсов”. ([fastapi.tiangolo.com][1])

Типовой подход, который используется в подобных проектах и поддерживается FastAPI:

* разбивка API на модули через `APIRouter`
* подключение модулей в приложение через `include_router` (удобно для `api/v1/*`) ([fastapi.tiangolo.com][1])

**CORS** (Cross-Origin Resource Sharing) — нужен, потому что фронтенд и бэкенд часто работают на разных портах/доменах в разработке. В FastAPI это делается через `CORSMiddleware`. ([fastapi.tiangolo.com][2])

**Uvicorn** — ASGI-сервер, которым обычно поднимают FastAPI в dev/prod (в dev — с `--reload`). ([fastapi.tiangolo.com][3])

### 3.2. Работа с БД: SQLAlchemy + Alembic

**SQLAlchemy** — ORM/SQL toolkit: модели, сессии, транзакции, запросы.
**Alembic** — миграции схемы БД (версионирование структуры таблиц).

Ключевая идея:

* Модели описываются в `backend/app/models/*`
* Pydantic-схемы для API (вход/выход) — в `backend/app/schemas/*`
* Миграции — в `backend/alembic/*` + `backend/alembic.ini`

Это позволяет:

* поддерживать консистентную схему БД
* воспроизводимо поднимать БД в любом окружении
* не “ломать” структуру при обновлениях

### 3.3. Auth: логин/пароли/токены

В FastAPI типовой паттерн авторизации для логина по паролю — через security-механизмы (`OAuth2PasswordRequestForm`, Bearer-токены и т. п.).
Даже если конкретная реализация в проекте проще/кастомнее, логика обычно такая:

* `/auth/login` принимает email+password
* сервер проверяет хэш пароля
* сервер возвращает токен
* фронтенд кладёт токен в хранилище (часто `localStorage`) и начинает слать `Authorization: Bearer <token>` в API-запросах

### 3.4. Frontend: React + TypeScript + сборщик

**React** — компонентный UI.
**TypeScript** — типизация данных (важно при большом количестве таблиц/форм/DTO).
**Vite** — сборка/дев-сервер, быстрый DX. Для конфигурации API обычно используют переменные окружения `VITE_*` (например, base URL бэкенда).

### 3.5. UI слой: Ant Design (или аналогичный подход)

Судя по стилистике интерфейса и типовым компонентам (таблицы, модалки, селекты, формы), проект опирается на UI-библиотеку уровня Ant Design:

* единые компоненты для таблиц/форм/валидации
* согласованный дизайн
* ускорение разработки админ-панели

Ant Design поддерживает централизованную настройку темы через `ConfigProvider`.

### 3.6. Docker и воспроизводимость

В репозитории присутствует `backend/Dockerfile`, поэтому бэкенд можно запускать как контейнер без ручной установки Python-зависимостей на машине.

Также у вас есть workflow `.github/workflows/publish-images.yml` — значит, проект ориентирован на повторяемую сборку образов и удобный деплой (например, через GHCR).

---

## 4) Структура репозитория (логика по слоям)

Ниже — **типовая логика**, которая прямо соответствует наличию файлов/папок в проекте:

### 4.1. Backend

* `backend/app/api/v1/*.py`
  Роуты по доменам: `analytics`, `attendance`, `auth`, `courses`, `export`, `feedback`, `lessons`, `users`.
* `backend/app/core/*`
  Конфиг, подключение к БД, security, зависимости приложения (общие вещи).
* `backend/app/models/*`
  ORM-модели (таблицы БД).
* `backend/app/schemas/*`
  DTO/Pydantic-схемы для входных/выходных данных.
* `backend/alembic/*`, `backend/alembic.ini`
  Миграции БД.

### 4.2. Frontend

* `frontend/src/pages/*`
  Страницы: Курсы / Посещаемость / Фидбэк / Экспорт / Аналитика / Профиль / Логин / Регистрация.
* `frontend/src/api/*`
  HTTP-клиент и функции доступа к API (обычно axios/fetch обёртки).
* `frontend/src/config/*`
  Базовые настройки (например, base URL API, фичи окружения).

---

## 5) Как запустить проект: варианты запуска

Ниже два стандартных сценария: **локально** и **через Docker**. В документации обычно дают оба, потому что аудитория разная.

---

# Вариант A — запуск локально (рекомендуется для разработки)

## A1. Предварительные требования

Установить:

* **Git**
* **Python 3.10+** (или версия, указанная в `backend/requirements.txt` / `pyproject.toml`)
* **Node.js 18+** (или версия, указанная в `frontend/package.json` / `.nvmrc` если есть)

## A2. Клонирование репозитория

```bash
git clone <repo_url>
cd <repo_url>
```

## A3. Backend: установка и запуск

Перейти в backend:

```bash
cd backend
```

Создать виртуальное окружение и поставить зависимости (один из вариантов):

```bash
python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

pip install -r requirements.txt
```

Применить миграции Alembic:

```bash
alembic upgrade head
```

Запустить сервер (типовая команда для FastAPI):

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Примечание: если точка входа называется иначе (например, `main.py` лежит не в `app/`), ориентир простой:

* найдите место, где создаётся объект FastAPI: `app = FastAPI(...)`
* запустите `uvicorn <python_import_path>:app`

## A4. Frontend: установка и запуск

Открыть второй терминал, перейти в frontend:

```bash
cd frontend
npm install
npm run dev
```

## A5. Настройка base URL API (если требуется)

Обычно в Vite это делается через `.env.local` и переменную вида `VITE_API_URL`.
Пример:

```bash
# frontend/.env.local
VITE_API_URL=http://localhost:8000
```

---

# Вариант B — запуск через Docker 

## B1. Собрать и запустить backend

Из корня репозитория:

```bash
docker build -t itam-backend ./backend
docker run --rm -p 8000:8000 itam-backend
```

## B2. Собрать и запустить frontend

(Если у фронтенда есть Dockerfile — аналогично. Если нет, чаще делают dev-запуск через Node локально.)

Примерная схема:

```bash
docker build -t itam-frontend ./frontend
docker run --rm -p 5173:5173 itam-frontend
```

## B3. Если используются готовые образы из GitHub Actions

Сценарий обычно такой:

1. посмотреть `.github/workflows/publish-images.yml`, какие теги/имена образов публикуются
2. выполнить:

```bash
docker pull ghcr.io/<owner>/<image>:latest
docker run -p 8000:8000 ghcr.io/<owner>/<image>:latest
```

---

## 6) Связь фронтенд и бекенд

### 6.1. Контракт: API v1

У вас явно выделены модули:

* `backend/app/api/v1/courses.py`
* `backend/app/api/v1/lessons.py`
* `backend/app/api/v1/attendance.py`
* `backend/app/api/v1/feedback.py`
* `backend/app/api/v1/export.py`
* `backend/app/api/v1/analytics.py`
* `backend/app/api/v1/auth.py`
* `backend/app/api/v1/users.py`

Это означает, что фронтенд не “угадывает” данные, а работает по контракту:

* фронтенд вызывает endpoints
* получает JSON
* отображает таблицы/карточки/графики

### 6.2. Авторизация

После логина фронтенд:

* сохраняет токен
* подставляет его в запросы к API (обычно через интерсептор или единый клиент)
* защищает роуты (если токена нет — редирект на `/login`)

FastAPI даёт типовой инструментарий для реализации такого потока.

### 6.3. CORS

В dev-режиме фронт и бэк обычно на разных портах (например, 5173 и 8000). Поэтому CORS обязателен, иначе браузер блокирует запросы. В FastAPI это решается `CORSMiddleware`. ([fastapi.tiangolo.com][2])

[1]: https://fastapi.tiangolo.com/tutorial/bigger-applications/ "Bigger Applications - Multiple Files - FastAPI"
[2]: https://fastapi.tiangolo.com/tutorial/cors/ "CORS (Cross-Origin Resource Sharing) - FastAPI"
[3]: https://fastapi.tiangolo.com/tutorial/security/simple-oauth2/ "Simple OAuth2 with Password and Bearer - FastAPI"
