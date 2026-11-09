# Renting Cloud: sincronización con iCloud y suscripción mensual

## Planes: gratis y suscripción (decisión del 8 nov 2026)

Hay **un solo plan de pago**, la suscripción mensual «Renting Cloud» (`com.albeasystems.renting.cloud.monthly`). **Se quitó el Pro de pago único** (`com.albeasystems.renting.pro`): la app no estaba publicada, así que nadie lo había comprado y no hay nada que conservar.

| | Gratis | Suscripción (Renting Cloud) |
|---|---|---|
| **Viviendas** | Hasta **3**, de cualquier tipo (entera, por habitaciones, temporada) | **Ilimitadas** |
| **Viviendas avanzado** | Nombre, dirección, tipo, habitaciones con su precio y gastos | Gestor o agencia con comisión (+IVA), valor de construcción y catastral, vivienda habitual del propietario |
| **Inquilinos** | Alquiler y suministros, fechas, importe de fianza y garantía adicional, devolución de la fianza, cobros | Tipo de contrato (LAU vivienda / temporada / Código Civil), duración y seguro de impago; actualización anual IRAV/IPC con su carta; control del depósito de la fianza; reducción del IRPF por contrato; **recibos de alquiler en PDF** |
| **Fiscal** | Rentas cobradas, gastos deducibles y rendimiento neto antes de reducciones, por vivienda | Amortización, reducciones, imputación de rentas por días vacíos, elegir qué gastos son deducibles, informe PDF/CSV |
| **Alertas** | En pantalla (tarjeta de Resumen con el número) | Lista completa, reglas configurables y notificaciones |
| **Anuncios** | Sí (un vídeo con premio los quita 1 h y desbloquea el informe fiscal esa hora) | No |
| **Sincronización con iCloud y copia en tu iCloud** | No (hay copia manual en un archivo, gratis) | Sí |
| Resumen, cobros, gastos, historial de ocupación, widget, copia en archivo | Sí | Sí |

- **Qué pasa si se cancela**: no se pierde ni se oculta nada. Quien tenga más de 3 viviendas las sigue viendo y editando, solo **no puede añadir más**. Los campos avanzados conservan sus valores (y las cuentas los siguen usando) pero se ven en gris y no se pueden cambiar; la sincronización se para y los datos se quedan en el dispositivo y en su iCloud. Los datos de ejemplo (6 viviendas), una copia de seguridad y lo que llegue de iCloud tampoco se recortan.
- **Cómo se ve**: lo avanzado no se esconde. Los campos salen en gris bajo una fila con candado «Incluido en la suscripción · Ver el plan», que abre el plan. Al pasar de 3 viviendas, «+» abre el plan con «El plan gratis incluye hasta 3 viviendas». En Fiscal, el plan gratis ve el rendimiento neto antes de reducciones y una tarjeta que enumera lo que añade la suscripción.
- **Código**: `Plan.swift` (límite y qué incluye cada plan), `StoreManager` es el único sitio que decide quién está suscrito (`hasCloud`; `isProUnlocked`, `isPremiumUnlocked` e `isCloudActive` son reflejos suyos que cambian juntos), `PlanGate.swift` (`SubscriberRows`, `PlanLockRow`).
- Precio de prueba: 2,99 €/mes con 7 días gratis (solo en `Renting.storekit`; el real se fija en App Store Connect). La prueba gratuita sale en el paywall solo si Apple dice que el usuario es elegible.
- **Nombre**: el plan se sigue llamando «Renting Cloud» aunque ahora incluya todo lo avanzado. Cambiarlo es solo texto (`pro.title`, `cloud.plan` y el nombre visible del producto en App Store Connect).

## Cómo funciona la sincronización

- Base de datos **privada** de CloudKit del propio usuario (contenedor `iCloud.com.albeasystems.renting`): los datos van del dispositivo al iCloud del usuario; no pasan por servidores nuestros y no podemos leerlos. Por eso la ficha de privacidad de la App Store no cambia ("datos no recopilados" por esta función).
- Un registro por vivienda, habitación, inquilino, cobro y gasto, más uno para los ajustes fiscales (`SyncModel.swift`). Cada registro lleva la entidad en JSON y la hora de su última edición.
- Conflictos: **gana la edición más reciente de cada registro**. Dos dispositivos que editan cosas distintas no chocan nunca. Depende de que los relojes de los dispositivos estén bien.
- Cada cobro tiene un id fijo (tenant + mes), para que dos dispositivos que marcan el mismo mes escriban el mismo registro y no dos.
- Motor: `CKSyncEngine` (iOS 17+): reintentos, lotes y notificaciones push. `CloudSync.swift` solo le dice qué cambió y aplica lo que llega.
- Se sincroniza solo si: el usuario lo activó, la suscripción está activa, los datos no son de ejemplo y hay cuenta de iCloud.
- Si se para (suscripción caducada, sin cuenta…): no se pierde nada; lo editado mientras tanto se sube al reanudar (se compara con una copia `base` del último estado igual al de la nube).
- Protecciones: los datos de ejemplo nunca se suben; un dispositivo sin datos propios descarga en vez de borrar la nube; un cambio de cuenta de iCloud desactiva la sincronización en vez de mezclar datos; borrar datos con la sincronización activa avisa de que se borra en todos los dispositivos; "Eliminar mis datos de iCloud" borra la zona y desactiva la sincronización.

## Lo que hay que hacer a mano (no lo puedo hacer yo)

1. **CloudKit**: crear el contenedor `iCloud.com.albeasystems.renting` (Xcode lo hace al firmar con tu equipo, o en developer.apple.com › Identifiers).
2. **Desplegar el esquema a Producción**: hacer una primera sincronización desde un dispositivo con la build de desarrollo (crea el tipo `Item` con los campos `kind`, `payload`, `modifiedAt`, `schema`) y en el CloudKit Console pulsar *Deploy Schema Changes to Production*. **TestFlight y la App Store usan Producción: sin este paso la sincronización falla allí.**
3. **App Store Connect**: crear el grupo de suscripción "Renting Cloud" con el producto `com.albeasystems.renting.cloud.monthly` (1 mes), precio, oferta introductoria si se quiere, nombre y descripción localizados (viviendas ilimitadas, herramientas avanzadas, recibos, alertas, sin anuncios y sincronización) y captura para revisión. **No hay que crear el producto de pago único.** Rellenar la URL de privacidad y de términos reales (`AppLinks`).
4. **Probar con dos dispositivos reales** con la misma cuenta de iCloud (activar, editar en uno, ver en el otro, editar offline, borrar).
5. Probar la compra con el esquema de Xcode (`Renting.storekit` ya lo incluye) o con TestFlight (sandbox).

## Qué está verificado y qué no

- Verificado (simulador): compila con los permisos de iCloud/CloudKit; la pantalla de iCloud, la confirmación al activar, el estado "sin cuenta de iCloud" (llama de verdad a `CKContainer.accountStatus()`); el paywall sin compras y con suscripción; 18 comprobaciones offline del núcleo (`-debugSyncTest 1`): ida y vuelta de 300 registros, reconstrucción, ids de cobros, cambios mínimos, borrado en cascada, ajustes fiscales, conflictos entre dos dispositivos, datos de versiones antiguas.
- **No verificado**: el viaje real a iCloud (subir, bajar, push, conflictos reales, cuota llena) y la compra real: requieren una cuenta de iCloud y de Apple en un dispositivo.
- Pendiente: las pantallas de iCloud están solo en español e inglés (el paywall y las condiciones de la suscripción sí en los 9 idiomas); compartir con copropietario o gestor (CKShare) queda fuera de la v1 por decisión del propietario del producto. Si vuelve: como la sincronización aún no está publicada, guardar cada vivienda en su propia zona de CloudKit (para compartir por vivienda) no exigiría migrar datos de nadie.

## Receta para probar la sincronización en dos dispositivos

Mismo Apple ID (con iCloud) en los dos. La app debe ser una compilación de desarrollo o de TestFlight.

**Dispositivo A (el que tiene los datos)**
1. Ajustes → toca **10 veces seguidas** la fila «Versión» (pausa máxima de 2 s entre toques): sale «Desbloqueo de prueba: suscripción activada» (activa todo lo de la suscripción). Otros 10 toques lo desactivan. Alternativa: en una ejecución desde Xcode, compra la suscripción con la configuración de StoreKit.
   Si no deja activar la sincronización, mira el bloque **«Diagnostics»** al final de la pantalla de iCloud (solo en Debug y TestFlight): cuenta de iCloud, contenedor, plan, «sample data: yes» (los datos de ejemplo nunca se suben) y el último error con su código de CloudKit.
2. Ajustes → Datos → **«Cargar ejemplo como datos reales (pruebas)»** (con la sincronización apagada). También se puede arrancar con el argumento `-debugDemoAsReal 1` desde el esquema de Xcode.
3. Ajustes → iCloud → activa la sincronización. Espera a «Al día».

**Dispositivo B (vacío)**
1. Instala la app y activa el desbloqueo de prueba (la suscripción) igual que en A.
2. **No cargues el ejemplo aquí.** Los identificadores de los datos de ejemplo se generan al azar en cada carga, así que cargarlo en los dos duplicaría la cartera. Un dispositivo sin datos propios descarga en vez de subir.
3. Ajustes → iCloud → activa la sincronización: deben aparecer las 6 viviendas, 15 inquilinos y los cobros.

**Qué probar después**
- Marcar un cobro en A y verlo en B (unos segundos; «Sincronizar ahora» fuerza la descarga).
- Editar lo mismo en los dos con un minuto de diferencia: gana la edición más reciente.
- Modo avión en B, editar, volver a conectar: el cambio sube.
- Borrar una habitación en A: desaparece en B con sus inquilinos y cobros.
- Apagar y encender la sincronización; «Eliminar mis datos de iCloud».
- Con A y B sincronizados, la primera ejecución en desarrollo habrá creado el tipo de registro en CloudKit: despliega el esquema a Producción antes de TestFlight.

El botón «Cargar ejemplo como datos reales» solo existe en compilaciones de desarrollo y TestFlight (`StoreManager.testUnlockAllowed`); en la App Store no se muestra.
