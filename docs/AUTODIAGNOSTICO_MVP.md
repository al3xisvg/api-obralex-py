# Autodiagnóstico MVP - Obralex

---

## 1. Información básica del equipo

| Campo | Detalle |
|-------|---------|
| **Nombre del proyecto** | Obralex |
| **Nombre del equipo** | Equipo Obralex (Equip Construye) |
| **Integrantes** | 3 personas (incluye al CTO de Equip Construye) |
| **Perfil del líder técnico** | CTO con +10 años de experiencia como FullStack Web/Mobile y DevOps en GCP/AWS/Azure. Actualmente cursando maestría en IA en UTEC |
| **Contexto académico** | Proyecto de tesis para Maestría en IA - UTEC, Lima, Perú |
| **Tiempo disponible** | 4 semanas (1 mes) para implementar el MVP |
| **Empresa** | Equip Construye - Marketplace B2B de venta de materiales de construcción |

---

## 2. Estado actual del prototipo

### ¿Qué demuestra bien nuestro prototipo?

El prototipo actual se encuentra en etapa inicial de desarrollo. Lo que ya está validado o funcionando es:

1. **Sistema upstream "Maia" operativo en producción**: El servicio Maia API Service ya detecta con un 95% de precisión los parámetros generales del requerimiento (RUC, correo, lugar de entrega, fecha, lista de materiales) a partir de conversaciones de WhatsApp en tiempo real.

2. **Infraestructura de datos existente**: Se cuenta con BigQuery (historial de conversaciones), Firestore (datos en tiempo real) y MongoDB Atlas (inventarios digitales) en producción.

3. **Detección de productos del cliente**: Maia ya extrae Nombre de Producto, Marca Sugerida, Unidad de Medida, Cantidad, Categoría y Subcategoría de cada producto mencionado en la conversación.

4. **Flujo operacional validado (Stage 3)**: El flujo completo desde WhatsApp hasta la cotización en Odoo ya funciona. Los asesores comerciales ya usan Maia Web Portal como herramienta diaria.

5. **Proyecto base de Obralex creado**: API FastAPI con endpoint de health check, estructura de carpetas definida y documentación técnica del plan.

### Supuestos críticos no validados

1. **Que un LLM con prompting estructurado puede detectar parámetros técnicos faltantes con >75% de precisión** sin necesidad de un modelo NER entrenado de forma personalizada.

2. **Que los asesores comerciales adoptarán la herramienta** (copiar texto del producto, pegar en Obralex y usar las preguntas sugeridas para consultar al cliente).

3. **Que las categorías/subcategorías asignadas por Maia son suficientemente precisas** para que Obralex aplique el esquema técnico correcto de parámetros obligatorios.

4. **Que 3 categorías piloto (Cables, Tuberías, Cemento) representan suficiente volumen** (~40-50% de pedidos) para medir impacto estadístico.

5. **Que la información del inventario digital actual es lo suficientemente completa** para servir como fuente de verdad (grounding) del sistema.

---

## 3. Definición del MVP

### Decisión de negocio

**Hipótesis**: Un sistema basado en LLMs puede detectar automáticamente los parámetros técnicos faltantes en las solicitudes de materiales de construcción, reduciendo el reproceso entre asesores comerciales y cotizadores en al menos un 30%.

**Problema raíz**: Los clientes envían listas de materiales con información incompleta por WhatsApp. Ejemplo: solicitan "cable eléctrico" cuando el cotizador necesita saber "cable eléctrico THW 750V 14 AWG". Esto genera ida y vuelta entre cotizador, asesor y cliente, demorando la cotización.

**Valor esperado**: Reducir tiempos de cotización y eliminar reproceso al detectar la información faltante antes de que el pedido llegue al cotizador.

### Usuario MVP

**Asesor Comercial** de Equip Construye que atiende pedidos por WhatsApp a través de la plataforma multiagente Respond.io y gestiona requerimientos desde Maia Web Portal.

- Perfil: Conoce al cliente, maneja la conversación comercial pero no tiene conocimiento técnico profundo de los materiales.
- Dolor principal: No sabe qué información técnica falta en el pedido hasta que el cotizador se lo indica (generando demora).
- Cantidad para piloto: 2-3 asesores.

### Lista de pasos del flujo mínimo end-to-end

```
1. El cliente envía un pedido por WhatsApp con su lista de materiales
2. Maia detecta los productos y sus categorías/subcategorías automáticamente
3. El asesor comercial abre Obralex (interfaz web simple)
4. El asesor copia el texto del producto desde Maia Web y lo pega en Obralex
5. El asesor selecciona la categoría/subcategoría (pre-seleccionada por Maia, editable)
6. Obralex envía el texto a la API de análisis
7. La API consulta el esquema técnico obligatorio para esa categoría/subcategoría
8. El LLM (Claude) extrae los parámetros presentes en el texto
9. El sistema cruza parámetros extraídos vs. parámetros obligatorios
10. La API retorna: parámetros detectados, parámetros faltantes, preguntas sugeridas y % de completitud
11. El asesor lee las preguntas sugeridas y se las hace al cliente por WhatsApp
12. El cliente responde con la información faltante
13. El asesor actualiza el requerimiento con la información completa
14. El requerimiento pasa al cotizador con toda la información necesaria
```

---

## 4. Definición de alcance

### ¿Qué NO es parte del MVP?

| Elemento excluido | Razón |
|-------------------|-------|
| Modelo NER personalizado (spaCy) | Requiere +500 ejemplos anotados y 2-3 semanas de entrenamiento. Se usa LLM con prompting en su lugar |
| Búsqueda semántica con embeddings (Vector DB) | Agrega complejidad sin validar primero la hipótesis central |
| Integración automática con N8N/webhook | Lo crítico es validar calidad del análisis, no la automatización. Se automatiza en v2 |
| Procesamiento de imágenes/documentos | Solo el 20% de pedidos. Se atiende primero el 70% de texto |
| Más de 3 categorías | Suficiente con Cables, Tuberías y Cemento para validar impacto (~40-50% del volumen) |
| Sistema de cache con Redis | Se usa cache en memoria para el MVP |
| A/B Testing automatizado | Se compara manualmente "semana con sistema vs semana sin sistema" |
| Feedback loop / reentrenamiento | Se implementa post-MVP si se valida la hipótesis |
| Autenticación de usuarios | API interna de uso exclusivo para asesores piloto |

### Componentes funcionales por mejorar

1. **Catálogo de parámetros técnicos**: Se necesita mapear con los cotizadores los parámetros obligatorios reales de cada subcategoría piloto. Actualmente se tiene la estructura pero no la data validada por el negocio.

2. **Dataset de ejemplos reales**: Se requiere recopilar 60-90 ejemplos reales de conversaciones de BigQuery para las 3 categorías, con anotación de parámetros completos/incompletos.

3. **Prompts del LLM**: El diseño de prompts está planteado pero no probado. Requiere iteración con datos reales hasta lograr >80% de precisión.

4. **Interfaz web**: Debe ser extremadamente simple (textarea + dropdown + botón) para maximizar adopción de los asesores.

---

## 5. Arquitectura mínima operable

### Componentes

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Asesor      │     │   Obralex API    │     │   Claude API     │
│  (Browser)   │────>│   (FastAPI en    │────>│   (Anthropic)    │
│  Interfaz    │<────│   Cloud Run)     │<────│   Opus + Haiku   │
│  HTML simple │     └────────┬─────────┘     └──────────────────┘
└──────────────┘              │
                              │
                    ┌─────────┴──────────┐
                    │                    │
              ┌─────▼──────┐     ┌──────▼──────┐
              │  Firestore  │     │  BigQuery    │
              │  (Análisis  │     │  (Esquema    │
              │  en tiempo  │     │  técnico por │
              │  real)      │     │  categoría)  │
              └─────────────┘     └─────────────┘
```

| Componente | Tecnología | Función |
|------------|-----------|---------|
| **API Backend** | FastAPI (Python) en Cloud Run | Recibe solicitudes de análisis, orquesta el flujo |
| **Motor de análisis** | Claude Opus 4.5 (Anthropic) | Extrae parámetros técnicos del texto del producto |
| **Validador rápido** | Claude Haiku (Anthropic) | Validaciones simples y verificación de coherencia |
| **Catálogo de parámetros** | Archivo JSON (catalog_schema.json) | Define parámetros obligatorios por categoría/subcategoría |
| **Persistencia de análisis** | Firestore | Almacena resultados para consumo en Maia Web |
| **Datos de inventario** | BigQuery | Fuente de verdad para esquemas técnicos y valores válidos |
| **Interfaz de usuario** | HTML + Vanilla JS (sin frameworks) | Página web donde el asesor pega texto y recibe resultados |
| **Deploy** | Docker + Cloud Run (GCP) | Hosting serverless con escalamiento automático |

### Nivel de automatización

| Paso del flujo | Nivel de automatización |
|-----------------|------------------------|
| Detección de productos en conversación | **Automático** (ya existe en Maia) |
| Ingreso de texto en Obralex | **Manual** (asesor copia y pega) |
| Selección de categoría/subcategoría | **Semi-automático** (sugerida por Maia, editable) |
| Análisis de parámetros faltantes | **Automático** (LLM + reglas) |
| Generación de preguntas sugeridas | **Automático** (LLM) |
| Consulta al cliente | **Manual** (asesor pregunta por WhatsApp) |
| Actualización del requerimiento | **Manual** (asesor marca como completo) |

---

## 6. Métrica principal de validación

### Métrica principal

**Precisión de detección de parámetros faltantes**: Porcentaje de parámetros técnicos faltantes correctamente identificados por Obralex respecto al total de parámetros que efectivamente faltaban (validado manualmente por cotizadores).

- **Meta**: >75%
- **Cómo se mide**: Al finalizar la semana de piloto, los cotizadores revisan una muestra de 50+ análisis y marcan si los parámetros faltantes identificados por Obralex eran los correctos.
- **Por qué esta métrica**: Si el sistema no detecta correctamente lo que falta, no tiene valor para el negocio. Es la métrica que valida directamente la hipótesis técnica.

### Métricas secundarias

| Métrica | Meta | Método de medición |
|---------|------|-------------------|
| Reducción de reproceso | -30% en categorías piloto | Comparar tasa de reproceso semana con sistema vs. semana anterior sin sistema |
| Adopción por asesores | >70% de uso regular | N° de análisis realizados / N° de pedidos de categorías piloto |
| Tiempo de análisis | <10 segundos por producto | Logs de latencia de la API |
| Satisfacción de asesores | >4/5 | Encuesta rápida post-piloto (5 preguntas) |
| Costo por análisis | <$0.01 promedio | Facturación de Claude API / N° total de análisis |

### Criterio de decisión para escalar

Se requiere alcanzar **2 de las 3 métricas primarias** (precisión, reducción de reproceso, adopción) y **0 incidentes críticos** durante la semana de piloto para tomar la decisión de escalar a más categorías.

---

## 7. Riesgo principal del MVP

**Riesgo**: El LLM alucina o detecta incorrectamente los parámetros técnicos, generando preguntas irrelevantes o información falsa que confunda al asesor y al cliente.

**Probabilidad**: Media

**Impacto**: Alto - Si las preguntas sugeridas son incorrectas, los asesores perderán confianza en el sistema y dejarán de usarlo. Peor aún, si el sistema indica que un pedido está "completo" cuando no lo está, se genera un reproceso que el sistema debía evitar.

**Mitigaciones**:

1. **Output JSON estructurado**: Forzar al LLM a responder solo con los parámetros del esquema definido para la categoría, limitando el espacio de alucinación.

2. **Validación con reglas**: Cruzar los valores extraídos por el LLM contra los valores válidos del inventario (ej: si dice "cable de 10mm" pero solo existen 6mm o 16mm, se alerta).

3. **Doble modelo**: Usar Claude Opus para extracción compleja y Haiku como validador de coherencia.

4. **Indicador de confianza**: Mostrar el porcentaje de completitud al asesor para que siempre revise antes de confiar ciegamente.

5. **Iteración rápida de prompts**: Ajustar prompts "en caliente" durante la semana de piloto según los errores detectados diariamente.

**Otros riesgos relevantes**:

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| Asesores no adoptan la herramienta | Media | Co-diseño con 1-2 asesores antes del piloto. Interfaz ultra-simple |
| Categorización de Maia es incorrecta | Alta | Permitir sobrescribir categoría en interfaz de Obralex |
| Latencia alta de Claude API | Baja | Cache en memoria. Fallback a Haiku si Opus demora >15s |
| Presupuesto API excedido | Baja | Rate limiting (10 prod/seg). Alertas de costo. Estimado <$25/mes |

---

## 8. Contrato del MVP

### Entregables comprometidos al finalizar las 4 semanas

| # | Entregable | Descripción |
|---|-----------|-------------|
| 1 | API funcionando en producción | API Obralex desplegada en Cloud Run (GCP) con endpoint `POST /api/v1/analyze/product` operativo |
| 2 | Interfaz web para asesores | Página HTML simple con textarea, dropdown de categoría y visualización de resultados |
| 3 | Catálogo de 3 categorías piloto | Archivo `catalog_schema.json` con parámetros obligatorios validados por cotizadores para Cables, Tuberías y Cemento |
| 4 | Dataset de pruebas | 60-90 ejemplos reales etiquetados de las 3 categorías |
| 5 | Piloto con usuarios reales | 100+ análisis realizados por 2-3 asesores durante 1 semana |
| 6 | Reporte de métricas | Documento con resultados del piloto: precisión, reproceso, adopción, tiempos, costos |
| 7 | Código documentado | Repositorio en GitHub con README, documentación de API (Swagger) y estructura limpia |

### Cronograma comprometido

| Semana | Foco | Hito clave |
|--------|------|------------|
| **Semana 1** | Setup + Catálogo de parámetros | API base desplegada. `catalog_schema.json` completo con 3 categorías |
| **Semana 2** | Motor de análisis LLM | Servicio de análisis con >80% de precisión en dataset piloto |
| **Semana 3** | API + Interfaz web + Firestore | API REST completa. Interfaz web funcional. Almacenamiento en Firestore |
| **Semana 4** | Deploy + Piloto + Métricas | Sistema en producción con usuarios reales. Reporte de resultados |

### Costos estimados

| Concepto | Costo mensual estimado |
|----------|----------------------|
| Claude API (80% Haiku + 20% Opus) | $5-7 |
| Cloud Run (GCP, tráfico bajo) | $10-15 |
| **Total MVP** | **<$25/mes** |

### Decisión post-MVP

Al finalizar la semana 4, con base en las métricas del piloto:

- **Si 2/3 métricas primarias se cumplen**: Escalar a 10+ categorías, integrar con N8N automáticamente e iniciar entrenamiento de modelo NER personalizado.
- **Si no se cumplen**: Analizar causas, ajustar prompts con más datos e iterar con nuevo piloto de 1 semana adicional antes de decidir si pivotar el enfoque.
