# Base image
FROM python:3.12-slim

# Python config
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code (excluding unnecessary files via .dockerignore)
COPY . .

# Expose port 8080 (Cloud Run default)
EXPOSE 8080

# Run with gunicorn + uvicorn workers
# Cloud Run provides credentials automatically via service identity (no serviceaccount.json needed)
CMD ["gunicorn", "main:app", "--workers", "2", "--worker-class", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8080", "--timeout", "600"]
