# Auditoría de la app (22 oct 2026)

Método: lectura del código, comprobaciones estáticas, 80 pruebas de lógica con datos construidos a mano y con la cartera de ejemplo (`-debugAudit 1`, `Renting/Core/AuditTest.swift`), tiempos con una cartera típica (6 viviendas, 18 habitaciones) y una enorme (30 viviendas, 150 habitaciones, 8.800 cobros), y comprobación de las 735 claves de traducción. Todo en el simulador; nada en un dispositivo real.

## Arreglado y verificado

| # | Problema | Cómo se vio | Arreglo |
|---|---|---|---|
| 1 | **Pérdida de datos**: si `renting.json` no se podía leer (dañado o de una versión más nueva), la app arrancaba vacía y la primera edición lo **sobrescribía** | Prueba con el archivo dañado | Se aparta como `renting-unreadable-<fecha>.json` y se avisa al usuario (comprobado en pantalla) |
| 2 | Un fallo al guardar (disco lleno) pasaba en silencio | Lectura del código | Aviso al usuario |
| 3 | **Subir la renta reescribía el historial**: al editar la renta de un inquilino, todos los meses ya cobrados pasaban a «parcial» (prueba S1b: 8 de 8) | Prueba S1b | Cada cobro guarda lo que se debía al registrarse (`rentDue`, `suppliesDue`) |
| 4 | **Rendimiento**: con 30 viviendas una pantalla del Resumen tardaba **2,2 s** (barras anuales 1 s, alertas 0,8 s) | Tiempos | 47 ms: índices por id, alertas memorizadas, comisión del gestor calculada de una vez. Con una cartera típica ya era instantáneo (3 ms) |
| 5 | **Sincronización**: un inquilino añadido en un dispositivo a una habitación borrada en otro se quedaba como fantasma y sumaba renta a los totales (5.779 € en la prueba) | Prueba S16 | Se podan los huérfanos al terminar una descarga completa |
| 6 | **Decimales**: «12,5» tecleado en una app en inglés se leía como 12 | Prueba S18 | El campo lee con los separadores del teclado del dispositivo |
| 7 | El CSV se abría mal en Excel en España (acentos rotos, columnas pegadas) | Lectura del código | Marca UTF-8, `;` y coma decimal en regiones con coma. **No lo he abierto en Excel** |
| 8 | Los círculos de cobro (la pieza central de la app) no decían nada a VoiceOver | Solo 9 etiquetas de accesibilidad en todo el código | Etiqueta en cada estado. **No probado con VoiceOver** |
| 9 | Se podía registrar una salida anterior a la entrada | Lectura del código | El selector de fecha lo impide |
| 10 | Los valores del IRAV y los topes de 2026 envejecen (el INE publica uno nuevo cada mes) | Riesgo legal | A los 40 días la app deja de sugerirlos y lo avisa |

### Segunda pasada (misma fecha, tras traducir)

| # | Problema | Cómo se vio | Arreglo |
|---|---|---|---|
| a | **Hindi: «2 de 3 viviendas» salía «3 de 2»** (`props.occupied`) | Revisión de los textos con dos marcadores sin posición | Marcadores numerados (`%1$lld`, `%2$lld`) en las 9 lenguas; el hindi ahora los invierte |
| b | **Árabe: las flechas de mes anterior/siguiente apuntaban al revés** (`chevron.left/right` no se espejan) | Captura en árabe | `chevron.backward/forward` en los 15 usos (también las flechas de «ir al detalle») |
| c | **Texto grande (Dynamic Type)**: «Col-lected / Ex-penses» partidos en el Resumen, títulos de las tarjetas de ingresos cortados («Oct 20…»), cifra principal fija en 38 pt | Capturas con tamaño de accesibilidad | En tamaños de accesibilidad el Resumen apila las columnas; la cifra principal escala (`@ScaledMetric`) en Resumen y Fiscal |
| d | **Matrices con letras de 9 pt fijas** y, con texto grande, iniciales de meses solapadas y nombres cortados | Capturas | Estilos de texto que escalan; dentro de las 4 matrices el tamaño se limita a `xxxLarge` para que no se rompa la rejilla |

Durante la verificación apareció otro fallo, ya corregido: el aviso del punto 1 **no se presentaba** (SwiftUI no muestra un aviso ya activo en el primer pintado). Ahora sale tras montar la interfaz.

### Tercera pasada (23 oct 2026, tras probar la app en un móvil)

| # | Problema | Cómo se vio | Arreglo |
|---|----------|-------------|---------|
| i | **Cobros: marcar y desmarcar no repintaba** (círculos rojo/verde y totales) | Prueba en el móvil. Después, la comprobación `S19 ticking a month tells the views…` **falla sin el arreglo y pasa con él** | Los índices por id (`@ObservationIgnored`, añadidos para el rendimiento) hacían que una vista que solo lee un cobro no se enterara de que `data` cambiaba. Cada consulta por índice registra ahora la dependencia (`observeData()`); también la caché de alertas |
| ii | **iCloud no se podía activar** | Prueba en el móvil | El interruptor estaba deshabilitado sin suscripción y un móvil sin el producto en App Store Connect no puede comprarla. Ahora el interruptor siempre responde (sin plan abre el plan) y hay un bloque «Diagnostics» (cuenta, contenedor, motor, plan, datos de ejemplo, último error con su código CloudKit). Con datos de ejemplo cargados dice, a propósito, que no sincroniza |
| iii | El desbloqueo de prueba pedía **20** toques y solo activaba Pro | Prueba en el móvil | **10** toques seguidos (pausa máxima de 2 s) activan Pro + Cloud; otros 10 lo desactivan. Solo en compilaciones Debug y TestFlight |
| iv | La notificación de fin de contrato decía «en 30 días» aunque la regla fuera de 60 | Lectura | El título lleva los días reales; avisa a la antelación elegida (90 por defecto, de 30 a 180) y otra vez a 30 días; en la app es urgente el último mes; Inquilinos muestra «Termina en N días» |
| v | Títulos de regla cortados con «…» en alemán | Captura | Pueden ocupar varias líneas |

Cambios de producto pedidos en esa prueba: carrusel de ingresos en el Resumen; historial de ocupación anualizado (botón ⓘ de Ocupación); tuerca de Ajustes siempre a la izquierda; tocar una pestaña vuelve a su primera pantalla; tipo de contrato (LAU vivienda habitual, LAU temporada u otro uso, Código Civil; duración; seguro de impago) que además decide si se aplican la actualización anual y la reducción del IRPF; fianza como un simple «Ya está depositada»; nuevo gasto «Seguro de impago». Texto en los 9 idiomas (758 claves).

**Verificado**: simulador (carrusel, historial, Cobros marcar y desmarcar, navegación y vuelta a la raíz desde 3 niveles, contrato y fianza, aviso de fin de contrato en la lista, 10 toques, pantalla de iCloud, alemán y árabe de derecha a izquierda) y `-debugAudit 1` (**104** comprobaciones, 24 nuevas) y `-debugSyncTest 1` sin fallos. **No verificado**: nada en un dispositivo real (iCloud entre dos dispositivos, compra, notificaciones).

### Cuarta pasada (23 oct 2026, segunda tanda del móvil)

Cambios pedidos: **quitar la comunidad autónoma** (la app es global), **precio y aportación de gastos por habitación al dar de alta una vivienda**, **precio de la habitación asociado al inquilino** (cuando uno se va, el precio de la habitación puede subir o bajar), y **editar vivienda, habitación e inquilino en pantalla** sin botón «Editar».

| # | Cambio | Detalle |
|---|--------|---------|
| a | Sin comunidades | Se eliminan `Region`, las reglas por comunidad y sus 24+30 textos. La fianza es un interruptor «Ya está depositada»; el plazo (30 días desde la entrada, 7–90) es la regla de alertas y es igual en todas partes. Los datos guardados con `region` se siguen leyendo (comprobado) y el campo desaparece al guardar |
| b | Precio por habitación | Alta de vivienda por habitaciones: una sección por habitación (nombre, renta, aportación de gastos); la nueva habitación copia el precio de la anterior. `Unit.listExpenses` es opcional: los datos antiguos no cambian |
| c | Precio del inquilino | El inquilino ya tenía su propia renta y gastos; ahora **nace con los de la habitación** (`Tenant.starting(in:)`) y se **copian**: subir la habitación no toca a quien ya vive allí. La ficha de la habitación muestra lo que paga cada inquilino. Comprobado con `S20` (6 pruebas) |
| d | Edición en pantalla | Vivienda, habitación e inquilino se editan directamente (`AutoSave`): se guarda a los 0,5 s de la última tecla, al salir de la pantalla, al pasar la app a segundo plano y antes de abrir una hoja que guarda el mismo registro. Un borrado no se «resucita» y no se guarda un nombre vacío. Teclados numéricos con «Hecho». Las hojas de **alta** (vivienda, habitación, inquilino) siguen con Cancelar/Guardar |

**Verificado** en el simulador: alta de una vivienda con 3 habitaciones; dirección escrita y conservada al salir sin pulsar nada; alquiler de un inquilino de 1100 a 1150 € con el total recalculado al instante y 1230 € en la lista; la habitación nueva da 400 € / 300 € al nuevo inquilino; el inquilino anterior de una habitación conserva su precio. Auditoría **108/108** y sincronización 31/31.

**No verificado**: el guardado al **pasar la app a segundo plano** y el caso de un cambio que llega de iCloud mientras se está editando (solo razonado). Tampoco la edición en el móvil real.

### Quinta pasada (8 nov 2026): widget de cobros

Nuevo widget **«Cobros del mes»** (`RentingWidget/`): cuánto alquiler ha entrado, la barra de progreso y quién debe todavía. Tamaño pequeño y mediano en la pantalla de inicio; circular, rectangular y en línea en la pantalla de bloqueo. Tocarlo abre la pestaña Cobros (`renting://collections`).

| Pieza | Cómo funciona |
|-------|---------------|
| Datos | El widget es otro proceso y no tiene la lógica de la app: la app calcula los totales y los textos (en el idioma y la moneda de la app) y los deja en un archivo del **App Group** `group.com.albeasystems.renting` (`WidgetSnapshot`). El widget solo lo dibuja |
| Cuándo se actualiza | Medio segundo después de cada cambio en los datos, al abrir la app, al pasar a segundo plano y al cambiar idioma o moneda (`WidgetBridge.refresh`). Sin abrir la app el widget cambia solo en dos momentos que ya conoce: el día en que un alquiler sin pagar pasa a «impago» y el cambio de mes (entonces pide abrir la app) |
| Privacidad | En la pantalla de bloqueo los importes y nombres se ocultan con el dispositivo bloqueado (`privacySensitive`) |
| Idiomas | Los 4 textos que escribe la app están en los 9 idiomas; el nombre y la descripción de la galería, en un catálogo propio (`RentingWidget/Localizable.xcstrings`, `tools/gen_widget_strings.py`) |

**Verificado** en el simulador: aparece en la galería de widgets, se coloca el pequeño y el mediano, muestra los datos reales, **se actualiza solo al marcar un cobro** (de 0 a 455 € y «+8» a «+7»), sigue al cambiar el idioma de la app (español, inglés y árabe de derecha a izquierda) y tocarlo abre Cobros. 13 comprobaciones nuevas (`S21`, auditoría **121/121**): totales iguales a los de Cobros, tres filas máximo, orden (impagos primero, luego quien más debe), pago parcial, el paso a «impago» sin abrir la app, fin de mes, ida y vuelta del archivo y escritura en el App Group.

**No verificado**: los widgets de la **pantalla de bloqueo** (compilan, no los he visto), el ocultado por privacidad, un widget con una cartera grande, y nada de esto en un iPhone real. En un dispositivo real hay que dar de alta el App Group en el portal de desarrolladores (Xcode lo hace solo con la firma automática y tu equipo) y el identificador `com.albeasystems.renting.widget`.

**Limitación conocida**: el widget solo sabe lo que la app le dejó. Si pasa un mes entero sin abrir la app, dirá «Abre Renting para actualizar» en lugar de inventar cifras.

### Revisión de usabilidad (8 nov 2026): primer uso de alguien nuevo

Hecha instalando la app desde cero en el simulador, siguiendo instalación → vivienda → inquilino → primer cobro, más una lectura del código. Los **5 fallos altos están arreglados y verificados** (auditoría **151/151** entonces, sincronización 31/31); los medios y menores siguen pendientes.

| # | Fallo | Arreglo | Verificado |
|---|-------|---------|-----------|
| 1 | Tres interrupciones antes de ver nada: seguimiento (ATT), consentimiento europeo y valoración con la app vacía | ATT, consentimiento y anuncios ya **no salen hasta que hay una vivienda** (después de la bienvenida). La valoración exige **datos reales** (no los de ejemplo), **3 cobros marcados** y **2 días de uso** (`ReviewManager.isEligible`) | Instalación limpia: la bienvenida sale sin avisos; el aviso de seguimiento aparece al guardar la primera vivienda; esperé más de 5 s cambiando de pestaña y no salió valoración. 5 pruebas (S23) |
| 2 | Estados vacíos sin camino | Un asistente de dos pasos (`SetupPrompt`): «Añade tu primera vivienda» → «Ahora añade un inquilino», con botón, en Resumen y Cobros. Gastos vacío lleva «Nuevo gasto». La vivienda sin inquilinos lo dice en su tarjeta y trae «Añadir el primer inquilino». Sin vivienda ya no se ven los ceros ni el anuncio de vídeo | En pantalla, los dos pasos y Gastos |
| 3 | Importes a 0 aceptados; tipo por defecto «por habitaciones» | **«Tradicional» por defecto**. El formulario del inquilino pone **Pagos** (alquiler y suministros) antes que fechas y régimen, y **no deja guardar sin alquiler**, diciendo qué falta (también sin nombre en la vivienda). Un inquilino con alquiler 0 ya no sale «Impagado»: «Falta el alquiler», y marcarlo no registra nada | En pantalla; 3 pruebas (S23) |
| 4 | Un toque borra un cobro; círculos de 14 pt | Tocar un mes ya cobrado **pregunta antes** («Se perderán el importe y la fecha anotados»), desde las tres vistas (lista, matriz anual y calendario del inquilino). La matriz anual pasa a celdas de 28 × 34 pt y el calendario del inquilino a 12 columnas con alto mínimo de 36 pt. La tira de 12 meses de la vivienda pasa a ser **solo informativa** (a ese tamaño no se puede acertar) | Confirmación vista en pantalla y cancelada sin perder el cobro; 3 pruebas (S23) |
| 5 | Sin copia de seguridad propia | **Ajustes → Copia de seguridad**: «Guardar copia en un archivo» (hoja del sistema: Archivos, Drive, AirDrop, correo…) y «Restaurar desde un archivo…». El archivo es un JSON con sobre (`app`, `format`, fecha, versión), nombre `Renting-backup-AAAA-MM-DD.json`. Restaurar pide confirmación contando lo que hay en la copia y lo que hay ahora; rechaza lo que no es de Renting, de una versión más nueva o vacío, repara registros sin padre y nunca importa como «datos de ejemplo». El archivo temporal se borra al salir. Los datos de ejemplo no se exportan. Sin iCloud, la pantalla de iCloud la ofrece como «Sin iCloud» | Exportar (hoja con el nombre correcto), restaurar la cartera de ejemplo (6 viviendas, 15 inquilinos, 224 cobros) y árabe. 17 pruebas (S22) |

**No verificado**: guardar en Archivos/Drive de verdad y elegir el archivo con el selector del sistema (en el simulador abrí la confirmación con un argumento de depuración, `-debugImport`); el aviso de seguimiento y el consentimiento en un móvil real; la valoración tras 2 días y 3 cobros (solo la regla pura); que las celdas más grandes se acierten con un dedo; VoiceOver.

**Sigue pendiente de esa revisión (medios y menores)**: borrar un gasto sin confirmación; moneda por defecto € y vocabulario fiscal de España visible en cualquier país; la ficha de una vivienda nueva mezcla gestor y datos fiscales con lo básico; «-0 €» en Fiscal; «propiedades»/«viviendas» para lo mismo; botón «Hecho» redundante sobre el teclado de texto; accesibilidad de los botones de solo icono.

### Sexta pasada (8 nov 2026): planes gratis y suscripción

Cambio de producto pedido por el propietario: lo avanzado de fiscal, inquilinos y viviendas, los recibos, las alertas, el no tener anuncios, la sincronización y las viviendas ilimitadas pasan a ser **solo de la suscripción**; el plan gratis tiene hasta 3 viviendas. Se **quitó el Pro de pago único**. Tabla completa en `docs/cloud-y-suscripcion.md`.

| Qué | Cómo se comprobó |
|---|---|
| Límite de 3 viviendas: «+» abre el plan con el motivo; las viviendas que ya había no se esconden ni se borran (datos de ejemplo de 6, copia de seguridad, suscripción caducada); aviso al final de la lista | Simulador gratis con la cartera de ejemplo: aviso al final de la lista y «+» abre el plan con «El plan gratis incluye hasta 3 viviendas». Suscrito: «+» abre el formulario. 7 pruebas (S24) |
| Inquilino: contrato, actualización de renta, fianza depositada, reducción del IRPF en gris bajo una fila con candado | Pantalla del inquilino en plan gratis (actualización de renta y contrato) |
| Vivienda: gestor y datos fiscales en gris | Código compartido con el inquilino; en suscrito el formulario de vivienda nueva sale con ambos activos |
| Fiscal gratis: rendimiento neto antes de reducciones + tarjeta de lo que añade la suscripción; suscrito: todo igual que antes | Pantalla de Fiscal en los dos planes |
| Recibos de alquiler: el PDF no se genera sin suscripción | Pantalla de recibo en plan gratis |
| Textos de Pro reescritos para la suscripción en los 9 idiomas; 13 claves nuevas comprobadas en los 9 | S17 (90 claves × 9 idiomas) |

Auditoría **158/158**, sincronización 31/31. **No verificado**: la compra real y la renovación; el paso de suscrito a gratis (solo el código y las reglas puras); los formularios de vivienda nueva y de inquilino nuevo en plan gratis (comparten código con las pantallas que sí se vieron); VoiceOver con los campos en gris; las pantallas nuevas en árabe, hindi y chino (solo los textos están comprobados).

## Lo que está bien (comprobado)

Dinero y fiscalidad: total de todas las viviendas = suma de cada vivienda cada mes (diferencia 5·10⁻¹³ €); comisión del gestor solo sobre el alquiler; días alquilados con bisiestos, solapes y extremos incluidos; imputación 1,1 % / 2 % / vivienda propia; reducción repartida por contrato; vencimientos trimestrales y anuales; actualización de renta (aniversarios perdidos, decisión «mantener»); fianza por comunidad (Madrid, Cataluña, Andalucía antes y después del 24/01/2026, sin comunidad, Ceuta); trimestres desde el 1 de enero. Sin registros huérfanos al borrar viviendas, habitaciones o inquilinos. Identificadores únicos en alertas, cargos, notificaciones y gráficos. Las 87 claves de traducción que se construyen en tiempo de ejecución existen en los 9 idiomas. Ninguna construcción que pueda tumbar la app (`try!`, `!` forzados fuera de URLs fijas).

## Pendiente, por prioridad

**Antes de enseñar la app a nadie fuera**
1. ~~Textos en inglés~~ **Resuelto** en los 9 idiomas (758 claves): 38 siguen iguales al inglés en algún idioma y son nombres propios o palabras que se escriben igual (Renting Pro/Cloud, IRAV, Madrid, Ceuta, «OK»…). Lo único traducible que queda: el nombre de archivo del PDF en árabe, hindi y chino (`receipt.file`, `letter.file`), dejado en latín a propósito para que lo abra cualquier sistema.
2. **Política de privacidad** apunta a `example.com` y el identificador de App Store es `id0000000000`: Apple rechaza la revisión así. Claves de LevelPlay y de AdMob siguen siendo marcadores.
3. **Cero pruebas en un dispositivo real**: ni la sincronización con iCloud, ni la compra, ni las notificaciones, ni VoiceOver, ni Excel, ni guardar la copia en Archivos/Drive.
4. **Calendarios no gregorianos**: con región Arabia Saudí (`ar_SA`) `Calendar.current` es el islámico y los meses y las fechas se interpretan en hégira (los datos creados con otro calendario salen en cero; lo vi en el simulador). Hay que fijar un calendario gregoriano en todo el código (hay muchas llamadas a `Calendar.current`). **No lo he cambiado.**
5. **El desbloqueo oculto y la revisión de Apple**: las compilaciones de TestFlight y de revisión llevan recibo «sandbox», y ahí el desbloqueo de 10 toques funciona. Antes de enviar a revisión hay que dejarlo inerte (`StoreManager.testUnlockAllowed` → `false` en Release).
6. **iCloud en producción**: el tipo de registro `Item` solo se crea automáticamente en el entorno de desarrollo (compilación desde Xcode). Para TestFlight o App Store hay que desplegar el esquema a Producción en el CloudKit Dashboard.

**Limitaciones conocidas de diseño**
7. La sincronización resuelve conflictos por registro entero: dos dispositivos que marcan a la vez **meses distintos como pagados del mismo gasto** (o de la comisión del gestor) pueden pisarse; gana la edición más reciente. Los cobros no sufren esto (un registro por cobro). Mitigación posible: guardar cada «gasto pagado» como registro propio.
8. El desempate usa la hora de los dispositivos: con un reloj mal puesto, gana el equivocado.
9. El dinero es `Double`: suma bien a la escala de esta app, pero no es lo ideal para contabilidad. Cambiar a céntimos enteros toca todo el modelo.
10. Las normas de 2026 (RDL 29/2026 pendiente de convalidación, plazos de fianza de varias comunidades) están escritas en el código; hay que revisarlas cada mes. Un servidor de configuración las actualizaría sin publicar versión.
11. El cálculo fiscal de una cartera enorme (30 viviendas) tarda 0,45 s al abrir la pestaña Fiscal. Con una cartera típica, 12 ms.

**Calidad**
12. No hay objetivo de pruebas XCTest: el banco de pruebas se lanza con `-debugAudit 1`. Conviene pasarlo a XCTest y ejecutarlo en cada cambio.
13. Accesibilidad: **revisados** Dynamic Type (tamaño de accesibilidad) y árabe de derecha a izquierda en Resumen, Cobros (mes y año), Gastos (año) y Fiscal (ver b–d de la segunda pasada). **Sin revisar**: contraste, VoiceOver real, el resto de pantallas (Viviendas, Inquilinos, hojas de edición, paywall) con texto grande y en árabe.
14. ~~Claves sin usar~~ Resuelto: 7 eliminadas; otras 12 (`kind.*.footer`, `rule.*.detail`) se construyen en tiempo de ejecución y están en uso.
15. ~~Marcadores sin posición~~ Resuelto (ver a de la segunda pasada); las otras 25 cadenas con varios marcadores ya eran posicionales.

## Cómo repetirla

```bash
# en el simulador (compilación Debug)
xcrun simctl launch <simulador> com.albeasystems.renting -debugAudit 1 -debugSyncTest 1 -debugDemo 1
# resultados en el contenedor de la app: tmp/audit.txt y tmp/synctest.txt
```
