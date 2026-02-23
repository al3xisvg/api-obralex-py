#### MI NEGOCIO

En mi Startup de Marketplace B2B de Venta de Materiales de Construcción, en Lima-Perú, llamada Equip Construye. Es así que se tiene al equipo comercial (asesores) que usa Whatsapp para recibir los pedidos de los usuarios. Cuando el pedido está realizado con la data escencial, pasa al equipo de Operaciones (cotizadores) que tienen el conocimiento ténico para analizar el pedido y cotizarlo, apoyándose en los "Inventario Digitales" donde se tiene la lista masiva de inventarios Equip y cruzarlo con los productos solicitados por el Cliente y así generar un precio total.

##### Canal de Conversación

En la empresa, se tienen un canal de Whatsapp donde se recepciona los pedidos de los clientes para cotizaciones. Por ejemplo, los usuarios nos saludan por whatsapp y envían mensajes que incluyen datos como:
a) RUC / Razón Social
b) Correo electrónico
c) Lugar de Entrega
d) Fecha de Entrega
e) Lista de Materiales
Para la Lista de Materiales (e), nos suelen escribir textos donde describen los productos que solicitan. Esto representa un 70% de pedidos, a diferencia del 20% de productos en archivos como imágenes/documentos y un 10% de conversaciones que no llegan a ningún pedido.
En ese sentido, se requiere automatizar la gestión del 70% de pedidos donde los usuarios describen lo que solicitan para una atención rápida.

##### Whatsapp API Business

Es así que, nuestro canal de Whatsapp está integrando mediante Whatsapp API Business con la **plataforma multi-agente Respond.io**, la cual nos ofrece webhooks que conectamos con N8N para almacenar todos los mensajes de entrada/salida en BigQuery (GCP) y en Firestore (Firebase).
**a) En BigQuery**, se almacena todo el mensaje entrante/saliente y sirve para obtener mediante sentencias SQL la conversación completa (desde una etiqueta de "opened", cuando el usuario nos envió el primer mensaje de apertura del chat)
**b) En Firestore**, se almacena Conversación General (celular del usuario y celular de la empresa) y los mensajes (textos). Sirve para mostrar en tiempo real todas las conversaciones en nuestro portal web llamado **Maia Web**; sin tener que estar en **Respond.io**

Sin embargo, **Maia Web** es solo un portal web y se alimenta de un servicio web llamado **Maia** que analiza la conversación (apoyándose en obtener toda la conversación desde **BigQuery**) y hacer un análisis para almacenar parámetros importantes que requiere la empresa y almacenarlos en **Firestore**. Estos parámetros son analizados en tiempo real (mediante el webhook mencionado anteriormente) y son:
a) RUC / Razón Social
b) Correo electrónico
c) Lugar de Entrega
d) Fecha de Entrega
e) Lista de Materiales

De esa forma, mientras el usuario sigue conversando con el asesor comercial, Maia analiza la conversación en tiempo real y va detecta cada parámetro disponible en la conversación.

Además, para el caso de la Lista de Materiales (e), se agregó una mejora en la cula se estructura más parámetros para detectar:
a) Nombre de Producto
b) Marca Sugerida
c) Unidad de Medida
d) Cantidad
e) Categoría
f) Subcategoría

La Categoria (e) y Subcategoría (f) se obtienen haciendo un análisis (por el momento se usa solo la API de OpenAI) con las Categorías/Subcategorías de nuestro sistema (nuestros inventarios digitales). Ahora bien, cada categoría/subcategoría en los inventarios digitales tienen parámetros obligatorios requeridos para poder estimar un costo. Por ejemplo, si se solicita un producto de la categoría Electricidad y subcategoría Cables; según los inventarios, se requiere saber el diámetro y modelo. El "Nombre de Producto" (a) de la Lista de Materiales detectada debería contar con esa información, pero no siempre lo tiene. Esto genera que el pedido aterrizado por el equipo comercial , al pasar al cotizador, requiere un reproceso para hacer las consultas necesarias y aterrizar el precio para la cotización.

##### Problema Raíz

Es decir, el principal problema es la falta de especificidad del cliente en su lista de materiales para poder cruzar correctamente el inventario que más se adecúe (por el momento queda fuera del análisis el Lugar de Entrega que también tiene otras condiciones).

##### Objetivo

Soy el CTO, llevo más de 10 años de experiencia como Web/Mobile FullStack, así como devops en GCP/AWS/Azure y estoy llevando una maestría en IA en la UTEC, por lo que para mi tesis quiero aplicar modelos NER (según he podido investigar) y/o modelos con prompting avanzado o combinación de modelos de IA (ya he usado gemini, claude, openai para crear un orquestador y juez de análisis de imágenes como método más avanzado) que me permitan obtener la información pendiente que requiere la lista de materiales para ser aterrizado. Esto con el objetivo de que el agente asesor pueda realizar las consultas y darle toda la información al cotizador
