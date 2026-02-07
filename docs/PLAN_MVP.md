# Plan MVP: Sistema de Detección de Parámetros Faltantes (4 Semanas)

## Alcance del MVP

**Objetivo**: Validar hipótesis de que un sistema automatizado puede detectar parámetros faltantes y reducir reproceso en cotizaciones.

**Reducción de alcance**:
- ✅ Enfoque en **2-3 categorías piloto** (ej: Cables, Tuberías, Cemento)
- ✅ Solo análisis de **texto** (sin imágenes/documentos)
- ✅ Usar **LLMs con prompting** en lugar de NER personalizado
- ✅ Integración **manual/semi-automática** (sin webhook automático)
- ✅ Métricas básicas para validar impacto

## Stack Técnico Simplificado

```
FastAPI + Claude Opus/Haiku + Firestore + Prompting Estructurado
```

**Sin**: spaCy custom, Vector DB, Redis, entrenamiento de modelos

**Con**: Prompting avanzado, validación basada en reglas simples, caché en memoria

## Arquitectura MVP

```
Input Manual (Maia Web) → API Obralex → Análisis LLM → Output (Parámetros faltantes + Preguntas)
```

**Flujo simplificado**:
1. Asesor copia texto del producto desde Maia Web
2. Pega en interfaz simple de Obralex MVP
3. Sistema analiza y muestra parámetros faltantes
4. Asesor pregunta al cliente lo necesario
5. Marca como "completo" y pasa a cotización

## Plan de 4 Semanas

### Semana 1: Setup + Catálogo de Parámetros

**Lunes - Martes: Setup del proyecto**
- [x] Estructura FastAPI básica
- [ ] Integración con Claude API (Anthropic)
- [ ] Conexión a Firestore (lectura de conversaciones)
- [ ] Dockerfile + deploy inicial en Cloud Run

**Miércoles - Viernes: Catálogo de parámetros**
- [ ] Mapear 3 categorías piloto con cotizadores
  - Ejemplo: Cables → `{diámetro, voltaje, tipo_aislamiento, longitud}`
  - Ejemplo: Tuberías → `{diámetro, material, presión, longitud}`
  - Ejemplo: Cemento → `{tipo, resistencia, cantidad_bolsas}`
- [ ] Crear `data/catalog_schema.json` con parámetros obligatorios
- [ ] 20-30 ejemplos reales de cada categoría con parámetros completos/incompletos

**Entregables Semana 1**:
- API base funcionando
- Archivo `catalog_schema.json` con 3 categorías
- Dataset de 60-90 ejemplos etiquetados

---

### Semana 2: Motor de Análisis con LLM

**Lunes - Martes: Sistema de Prompts**
- [ ] Prompt principal de extracción de parámetros
  ```
  Sistema: Eres experto en materiales de construcción en Perú.
  Tarea: Extraer parámetros técnicos de este producto.
  Categoría: {categoria}
  Parámetros requeridos: {required_params}
  Texto del cliente: {texto}

  Output JSON: {param: valor o null si falta}
  ```
- [ ] Prompt de generación de preguntas
- [ ] Validación de outputs con Pydantic

**Miércoles - Jueves: Implementación del servicio**
- [ ] `app/services/llm_analyzer.py`
  - Función `extract_params(texto, categoria, subcategoria)`
  - Función `generate_questions(missing_params, context)`
- [ ] Estrategia de modelos:
  - Claude Opus para extracción compleja
  - Haiku para validaciones simples
- [ ] Manejo de errores y fallbacks

**Viernes: Testing con ejemplos reales**
- [ ] Tests con los 60-90 ejemplos del dataset
- [ ] Calcular precisión: % de parámetros correctamente identificados
- [ ] Iterar prompts hasta lograr >80% de precisión

**Entregables Semana 2**:
- Servicio de análisis LLM funcionando
- Precisión validada >80% en dataset piloto
- Tests automatizados

---

### Semana 3: API + Interfaz Básica

**Lunes - Martes: Endpoints de la API**
- [ ] `POST /api/v1/analyze/product`
  ```json
  Request:
  {
    "texto": "cable 20 metros marca indeco",
    "categoria": "Electricidad",
    "subcategoria": "Cables"
  }

  Response:
  {
    "parametros_detectados": {
      "longitud": "20m",
      "marca": "Indeco",
      "diametro": null,
      "voltaje": null
    },
    "parametros_faltantes": ["diametro", "voltaje"],
    "preguntas_sugeridas": [
      "¿Qué diámetro de cable necesita? (2.5mm, 4mm, 6mm)"
    ],
    "completitud": "50%",
    "puede_cotizar": false
  }
  ```
- [ ] `GET /api/v1/catalog/params/{categoria}/{subcategoria}`
- [ ] Documentación Swagger completa

**Miércoles - Jueves: Interfaz Web Simple**
- [ ] HTML + Vanilla JS (sin frameworks para rapidez)
- [ ] UI con 3 secciones:
  1. Input: Textarea para pegar texto del producto
  2. Selector: Categoría/Subcategoría (dropdown)
  3. Output: Tabla con parámetros detectados/faltantes + preguntas
- [ ] Botón "Analizar" que llama a la API
- [ ] Botón "Marcar como completo" (para métricas)

**Viernes: Integración básica con Firestore**
- [ ] Guardar análisis realizados en Firestore
  - Colección: `material_analysis`
  - Campos: `{timestamp, producto, categoria, params_detected, params_missing, asesor_id}`
- [ ] Endpoint para obtener historial de análisis

**Entregables Semana 3**:
- API REST completa y documentada
- Interfaz web funcional
- Almacenamiento en Firestore

---

### Semana 4: Piloto + Métricas + Ajustes

**Lunes: Deploy y capacitación**
- [ ] Deploy a Cloud Run (GCP)
- [ ] Configurar variables de entorno y secretos
- [ ] Capacitar a 2-3 asesores piloto (30 min)
- [ ] Entregar manual de uso de 1 página

**Martes - Jueves: Piloto en producción**
- [ ] Asesores usan el sistema en 100% de pedidos de las 3 categorías
- [ ] Monitoreo diario de errores y feedback
- [ ] Ajustes de prompts en caliente según casos edge
- [ ] Recopilar métricas:
  - N° de análisis realizados
  - % de parámetros detectados correctamente (validación manual)
  - Tiempo promedio de análisis por producto
  - N° de pedidos que pasaron sin reproceso

**Viernes: Análisis de resultados**
- [ ] Dashboard simple con métricas clave
- [ ] Comparar semana con sistema vs semana sin sistema:
  - Tasa de reproceso
  - Tiempo de aterrizaje de pedido
  - Satisfacción de asesores (encuesta rápida)
- [ ] Documento de resultados para tesis (3-5 páginas)

**Entregables Semana 4**:
- Sistema en producción con usuarios reales
- Métricas de impacto medidas
- Reporte de resultados del piloto
- Decisión: escalar o pivotar

---

## Estructura del Proyecto MVP

```
api-obralex-py/
├── app/
│   ├── api/
│   │   ├── health.py
│   │   └── analyze.py          # Endpoint principal
│   ├── services/
│   │   ├── llm_analyzer.py     # Lógica de análisis con Claude
│   │   └── catalog_service.py  # Manejo de catálogo
│   ├── models/
│   │   └── schemas.py          # Pydantic models
│   └── main.py
├── data/
│   └── catalog_schema.json     # 3 categorías piloto
├── static/
│   └── index.html              # Interfaz web simple
├── tests/
│   └── test_analyzer.py
├── Dockerfile
└── requirements.txt
```

## Estimación de Costos

**Claude API (Anthropic)**:
- Opus: ~$15/1M input tokens, $75/1M output tokens
- Haiku: ~$0.25/1M input tokens, $1.25/1M output tokens

**Estimado por análisis**:
- Input: ~500 tokens (prompt + catálogo + texto)
- Output: ~200 tokens (JSON estructurado)
- Costo Opus: ~$0.02 por análisis
- Costo Haiku: ~$0.0003 por análisis

**Para 1000 análisis/mes (piloto)**:
- 80% Haiku + 20% Opus = ~$5-7/mes

**GCP Cloud Run**: ~$10-15/mes (piloto con tráfico bajo)

**Total MVP**: <$25/mes

## Decisiones Técnicas Clave

### ¿Por qué LLM en lugar de NER?

| Aspecto | NER Custom | LLM con Prompting |
|---------|-----------|-------------------|
| Tiempo de setup | 2-3 semanas | 2-3 días |
| Datos necesarios | 500+ ejemplos anotados | 20-30 ejemplos |
| Flexibilidad | Rígido por entidades | Adaptable en tiempo real |
| Precisión | 90%+ (con buen dataset) | 80-85% (con buenos prompts) |
| Mantenimiento | Reentrenamiento periódico | Ajuste de prompts |

**Para MVP → LLM es ideal**. Si escala, migrar a NER en v2.

### ¿Por qué solo 3 categorías?

- Validar enfoque sin sobre-ingeniería
- Suficiente para medir impacto estadístico
- Representan ~40-50% de pedidos (cables + tuberías + cemento)
- Permite iteración rápida de prompts

### ¿Por qué interfaz manual y no webhook automático?

- Integración con N8N requiere 3-5 días adicionales
- Para MVP, lo crítico es validar **calidad del análisis**, no automatización
- Interfaz manual permite feedback directo de asesores
- Si funciona, automatizar en v2 es straightforward

## Métricas de Éxito del MVP

**Métricas primarias**:
1. **Precisión de detección**: >75% de parámetros correctos
2. **Reducción de reproceso**: -30% en categorías piloto
3. **Adopción**: >70% de asesores lo usan regularmente

**Métricas secundarias**:
4. Tiempo de análisis: <10 segundos por producto
5. Satisfacción de asesores: >4/5 en encuesta post-piloto
6. Costo por análisis: <$0.01 promedio

**Criterio de éxito para escalar**:
- 2 de 3 métricas primarias alcanzadas
- 0 incidentes críticos en semana de piloto

## Riesgos del MVP

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|------------|
| LLM alucina parámetros incorrectos | Media | Validación con reglas, output estructurado JSON |
| Asesores no adoptan la herramienta | Media | Co-diseño con 1-2 asesores, interfaz muy simple |
| Latencia alta de Claude API | Baja | Cache en memoria, fallback a Haiku |
| Categorización de Maia incorrecta | Alta | Permitir sobrescribir categoría en interfaz |
| Presupuesto API excedido | Baja | Rate limiting, alertas de costos |

## Plan de Escalamiento Post-MVP

**Si el MVP es exitoso**, roadmap siguiente:

1. **Mes 2**: Expandir a 10 categorías adicionales
2. **Mes 3**: Integración automática con N8N + webhook
3. **Mes 4**: Modelo NER personalizado para reducir costos LLM
4. **Mes 5**: Vector search para sugerencias de productos del inventario
5. **Mes 6**: Sistema de aprendizaje continuo (feedback loop)

## Entregables Finales del MVP

1. ✅ API funcionando en producción (Cloud Run)
2. ✅ Interfaz web para asesores
3. ✅ Catálogo de 3 categorías con parámetros
4. ✅ 100+ análisis reales realizados
5. ✅ Reporte de métricas de impacto
6. ✅ Código en GitHub con documentación
7. ✅ Capítulo de tesis con resultados preliminares

## Cronograma Visual

```
Semana 1: [Setup 40%] [Catálogo 60%]
Semana 2: [Prompts 30%] [Servicio LLM 40%] [Testing 30%]
Semana 3: [API 40%] [Interfaz 40%] [Firestore 20%]
Semana 4: [Deploy 10%] [Piloto 60%] [Análisis 30%]
```

**Hitos críticos**:
- Día 5: Catálogo completo
- Día 10: Precisión LLM >80%
- Día 15: Interfaz funcional
- Día 22: Primera semana de piloto completa

---

## Conclusión

Este plan MVP prioriza **velocidad de validación** sobre perfección técnica.

**Hipótesis a validar**: Un sistema basado en LLMs puede detectar parámetros faltantes con suficiente precisión para reducir reproceso en cotizaciones.

**Siguiente paso**: Si métricas son positivas → escalar con NER personalizado, automatización completa y más categorías. Si no → pivotar enfoque o ajustar prompts con más datos.
