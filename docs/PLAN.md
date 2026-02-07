# Plan de Solución: Sistema de Detección de Parámetros Faltantes en Materiales

## Problema Identificado

Los clientes envían listas de materiales con información incompleta, lo que genera reproceso cuando los cotizadores necesitan especificaciones técnicas obligatorias según la categoría/subcategoría del inventario.

**Ejemplo**: Cliente solicita "cable eléctrico 20m" → Falta: diámetro, modelo, tipo de aislamiento (según inventario de Cables).

## Arquitectura Propuesta

### Componente Principal: **Obralex API**

Sistema de análisis en 3 etapas que procesa cada producto detectado por Maia:

```
Input (Maia) → [Extracción NER] → [Validación de Parámetros] → [Generación de Consultas] → Output (Asesor)
```

### Stack Técnico

- **Backend**: FastAPI (Python 3.7+)
- **NER**: spaCy + Modelo personalizado entrenado con productos de construcción peruanos
- **LLM Orquestación**: Claude Opus 4.5 (análisis complejo) + Haiku (validaciones rápidas)
- **Embeddings**: text-embedding-3-small (OpenAI) para búsqueda semántica en inventario
- **Vector DB**: Pinecone o ChromaDB para inventario vectorizado
- **Storage**: Firestore (caché de parámetros por categoría)
- **Validación**: Sistema de reglas + LLM como juez

## Fases de Implementación

### Fase 1: Preparación de Datos (Semanas 1-2)

**Objetivo**: Crear datasets y catálogo de parámetros obligatorios

1. **Extracción de esquema de inventario**
   - Mapear todas las categorías/subcategorías
   - Documentar parámetros obligatorios por categoría
   - Ejemplos: `Cables → {diámetro, modelo, longitud, tipo_aislamiento}`

2. **Dataset de entrenamiento NER**
   - Recopilar conversaciones históricas de BigQuery
   - Anotar entidades: `PRODUCTO, MARCA, CANTIDAD, UNIDAD, DIAMETRO, MODELO, COLOR, MATERIAL, etc.`
   - Mínimo 500 ejemplos anotados

3. **Vectorización de inventario**
   - Embeddings de productos existentes con sus especificaciones completas
   - Indexar en vector DB para búsqueda semántica

**Entregables**:
- `data/catalog_schema.json` - Esquema de parámetros por categoría
- `data/training_ner.jsonl` - Dataset anotado
- Vector DB poblada con inventario

### Fase 2: Motor de Extracción NER (Semanas 3-4)

**Objetivo**: Extraer especificaciones técnicas del texto del cliente

1. **Entrenamiento de modelo NER**
   - Fine-tuning de spaCy en español con dataset de construcción
   - Entidades custom: `DIAMETRO, VOLTAJE, PRESION, ESPESOR, etc.`
   - Validación con métricas: precision, recall, F1 > 0.85

2. **Pipeline de extracción**
   ```python
   texto_cliente → spaCy NER → entidades extraídas → normalización
   ```

3. **Normalización de valores**
   - Convertir "3/4 pulgadas" → "19.05mm"
   - Estandarizar unidades (m, cm, mm, kg, etc.)
   - Mapear sinónimos: "tubo" = "tubería"

**Entregables**:
- `app/services/ner_extractor.py`
- Modelo entrenado `models/ner_construccion/`
- Tests unitarios con casos reales

### Fase 3: Sistema de Validación (Semanas 5-6)

**Objetivo**: Identificar parámetros faltantes según categoría/subcategoría

1. **Motor de validación basado en reglas**
   ```python
   def validate_product(producto, categoria, subcategoria):
       required_params = get_required_params(categoria, subcategoria)
       extracted_params = extract_params_from_ner(producto)
       missing_params = required_params - extracted_params
       return missing_params
   ```

2. **Orquestación de LLMs**
   - **Agente 1 (Claude Opus)**: Inferir parámetros implícitos del contexto
     - Ejemplo: "cemento para columnas" → inferir tipo estructural
   - **Agente 2 (Haiku)**: Validar coherencia de parámetros extraídos
   - **Agente 3 (Juez)**: Decidir si la información es suficiente o no

3. **Búsqueda semántica en inventario**
   - Si hay ambigüedad, buscar productos similares
   - Sugerir opciones al asesor: "¿Se refiere a X o Y?"

**Entregables**:
- `app/services/validator.py`
- `app/services/llm_orchestrator.py`
- Sistema de prompts versionados

### Fase 4: Generación de Consultas Inteligentes (Semana 7)

**Objetivo**: Crear preguntas contextuales para que el asesor complete información

1. **Generador de preguntas**
   - Input: `{producto, parámetros_faltantes, contexto_conversación}`
   - Output: Pregunta natural en español peruano
   - Ejemplo: "Para el cable eléctrico, ¿qué diámetro necesita? Tenemos 2.5mm, 4mm, 6mm"

2. **Priorización de preguntas**
   - Agrupar parámetros relacionados en una sola pregunta
   - Priorizar parámetros críticos para pricing

3. **Integración con Maia Web**
   - Notificación al asesor con preguntas sugeridas
   - UI para marcar parámetros como "completados"

**Entregables**:
- `app/services/question_generator.py`
- API endpoint: `POST /api/v1/materials/validate`
- Webhook para notificar a Maia Web

### Fase 5: API y Integración (Semana 8)

**Objetivo**: Exponer endpoints y conectar con ecosistema actual

1. **Endpoints principales**
   ```
   POST /api/v1/materials/extract     - Extrae parámetros con NER
   POST /api/v1/materials/validate    - Valida completitud
   POST /api/v1/materials/suggest     - Sugiere productos del inventario
   GET  /api/v1/catalog/params/{cat}  - Obtiene parámetros obligatorios
   ```

2. **Integración con N8N**
   - Webhook que recibe producto detectado por Maia
   - Procesa con Obralex API
   - Devuelve parámetros faltantes + preguntas sugeridas

3. **Caché y optimización**
   - Redis para parámetros frecuentes
   - Rate limiting por conversación
   - Logs estructurados para análisis

**Entregables**:
- API completa documentada (OpenAPI/Swagger)
- Flujo N8N configurado
- Monitoring con logs en GCP

### Fase 6: Evaluación y Refinamiento (Semana 9-10)

**Objetivo**: Medir impacto y ajustar modelos

1. **Métricas de éxito**
   - % de pedidos que pasan a cotización sin reproceso
   - Tiempo promedio de atención por pedido
   - Precisión del NER en producción
   - Satisfacción de asesores y cotizadores

2. **A/B Testing**
   - 50% pedidos con sistema nuevo
   - 50% flujo tradicional
   - Comparar tasas de conversión y tiempos

3. **Reentrenamiento continuo**
   - Feedback loop: errores del sistema → nuevo dataset
   - Ajuste de prompts según casos edge
   - Fine-tuning mensual del modelo NER

**Entregables**:
- Dashboard de métricas
- Reporte de impacto para tesis
- Plan de mejora continua

## Consideraciones Técnicas

### 1. Manejo de Ambigüedad

Cuando un producto tiene múltiples interpretaciones:
- Usar búsqueda semántica en inventario
- Presentar top-3 opciones al asesor
- Aprender de selecciones previas (histórico)

### 2. Escalabilidad

- Procesar múltiples productos en paralelo
- Cache de embeddings de productos frecuentes
- Rate limiting: max 10 productos por segundo

### 3. Costos de LLM

- Claude Opus solo para casos complejos
- Haiku para validaciones simples
- Cache de respuestas frecuentes (30 días)
- Estimado: $0.02-0.05 por conversación completa

### 4. Privacidad y Seguridad

- No almacenar datos sensibles de clientes en logs
- Encriptar comunicación con LLMs
- Auditoría de accesos a BigQuery

## Estructura del Proyecto

```
api-obralex-py/
├── app/
│   ├── api/
│   │   ├── health.py
│   │   ├── materials.py        # Endpoints de materiales
│   │   └── catalog.py          # Endpoints de catálogo
│   ├── services/
│   │   ├── ner_extractor.py    # Motor NER
│   │   ├── validator.py        # Validación de parámetros
│   │   ├── llm_orchestrator.py # Orquestación LLMs
│   │   ├── question_generator.py
│   │   └── vector_search.py    # Búsqueda semántica
│   ├── models/
│   │   └── schemas.py          # Pydantic models
│   └── main.py
├── data/
│   ├── catalog_schema.json
│   └── training_ner.jsonl
├── models/
│   └── ner_construccion/       # Modelo spaCy entrenado
├── tests/
└── notebooks/                  # Experimentación para tesis
```

## Riesgos y Mitigaciones

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| NER con baja precisión en jerga peruana | Alto | Dataset con lenguaje local, validación humana inicial |
| Latencia alta en análisis | Medio | Cache, procesamiento asíncrono, modelos rápidos |
| Categorización incorrecta de Maia | Alto | Re-validación con embeddings, sugerencias múltiples |
| Costos elevados de API | Medio | Estrategia de modelos por complejidad, cache agresivo |

## Roadmap de Entrega

- **Semana 2**: Dataset listo + esquema de parámetros
- **Semana 4**: Modelo NER funcionando con >85% F1
- **Semana 6**: Sistema de validación integrado
- **Semana 8**: API desplegada en producción
- **Semana 10**: Resultados de A/B testing para tesis

## Diferenciadores para Tesis

1. **Modelo NER específico de dominio**: Entrenado con jerga de construcción peruana
2. **Orquestación multi-LLM**: Combinación de modelos según complejidad
3. **Sistema de validación híbrido**: Reglas + IA + búsqueda semántica
4. **Impacto medible**: Reducción de reproceso, mejora en tiempo de cotización
5. **Contribución práctica**: Sistema productivo en startup real
