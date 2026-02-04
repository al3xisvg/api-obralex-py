# Obralex API

API REST construida con FastAPI.

## Instalación

```bash
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
pip install -r requirements.txt
```

## Ejecución

```bash
uvicorn app.main:app --reload
```

La API estará disponible en `http://localhost:8000`

## Endpoints

- `GET /` - Mensaje de bienvenida
- `GET /api/v1/health` - Health check
- `GET /docs` - Documentación interactiva (Swagger)
