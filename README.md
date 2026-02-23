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
uvicorn main:app --reload
```

La API estará disponible en `http://localhost:8000`

## Endpoints

- `GET /` - Mensaje de bienvenida
- `GET /api/v1/health` - Health check
- `GET /docs` - Documentación interactiva (Swagger)

# GCP

### Paso 1: Autenticar con GCloud

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project maia-466013
```

### Paso 2: Construir imagen Docker

```bash
docker build -t us-central1-docker.pkg.dev/maia-466013/ar-api-obralex-prod/api-obralex-prod:1 . --platform linux/amd64
```

### Paso 3: Autenticar Docker con Artifact Registry

```bash
~ gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://us-central1-docker.pkg.dev

~ gcloud auth configure-docker us-central1-docker.pkg.dev
```

### Paso 4: Subir imagen

```bash
docker push us-central1-docker.pkg.dev/maia-466013/ar-api-obralex-prod/api-obralex-prod:1
```
