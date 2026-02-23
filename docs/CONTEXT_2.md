## MI NEGOCIO

Soy el CTO, llevo más de 10 años de experiencia como Web/Mobile FullStack, así como devops en GCP/AWS/Azure y estoy llevando una maestría en IA en la UTEC.

En mi Startup de Marketplace B2B de Venta de Materiales de Construcción, en Lima-Perú, llamada Equip Construye. Es así que se tiene al equipo comercial (asesores) que usa Whatsapp para recibir los pedidos de los usuarios. Cuando el pedido está realizado con la data escencial, pasa al equipo de Operaciones (cotizadores) que tienen el conocimiento ténico para analizar el pedido y cotizarlo, apoyándose en los "Inventario Digitales" donde se tiene la lista masiva de inventarios Equip y cruzarlo con los productos solicitados por el Cliente y así generar un precio total.

## Canal de Conversación

En la empresa, se tienen un canal de Whatsapp donde se recepciona los pedidos de los clientes para cotizaciones. Por ejemplo, los usuarios nos saludan por whatsapp y envían mensajes que incluyen datos los cuales serán "PARÁMETROS GENERALES DEL REQUERIMIENTO" como:
a) RUC / Razón Social
b) Correo electrónico
c) Lugar de Entrega
d) Fecha de Entrega
e) Lista de Materiales
Para la Lista de Materiales (e), nos suelen escribir textos donde describen los productos que solicitan. Esto representa un 70% de pedidos, a diferencia del 20% de productos en archivos como imágenes/documentos y un 10% de conversaciones que no llegan a ningún pedido.
En ese sentido, se requiere automatizar la gestión del 70% de pedidos donde los usuarios describen lo que solicitan para una atención rápida.

## Historia de la automatización en el Canal de Conversación

#### Stage 1

Al principio, cada Asesor Comercial que atendía a los clientes tenía que usar su Whatsapp personal para poder recopilar información del pedido con los "PARÁMETROS GENERALES DEL REQUERIMIENTO" y armar la Solicitud.

- Con la información recopilada, el Asesor Comercial debía usar la app móvil llamada Argos (Expo SDK 54) para poder crear el Requerimiento
- Este requerimiento se reflejaba en el portal web "Cronos" que usan los Cotizadores para poder ver todos los pedidos clientes y sus productos a relacionar manualmente con los Inventarios Digitales de Equip Construye.
- Al finalizar el match manual entre "productos cliente - inventarios digitales", el cotizador migra el Requerimiento al portal web de Odoo
- Desde Odoo, el cotizador genera la "Cotización" y esta ultima viaja hacia Argos
- El Asesor Comercial, al tener la Cotización en su aplicación, se lo reenvía al cliente

#### Stage 2

Luego, se implementó Whatsapp API Business y se integró una plataforma de Whatsapp Multi-agente usando solo 1 número de whatsapp de la empresa Equip Construye. De esa forma, todos los Asesores Comerciales tenían una mejor manera de gestionar la información conversacional en una sola plataforma y asignarse chats

- Se repite el mismo proceso que en Stage 1

#### Stage 3 (Actual)

Al usar Whatsapp API Business, se usó un webhook que recibía cada mensaje de entrada/salida de Whatsapp, para poder reenviar dicha información a un servicio llamado "Maia Api Service"

- El Asesor Comercial conversa "naturalmente" con el Cliente
- Cada mensaje enviado/recibido por el Cliente hacia el número Whatsapp de Equip es recepcionado por "Maia Api Service"
- Maia Api Service, almacena cada mensaje en 2 bases de datos: BigQuery y Firestore
- En BigQuery, se almacena cada "apertura" de conversación, así como cada mensaje entrante/saliente y sirve para guardar todo el histórico de conversación incluyendo los "tags" cuando el usuario ha iniciado una nueva conversación
- En Firestore, se almacena cada mensaje entrante/saliente y sirve para mostrar en tiempo real los chats entre AsesorComercial-Cliente en un nuevo portal web llamado "Maia Portal Web"
- Además, en Firestore se almacena el análisis que realiza "Maia Api Service" para la detección automática de "PARÁMETROS GENERALES DEL REQUERIMIENTO" con cada nuevo mensaje entrante que llega del cliente (omite los salientes de Equip hacia el cliente)
- Un plus, es que para los "productos cliente", se logra detectar los campos de "NOMBRE DE PRODUCTO", "MARCA SUGERIDA", "UNIDAD DE MEDIDA", "CANTIDAD", "CATEGORÍA", "SUBCATEGORÍA"
- De esa forma, en "Maia Portal Web", el Asesor Comercial puede ver todos los parámetros detectados, mientras él sigue conversanco con el cliente
- Además, el Asesor Comercial tiene disponible la "Generación de Requerimiento" desde "Maia Portal Web" mediante un botón que crea automáticamente el Requerimiento con toda la información recopilada (esto ayuda a evitar ingresar manualmente cada campo , como se hace en Argos)
- Este requerimiento se refleja en el portal web "Cronos" que usan los Cotizadores para poder ver todos los pedidos clientes y sus productos a relacionar manualmente con los Inventarios Digitales de Equip Construye.
- Al finalizar el match manual entre "productos cliente - inventarios digitales", el cotizador migra el Requerimiento al portal web de Odoo
- Desde Odoo, el cotizador genera la "Cotización" y esta ultima viaja hacia Argos
- El Asesor Comercial, al tener la Cotización en su aplicación, se lo reenvía al cliente usando la plataforma de Whatsapp Multi-agente

#### El gran problema en los "PARÁMETROS GENERALES DEL REQUERIMIENTO"

Si bien "Maia Api Service" detecta en un 95% de precisión los parámetros, los cuales incluyen los productos que el cliente solicita, se tiene un gran problema con este último parámetro; y es que al tratarse del mundo de la construcción, los productos deben ser lo más específicos para poder realizar una cotización correcta. Por ejemplo, no es lo mismo solicitar "cable eléctrico", que solicitar "cable eléctrico thw 750V 14 AWG".

Es por ello, que desde el Stage 1 hasta el 3 (actual), suele haber demoras en la cotización por la falta de información para hacer match entre "productos cliente - inventarios digitales" y/o re-procesos por información ambigua según la categoría/subcategoría a la que pertenece cada "producto cliente" detectado.

En los "inventarios digitales" que maneja Equip Construye se tienen productos con N-Campos (o columnas) que lo caracterizan (dependiendo de la categoría/subcategoría). Es decir, todos los inventarios digitales tienen disponible los Campos: Color, Presentación, Tipo, Modelo, Talla, Medida, Espesor, Peso, Volumen, Ángulo, Fabricación, Fabricante, Material, Parte o Referencia; sin embargo, para la subcategoría Cable (de la categoría Electricidad), son requeridos solo Tipo, Medida, Espesor y Material; en cambio para la subcategoría Válvulas (de la categoría Tuberías, Válvulas y Conexiones), son requeridos el Modelo, Peso y Ángulo.

El cotizador no tiene comunicación con el cliente, el asesor comercial sí, es por ello que si el cotizador no tiene la información completa para cotizar, debe solicitarlo al asesor comercial, y este ultimo lo solicita al cliente. El proceso se repite hasta que el cotizador tiene toda la información para los productos. Cabe resaltar que el cotizador también puede equivocarse y no solicitar la información pendiente, lo que generará re-procesos si el cliente no recibe la cotización esperada con su pedido.

#### Stage 4 (La Tesis para la Maestría)

Para mi proyecto con mi grupo (en total somos 3 personas y tenemos solo 1 mes para implementar el MVP), por lo que se ha planteado un proyecto llamado "Obralex", el cual servirá para solucionar el gran problema en los "productos cliente" de los "PARÁMETROS GENERALES DEL REQUERIMIENTO" para poder detectar: ¿cuál es la información faltante de cada producto (según su categoría/subcategoría)?

Mis "Inventarios Digitales", se encuentran en MongoDB en un DBaaS MongoDB Atlas. Sin embargo, dicha data es cargada diariamente por el equipo de "Supply" usando un proyecto dektop (python tkinter) llamado "Adatrack" que conecta los GoogleSheets (donde están los productos de cada Proveedor aliado de Equip Construye, ya que mi startup no maneja almacenes físicos, solo alianzas con los Proveedores); por lo que, planeo implementar en "Adatrack" la conexión con BigQuery para que almacene dicha información en GCP y así aprovechar los modelos y/o agentes de IA para presentar mi MVP
