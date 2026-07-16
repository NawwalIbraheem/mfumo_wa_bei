# Mfumo wa Bei Backend

Django REST backend for the Flutter app.

## Setup

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python scripts/create_database.py
python manage.py migrate
python manage.py runserver
```

## PostgreSQL database

Use a PostgreSQL database named `mfumo_wa_bei_db` and set its credentials in `.env`.

## Auth endpoints

- `POST /api/auth/register/`
- `POST /api/auth/login/`
- `POST /api/auth/refresh/`
- `GET /api/auth/me/`
- `POST /api/auth/password-reset-request/`
