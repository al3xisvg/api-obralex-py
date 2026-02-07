# Especificación Técnica MVP: Obralex (Versión Simplificada 4 Semanas)

## 1. Introducción

Obralex es un microservicio diseñado para identificar parámetros técnicos faltantes en solicitudes de materiales de construcción. Para el MVP, se prioriza la validación de la lógica agéntica sobre 3 categorías piloto mediante una arquitectura asíncrona basada en eventos.

## 2. Flujo de Ejecución (Arquitectura MVP)

1.  **Ingreso (API):** El endpoint `POST /api/v1/analyze` recibe: `texto_producto`, `categoria` y `subcategoria`.
2.  **Desacoplamiento (Pub/Sub):** El endpoint publica un mensaje en un Topic de Google Cloud Pub/Sub y responde de inmediato un `job_id` al cliente.
3.  **Procesamiento (Worker Cloud Run):** Un suscriptor de Pub/Sub activa el proceso del Agente en Cloud Run.
4.  **Ejecución de Tools:** El agente decide qué herramientas invocar para completar su análisis.
5.  **Persistencia (Firestore):** El resultado final (parámetros detectados, faltantes y preguntas sugeridas) se guarda en Firestore, donde Maia Web lo consume en tiempo real.

## 3. Definición de Métodos de Integración

### A. Endpoint de Entrada (FastAPI)

- **Método:** `POST /analyze`
- **Payload:** ```json

      {
      "product_text": "cable indeco 100m",
      "category": "Electricidad",
      "subcategory": "Cables"
      }

  ```

  ```

- **Acción:** Valida el esquema y publica en el topic `obralex-analysis-tasks`.

### B. El Worker Agéntico (Lógica de Tesis)

Para que el modelo actúe como un **Agente** y no solo como un transformador de texto, el Worker implementará las siguientes funciones que el LLM puede invocar:

##### B.1. `get_technical_schema(categoria, subcategoria)`

- **Propósito:** Consultar en **BigQuery** qué atributos son obligatorios (ej: diámetro, marca, color) para ese rubro específico.
- **Valor para la tesis:** Demuestra el uso de "Grounding" (anclaje) con datos estructurados de la empresa para evitar alucinaciones.

##### B.2. `validate_existing_specs(extracted_data)`

- **Propósito:** Cruza los datos que el agente extrajo del texto con los valores permitidos en el inventario.
- **Acción:** Si el usuario dijo "Cable de 10mm" y en BigQuery solo existen "6mm" o "16mm", la herramienta devuelve una alerta al agente.

##### B.3. `format_output_and_notify(analysis_result)`

- **Propósito:** Estructura el JSON final con parámetros detectados, faltantes y la pregunta sugerida para el cliente.
- **Acción:** Realiza la persistencia final en **Firestore**.

## 4. Estructura de Datos en Firestore (`material_analysis`)

Cada documento representará un análisis único para facilitar la visualización en Maia Web:

```json
{
  "job_id": "uuid-123",
  "status": "COMPLETED", // PENDING, PROCESSING, COMPLETED, ERROR
  "input": {
    "text": "cable indeco 100m",
    "category": "Electricidad"
  },
  "analysis": {
    "detected": { "marca": "Indeco", "longitud": "100m" },
    "missing": ["diametro", "tension"],
    "suggested_questions": [
      "¿De qué diámetro requiere el cable (2.5mm, 4mm, 6mm)?"
    ]
  },
  "agent_reasoning_log": "El modelo identificó la marca pero detectó ausencia de calibre según el esquema de BigQuery."
}
```

## 5. Cronograma de Implementación (4 Semanas)

- **Semana 1:** Setup de GCP (Cloud Run, Pub/Sub, BigQuery) y creación del esquema de datos piloto.
- **Semana 2:** Desarrollo del Agente con Gemini 1.5 Pro y prompts estructurados para las 3 categorías.
- **Semana 3:** Integración del flujo asíncrono (API -> Pub/Sub -> Worker) y guardado en Firestore.
- **Semana 4:** Pruebas con asesores reales en Maia Web y recolección de métricas para la tesis.
