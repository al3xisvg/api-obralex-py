# Plan: Esquemas de Producto desde MongoDB (categories/subcategories)

## Objetivo

Agregar `required_fields` y `field_options` a las colecciones existentes de `categories` y `subcategories` en MongoDB (mx-internal), y exponer esa metadata desde api-obralex mediante nuevos endpoints que sirvan como tools en equip-mcp-hub.

## Problema

Cuando un cliente dice "Necesito clavos y cemento", el agente necesita saber:
- **Clavos**: falta medida, tipo de proyecto, material
- **Cemento**: falta peso, tipo, cantidad

Actualmente Vertex AI Search tiene los datos del producto (`size`, `material`, etc.) pero **no tiene metadata que indique que campos son obligatorios ni que opciones validas existen**. Esa metadata debe vivir en MongoDB como parte de las colecciones de categories/subcategories que ya existen.

---

## Arquitectura

### Fuentes de datos

| Fuente | Que aporta |
|--------|-----------|
| **MongoDB** (categories/subcategories) | Esquemas: `required_fields`, `field_options` por categoria y subcategoria |
| **Vertex AI Search** (datastore productos) | Identificacion de producto: `category`, `subcategory`, `price`, `stock`, etc. |

### Flujo completo

```
Cliente (Telegram): "Necesito clavos"
    |
api-maia -> AgentService -> Gemini decide llamar get_product_schema("clavos")
    |
    v MCP tool call
equip-mcp-hub -> GET /products/schema?query=clavos -> api-obralex
    |
    v api-obralex internamente:
    1. Vertex AI Search: busca "clavos" (page_size=1)
       -> identifica category="Ferreteria", subcategory="Clavos"
    2. MongoDB: busca subcategory por name="Clavos" + categoryId
       -> obtiene required_fields + field_options
    3. Si subcategory no tiene esquema -> busca en category (fallback)
    4. Si category tampoco tiene -> retorna esquema default generico
    |
    ^ respuesta sube por la misma cadena
equip-mcp-hub <- { category, subcategory, required_fields, field_options }
    |
api-maia <- tool result -> Gemini formula preguntas al cliente
    |
Cliente recibe: "Para los clavos necesito algunos detalles. De que medida? (1", 2", 3", 4")"
```

---

## Cambios en MongoDB (mx-internal)

### Modelo actual: Categories

```typescript
// server/models/categories.ts - campos actuales
{
  order, code, name, storeBrands, keywords, alias,
  imageUrl, imageMobileUrl, isBuyer, isProvider,
  isActive, status, actionBy
}
```

### Modelo actual: Subcategories

```typescript
// server/models/subcategories.ts - campos actuales
{
  code, name, alias, imageUrl, imageMobileUrl,
  isBuyer, isProvider, isActive, status,
  categoryId (ref Categories), actionBy
}
```

### Campos nuevos a agregar

**En `subcategories` (nivel especifico):**

```typescript
// Campos nuevos
required_fields: [{ type: String }],
field_options: { type: mongoose.Schema.Types.Mixed }
```

**En `categories` (nivel fallback general):**

```typescript
// Campos nuevos
required_fields: [{ type: String }],
field_options: { type: mongoose.Schema.Types.Mixed }
```

### Ejemplo de documento Subcategory en MongoDB (despues del cambio)

```json
{
  "_id": "683a1b2c...",
  "code": "CLV",
  "name": "Clavos",
  "categoryId": "682f0a1d...",
  "isActive": true,
  "status": "active",
  "required_fields": ["medida", "tipo_proyecto", "tipo_material"],
  "field_options": {
    "medida": {
      "type": "choice",
      "options": ["1\"", "1.5\"", "2\"", "2.5\"", "3\"", "4\""],
      "question": "De que medida necesitas los clavos?"
    },
    "tipo_proyecto": {
      "type": "choice",
      "options": ["madera", "concreto", "drywall", "calamina"],
      "question": "Para que tipo de proyecto?"
    },
    "tipo_material": {
      "type": "choice",
      "options": ["acero", "galvanizado", "inoxidable"],
      "question": "De que material?"
    }
  }
}
```

### Ejemplo de documento Category en MongoDB (fallback)

```json
{
  "_id": "682f0a1d...",
  "code": "FER",
  "name": "Ferreteria",
  "isActive": true,
  "status": "active",
  "required_fields": ["tipo", "medida", "cantidad"],
  "field_options": {
    "tipo": {
      "type": "text",
      "question": "Que tipo especifico necesitas?"
    },
    "medida": {
      "type": "text",
      "question": "De que medida?"
    },
    "cantidad": {
      "type": "number",
      "unit": "unidades",
      "question": "Cuantas unidades necesitas?"
    }
  }
}
```

---

## Jerarquia de resolucion de esquemas

```
1. subcategory.required_fields  ->  si tiene datos, usar este (mas especifico)
2. category.required_fields     ->  si subcategory no tiene, usar este (general)
3. DEFAULT_SCHEMA (en codigo)   ->  ultimo recurso (especificacion + cantidad)
```

El fallback default en codigo (nivel 3) es minimo:

```python
DEFAULT_SCHEMA = {
    "required_fields": ["especificacion", "cantidad"],
    "field_options": {
        "especificacion": {
            "type": "text",
            "question": "Puedes dar mas detalles sobre lo que necesitas?"
        },
        "cantidad": {
            "type": "number",
            "unit": "unidades",
            "question": "Cuantas unidades necesitas?"
        }
    }
}
```

---

## Tipos de field_options

Cada campo en `field_options` tiene un `type` que define como el agente debe preguntar:

| type | Descripcion | Campos | Ejemplo |
|------|-------------|--------|---------|
| `choice` | Opciones predefinidas | `options`, `question` | medida: ["1\"", "2\"", "3\""] |
| `number` | Valor numerico libre | `unit`, `question` | cantidad: unit="bolsas" |
| `text` | Texto libre | `question` | color: "De que color?" |

---

## Implementacion en api-obralex-py

### Dependencia nueva

```
motor==3.x  # Cliente async de MongoDB
```

### Archivos a crear/modificar

| Archivo | Accion | Descripcion |
|---------|--------|-------------|
| `src/core/config.py` | MODIFICAR | Agregar `MONGODB_URI`, `MONGODB_DATABASE` |
| `src/db/mongodb.py` | CREAR | Conexion a MongoDB con motor (async) |
| `src/services/product_schema.py` | CREAR | Servicio que consulta MongoDB para resolver esquemas |
| `src/models/schema.py` | CREAR | Modelos Pydantic para request/response de esquemas |
| `src/api/schema.py` | CREAR | Router con endpoints de esquemas |
| `main.py` | MODIFICAR | Registrar nuevo router y lifecycle de MongoDB |

### Paso 1: Conexion a MongoDB (`src/db/mongodb.py`)

- Usa `motor.motor_asyncio.AsyncIOMotorClient`
- Conexion a la misma BD que usa mx-internal (lectura solamente)
- Se conecta al iniciar la app (lifespan) y se cierra al apagar

### Paso 2: Servicio de esquemas (`src/services/product_schema.py`)

Responsabilidades:
- `get_schema_for_query(query)`: flujo principal
  1. Busca en Vertex AI Search (1 resultado) -> obtiene `category`, `subcategory`
  2. Busca en MongoDB `subcategories` por nombre -> obtiene `required_fields`, `field_options`
  3. Si subcategory no tiene esquema -> busca en `categories`
  4. Si tampoco -> retorna DEFAULT_SCHEMA
- `get_schema_by_category(category_name)`: obtiene esquema directo de una categoria
- `get_schema_by_subcategory(subcategory_name)`: obtiene esquema directo de una subcategoria

Logica de busqueda en MongoDB:

```
# Pseudocodigo
subcategory_doc = await db.subcategories.find_one({
    "name": subcategory_name,  # match con lo que retorna Vertex AI Search
    "status": "active"
})

if subcategory_doc and subcategory_doc.get("required_fields"):
    return schema from subcategory_doc

# Fallback a category
category_doc = await db.categories.find_one({
    "name": category_name,
    "status": "active"
})

if category_doc and category_doc.get("required_fields"):
    return schema from category_doc

# Ultimo recurso
return DEFAULT_SCHEMA
```

**Nota**: La busqueda se hace por `name` (no por `_id`) porque Vertex AI Search retorna el nombre de la categoria/subcategoria como strings, no ObjectIds de MongoDB.

### Paso 3: Modelos Pydantic (`src/models/schema.py`)

```
FieldOption:
  - type: str              # "choice" | "number" | "text"
  - question: str
  - options: list[str] | None
  - unit: str | None

ProductSchemaResponse:
  - category: str | None
  - subcategory: str | None
  - product_hint: str | None    # nombre del producto encontrado en Vertex AI Search
  - required_fields: list[str]
  - field_options: dict[str, FieldOption]
  - error: str | None
```

### Paso 4: Endpoints (`src/api/schema.py`)

| Endpoint | Metodo | Input | Descripcion |
|----------|--------|-------|-------------|
| `/products/schema` | GET | `query: str` | Busca producto en Vertex AI Search, resuelve esquema desde MongoDB |
| `/categories` | GET | - | Lista categorias activas con sus required_fields |
| `/categories/{category_id}/subcategories` | GET | `category_id: str` | Lista subcategorias de una categoria con sus required_fields |

El endpoint principal (`/products/schema`) es el que usa equip-mcp-hub como tool.
Los otros dos son utiles para debug y para un futuro admin donde se puedan editar los esquemas.

---

## Cambios en mx-internal-ts

| Archivo | Accion | Descripcion |
|---------|--------|-------------|
| `server/models/categories.ts` | MODIFICAR | Agregar `required_fields` y `field_options` al schema |
| `server/models/subcategories.ts` | MODIFICAR | Agregar `required_fields` y `field_options` al schema |

Solo se agregan campos opcionales al schema de Mongoose. No rompe nada existente porque los documentos actuales simplemente no tendran esos campos (se resuelven como `undefined`/`[]`).

---

## Datos iniciales para el MVP

Subcategorias a poblar con required_fields y field_options:

| Categoria | Subcategoria | required_fields |
|-----------|-------------|-----------------|
| Ferreteria | Clavos | medida, tipo_proyecto, tipo_material |
| Ferreteria | Tornillos | medida, tipo_cabeza, tipo_material |
| Materiales | Cemento | peso, tipo, cantidad |
| Materiales | Arena | tipo, cantidad |
| Materiales | Ladrillos | tipo, medida, cantidad |
| Fierros | Fierro corrugado | diametro, longitud, cantidad |
| Pinturas | Pintura | tipo, color, cantidad |

**Total: 4 categorias, 7 subcategorias para el MVP.**

Se pueden poblar con un script de migracion o manualmente desde mx-internal.

---

## Agregar nuevas categorias/subcategorias en el futuro

1. Desde mx-internal (o directamente en MongoDB), editar la subcategoria y agregar `required_fields` + `field_options`
2. No requiere cambios en api-obralex-py, equip-mcp-hub, ni api-maia-py
3. El agente automaticamente usara el nuevo esquema la proxima vez que un cliente pida ese producto

---

## Dependencias entre proyectos

```
mx-internal-ts     -> Agrega campos al modelo + UI para editar esquemas (futuro)
                       (MongoDB es la fuente de verdad)
        |
        v
api-obralex-py     -> Lee MongoDB (motor) + Vertex AI Search
                       Expone GET /products/schema
        |
        v
equip-mcp-hub      -> Tool get_product_schema que llama a api-obralex
        |
        v
api-maia-py        -> Agente usa el tool para saber que preguntar
```

## Variables de entorno nuevas en api-obralex-py

```env
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/
MONGODB_DATABASE=nombre_bd
```
