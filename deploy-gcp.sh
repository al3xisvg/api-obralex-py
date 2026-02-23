#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# GCP Configuration
PROJECT_ID="maia-466013"
REGION="us-central1"
REGISTRY="${REGION}-docker.pkg.dev"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}i ${NC}$1"
}

print_success() {
    echo -e "${GREEN}v${NC} $1"
}

print_error() {
    echo -e "${RED}x${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_header() {
    echo -e "\n${CYAN}=======================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=======================================================${NC}\n"
}

# Function to handle errors
handle_error() {
    print_error "$1"
    exit 1
}

# Function to show usage
show_usage() {
    echo -e "${CYAN}Uso:${NC} $0 [ambiente]"
    echo ""
    echo -e "${YELLOW}Ambientes disponibles:${NC}"
    echo "  dev   - Ambiente de desarrollo"
    echo "  prod  - Ambiente de produccion"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo "  $0 dev     # Deploy a desarrollo"
    echo "  $0 prod    # Deploy a produccion"
    echo ""
    exit 1
}

# Check if environment argument is provided
if [ -z "$1" ]; then
    print_error "Error: Debes especificar el ambiente (dev o prod)"
    echo ""
    show_usage
fi

# Validate environment argument
ENV=$1
case $ENV in
    dev|DEV)
        ENV="dev"
        REPOSITORY="ar-api-obralex-dev"
        IMAGE_NAME="api-obralex-dev"
        ;;
    prod|PROD)
        ENV="prod"
        REPOSITORY="ar-api-obralex-prod"
        IMAGE_NAME="api-obralex-prod"
        ;;
    *)
        print_error "Error: Ambiente '$1' no valido"
        echo ""
        show_usage
        ;;
esac

FULL_IMAGE="${REGISTRY}/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}"

print_header "DEPLOYMENT SCRIPT - GCP Artifact Registry (${ENV^^})"

echo -e "${CYAN}Configuracion:${NC}"
echo -e "  Ambiente:    ${GREEN}${ENV}${NC}"
echo -e "  Proyecto:    ${PROJECT_ID}"
echo -e "  Region:      ${REGION}"
echo -e "  Repositorio: ${REPOSITORY}"
echo -e "  Imagen:      ${IMAGE_NAME}"
echo ""

# Step 1: Configure GCP project
print_info "Paso 1/5: Configurando proyecto GCP..."
gcloud config set project "$PROJECT_ID"

if [ $? -ne 0 ]; then
    handle_error "Error: Fallo la configuracion del proyecto GCP"
fi
print_success "Proyecto configurado: $PROJECT_ID"

# Step 2: Authenticate Docker with Artifact Registry
print_info "Paso 2/5: Autenticando Docker con Artifact Registry..."
gcloud auth configure-docker "$REGISTRY" --quiet

if [ $? -ne 0 ]; then
    handle_error "Error: Fallo la autenticacion con Artifact Registry"
fi
print_success "Autenticacion exitosa con Artifact Registry"

# Step 3: Get latest tag from Artifact Registry
print_info "Paso 3/5: Obteniendo ultima version de Artifact Registry..."
RAW_TAGS=$(gcloud artifacts docker tags list "$FULL_IMAGE" --format="value(tag)" 2>/dev/null || echo "")

NEW_TAG=1
LATEST_TAG="0"
if [ -n "$RAW_TAGS" ]; then
    LATEST_TAG=$(echo "$RAW_TAGS" | grep -E '^[0-9]+$' | sort -n | tail -1)
    if [ -n "$LATEST_TAG" ]; then
        NEW_TAG=$((LATEST_TAG + 1))
        print_success "Ultima version encontrada: $LATEST_TAG"
    else
        print_warning "No se encontraron tags numericos. Iniciando desde 1."
        LATEST_TAG="0"
    fi
else
    print_warning "No hay versiones previas. Iniciando desde 1."
fi

print_info "Nueva version a desplegar: ${GREEN}$NEW_TAG${NC}"
echo ""

# Confirmation
read -p "Deseas continuar con el build y push de ${IMAGE_NAME}:${NEW_TAG}? (s/n) " confirm
if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
    print_warning "Deploy cancelado."
    exit 0
fi

echo ""

# Step 4: Build Docker image
print_info "Paso 4/5: Construyendo imagen Docker..."
print_warning "Esto puede tomar varios minutos..."
docker build -t "${FULL_IMAGE}:${NEW_TAG}" . --platform linux/amd64 --provenance false

if [ $? -ne 0 ]; then
    handle_error "Error: Fallo la construccion de la imagen Docker"
fi
print_success "Imagen Docker construida exitosamente"

# Step 5: Push image to Artifact Registry
print_info "Paso 5/5: Subiendo imagen a Artifact Registry..."
print_warning "Esto puede tomar varios minutos..."
docker push "${FULL_IMAGE}:${NEW_TAG}"

if [ $? -ne 0 ]; then
    handle_error "Error: Fallo el push de la imagen a Artifact Registry"
fi
print_success "Imagen subida exitosamente a Artifact Registry"

# Summary
print_header "RESUMEN DEL DEPLOYMENT (${ENV^^})"

echo -e "${CYAN}Proyecto GCP:${NC}     ${GREEN}${PROJECT_ID}${NC}"
echo -e "${CYAN}Region:${NC}           ${REGION}"
echo -e "${CYAN}Ambiente:${NC}         ${GREEN}${ENV}${NC}"
echo -e "${CYAN}Repositorio:${NC}      ${REPOSITORY}"
echo -e "${CYAN}Version anterior:${NC} ${YELLOW}${LATEST_TAG}${NC}"
echo -e "${CYAN}Version nueva:${NC}    ${GREEN}${NEW_TAG}${NC}"
echo -e "${CYAN}Imagen completa:${NC}  ${FULL_IMAGE}:${NEW_TAG}"

print_header "DEPLOYMENT COMPLETADO EXITOSAMENTE"

echo -e "${BLUE}Para desplegar en Cloud Run:${NC}"
echo -e "  ${YELLOW}gcloud run deploy api-obralex-${ENV} \\${NC}"
echo -e "  ${YELLOW}  --image ${FULL_IMAGE}:${NEW_TAG} \\${NC}"
echo -e "  ${YELLOW}  --region ${REGION} \\${NC}"
echo -e "  ${YELLOW}  --platform managed${NC}"
echo ""
echo -e "${BLUE}Para descargar en una VM de GCP:${NC}"
echo -e "  ${YELLOW}docker pull ${FULL_IMAGE}:${NEW_TAG}${NC}"
echo ""
print_success "La imagen esta lista para ser desplegada en GCP"
echo ""
