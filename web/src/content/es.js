// Spanish copy. Every other language mirrors this file key for key (content.test.js enforces it), except the
// tool pages, the tool labels and the legal pages, which exist in Spanish and English only (the rules are Spanish).
// "{app}" is replaced by SITE_NAME (site.js). Figures quoted in text are computed with engine.js (see engine.test.js).
export default {
  dir: 'ltr',
  summary: '{app} es una app para iPhone y iPad para propietarios que alquilan viviendas: alquiler tradicional, por habitaciones y de temporada. Controla los cobros por inquilino y mes, los gastos con sus vencimientos, el resumen de ingresos y beneficio, los recibos de alquiler en PDF, la actualización anual de la renta con IRAV o IPC, la fianza y una pestaña Fiscal del IRPF español (amortización del 3 %, reducciones del 50 % al 90 %, imputación por días sin alquilar). Los datos se guardan en el dispositivo; la sincronización con iCloud es opcional. Nueve idiomas. Gratis hasta 3 viviendas y con anuncios; la suscripción mensual quita el límite y los anuncios. Todavía no está publicada en la App Store. Herramienta informativa, no asesoramiento fiscal ni jurídico.',
  llms: { app: 'La app', tools: 'Herramientas gratuitas', legal: 'Legal y soporte', other: 'Otros idiomas', store: 'App Store' },
  featureList: ['Cobros por inquilino y mes, con los impagos a la vista', 'Gastos con vencimientos y marca de pagado', 'Resumen mensual, trimestral y anual', 'Recibos de alquiler en PDF (art. 17.4 LAU)', 'Actualización de la renta con IRAV o IPC y carta de notificación', 'Pestaña Fiscal del IRPF: amortización, reducciones e imputación', 'Widget de cobros del mes', 'Datos en el dispositivo y sincronización opcional con iCloud', 'Nueve idiomas'],
  ui: {
    skip: 'Saltar al contenido',
    nav: { app: 'La app', tools: 'Herramientas', plans: 'Planes', faq: 'Preguntas' },
    langLabel: 'Idioma',
    soon: 'Próximamente en la App Store',
    soonShort: 'Próximamente',
    seeApp: 'Ver la app',
    download: 'Descargar en la App Store',
    downloadShort: 'Descargar',
    tryTools: 'Probar las herramientas',
    updated: 'Actualizado',
    cta: { text: 'Estas mismas cuentas, con tus viviendas e inquilinos guardados, en tu iPhone.' },
    footer: {
      project: 'App para propietarios de viviendas en alquiler. Tus datos se quedan en tu dispositivo.',
      publisher: 'Editor', legal: 'Legal', privacy: 'Privacidad', terms: 'Términos', support: 'Soporte', languages: 'Idiomas',
      disclaimer: '{app} es una herramienta informativa. Las cifras dependen de los datos que introduces y de la normativa vigente en cada ejercicio; no son asesoramiento fiscal ni jurídico. Confirma siempre con la Agencia Tributaria o con tu asesor.',
    },
    lab: {
      currency: 'EUR',
      rentUpdate: {
        rent: 'Renta mensual actual', index: 'Índice de actualización', anniversary: 'Aniversario del contrato', notified: 'Notificación por escrito al inquilino',
        newRent: 'Renta nueva', perMonth: 'Más al mes', perYear: 'Más al año', firstMonth: 'Primer mes con la renta nueva',
        note: 'El índice lo introduces tú: consulta el IRAV del INE o el IPC que fije tu contrato.',
      },
      tax: {
        income: 'Ingresos del año por alquiler', expenses: 'Gastos deducibles del año', construction: 'Valor de construcción', months: 'Meses alquilados en el año', reduction: 'Reducción aplicable',
        none: 'Sin reducción (temporada u otro régimen)', general: '50 %: caso general', old: '60 %: contrato anterior al 26/05/2023', rehab: '60 %: rehabilitación reciente',
        young: '70 %: joven de 18 a 35 años en zona tensionada', tensioned: '90 %: bajada de renta superior al 5 % en zona tensionada',
        depreciation: 'Amortización (3 %)', net: 'Rendimiento neto', reductionAmount: 'Reducción', reduced: 'Rendimiento neto reducido',
        note: 'Una vivienda. La reducción solo se aplica a un rendimiento neto positivo. Revisa los porcentajes vigentes cada ejercicio.',
      },
      receipt: {
        landlord: 'Arrendador (nombre)', taxId: 'NIF del arrendador (opcional)', tenant: 'Inquilino', property: 'Vivienda o habitación', month: 'Mes que se paga', rent: 'Renta', utilities: 'Suministros', paidOn: 'Fecha del pago', city: 'Lugar',
        title: 'Recibo de alquiler', period: 'Periodo', concepts: 'Conceptos', rentLine: 'Renta', utilitiesLine: 'Suministros', total: 'Total pagado', received: 'Recibí del inquilino la cantidad indicada.', signature: 'Firma del arrendador',
        legal: 'Recibo conforme al artículo 17.4 de la LAU: cada concepto se detalla por separado.', print: 'Imprimir o guardar en PDF', preview: 'Vista previa', landlordLabel: 'Arrendador', tenantLabel: 'Inquilino', propertyLabel: 'Vivienda', paidLabel: 'pagado el', empty: 'Sin rellenar',
        note: 'El recibo se genera en tu navegador: los datos no se envían a ningún sitio.',
      },
    },
  },
  sections: { faq: 'Preguntas frecuentes' },
  related: { title: 'Otras herramientas' },
  home: {
    meta: {
      title: '{app}: app para caseros, cobros y renta del alquiler',
      description: 'App para iPhone para propietarios: controla quién ha pagado, los gastos de cada vivienda, los recibos de alquiler y los números de la declaración de la renta.',
    },
    h1: 'App para caseros: quién ha pagado y qué declarar.',
    lede: '{app} reúne los cobros por mes, los gastos, los recibos en PDF y los números de la renta de tus alquileres.',
    caption: 'El recorrido de un casero, captado en el simulador de iOS con la cartera de ejemplo de la app.',
    gifAlt: 'Recorrido por la app: el resumen del mes, los cobros de cada inquilino con un impago marcado, la matriz del año, un recibo de alquiler y la pestaña Fiscal.',
    app: {
      title: 'La app, pantalla a pantalla',
      lede: 'Ocho pantallas reales, captadas en el simulador de iOS con la cartera de ejemplo de la app. Las viviendas, los inquilinos y los importes son ficticios.',
      views: [
        { file: 'summary', caption: 'Resumen del mes', alt: 'Pantalla Resumen de la app con el beneficio neto del mes, lo cobrado, los gastos y lo pendiente' },
        { file: 'chart', caption: 'Ingresos frente a gastos', alt: 'Gráfica mensual de barras con los ingresos cobrados y los gastos, y la ocupación por vivienda' },
        { file: 'homes', caption: 'Viviendas y habitaciones', alt: 'Lista de viviendas con una casilla por habitación: cobrada o impagada' },
        { file: 'collections', caption: 'Cobros del mes', alt: 'Lista de inquilinos con el importe cobrado y la fecha, y los impagos marcados en rojo' },
        { file: 'year', caption: 'El año en una matriz', alt: 'Matriz de doce meses por inquilino con cada cobro marcado' },
        { file: 'receipt', caption: 'Recibo de alquiler en PDF', alt: 'Vista previa de un recibo de alquiler con la renta y los suministros en líneas separadas' },
        { file: 'expenses', caption: 'Gastos y vencimientos', alt: 'Gastos del mes con lo pagado, lo pendiente y los vencidos sin pagar' },
        { file: 'tax', caption: 'Fiscal: rendimiento neto reducido', alt: 'Pestaña Fiscal con ingresos, gastos deducibles, amortización, reducción y rendimiento neto reducido' },
      ],
    },
    ledger: {
      title: 'El cobro de cada mes, con un toque.',
      text: 'Marca cada cobro y lo que falta queda a la vista, por inquilino y por habitación. El año entero cabe en una matriz de doce meses.',
      alt: 'Matriz anual de cobros: una fila por inquilino y una columna por mes, con las casillas pagadas marcadas',
    },
    tax: {
      title: 'La renta del alquiler, calculada.',
      text: 'La pestaña Fiscal suma los ingresos, resta los gastos deducibles y la amortización del 3 %, aplica la reducción de cada contrato (50 % o 60 % según la fecha, 70 % o 90 % donde corresponda) y muestra el rendimiento neto reducido. También imputa renta por los días sin alquilar.',
      note: 'Sigue la normativa española del IRPF. Es una herramienta informativa: confirma las cifras con la Agencia Tributaria o con tu asesor.',
      alt: 'Pestaña Fiscal con el rendimiento neto reducido del año y el desglose de ingresos, gastos y reducciones',
    },
    tools: { title: 'Herramientas gratuitas', lede: 'Tres cuentas de la app, con su respuesta, su fórmula y sus preguntas. Funcionan aquí, sin registro y sin enviar tus datos.' },
    plans: {
      title: 'Qué es gratis y qué incluye la suscripción',
      lede: 'Dos planes y ninguna compra suelta.',
      rows: [
        ['Gratis', 'Hasta 3 viviendas con sus habitaciones, cobros, gastos, Resumen, widget, copia de seguridad en archivo y el rendimiento neto en Fiscal. Con anuncios.'],
        ['{app} Cloud, suscripción mensual', 'Viviendas ilimitadas, datos del gestor y del contrato, actualización con IRAV o IPC y carta, recibos en PDF, amortización y reducciones en Fiscal, exportación en PDF y CSV, alertas, sin anuncios y sincronización con iCloud. El precio se mostrará en la App Store.'],
        ['Tus datos', 'Se guardan en tu dispositivo. La sincronización con iCloud es opcional y usa tu propia cuenta de iCloud: no hay ningún servidor nuestro.'],
      ],
    },
    faq: {
      title: 'Preguntas frecuentes',
      items: [
        ['¿Qué es {app}?', '{app} es una app para iPhone y iPad para propietarios que alquilan viviendas. Controla los cobros por inquilino y mes, los gastos, los recibos de alquiler en PDF, la actualización de la renta y los números de la declaración de la renta.'],
        ['¿Para quién es?', 'Para el pequeño propietario, de una a diez viviendas, con alquiler tradicional, por habitaciones o de temporada. No es para alquiler turístico.'],
        ['¿Cuánto cuesta?', 'La descarga es gratis y permite hasta 3 viviendas, con anuncios. La suscripción mensual quita el límite y los anuncios y añade las funciones avanzadas. El precio se mostrará en la App Store; no hay compra única.'],
        ['¿Dónde se guardan mis datos?', 'En tu dispositivo. La sincronización con iCloud es opcional y funciona con tu cuenta de iCloud, no con un servidor nuestro. También puedes guardar una copia de seguridad en un archivo.'],
        ['¿Sirve fuera de España?', 'La app está en nueve idiomas y los cobros, los gastos, los recibos y el resumen valen en cualquier país. La pestaña Fiscal sigue las reglas del IRPF español.'],
        ['¿Calcula mi declaración de la renta?', 'Calcula las cifras del rendimiento de cada vivienda con la normativa española. No presenta la declaración ni sustituye a un asesor: confirma los datos con la Agencia Tributaria.'],
        ['¿Genera recibos de alquiler?', 'Sí. Crea un recibo en PDF con la renta y los suministros en líneas separadas, como pide el artículo 17.4 de la LAU. Está incluido en la suscripción.'],
        ['¿Cuándo estará en la App Store?', 'Todavía no está publicada. Cuando lo esté, esta página tendrá el enlace de descarga.'],
      ],
    },
    close: { title: 'Los alquileres, en orden.', lede: 'Aún no está en la App Store. Mientras tanto, usa las herramientas gratuitas.' },
  },
  pages: {
    'rent-update': {
      slug: 'actualizar-renta-alquiler', lab: 'rentUpdate', short: 'Actualización de la renta', blurb: 'Renta nueva con el IRAV o el IPC y el primer mes en que se cobra.',
      h1: 'Calculadora de actualización de la renta del alquiler',
      answer: 'Con una renta de 800 € y un índice del 3 %, la renta nueva es de 824 €: 24 € más al mes y 288 € más al año. Se cobra desde el mes siguiente a la notificación por escrito y nunca antes del aniversario del contrato.',
      formula: 'renta nueva = renta actual × (1 + índice / 100)',
      meta: { title: 'Calculadora de actualización de renta del alquiler | {app}', description: 'Calcula la renta nueva al actualizar un alquiler con el IRAV o el IPC y el primer mes en que se cobra. Gratis y sin registro.' },
      how: {
        title: 'Cómo se calcula',
        paras: [
          'La renta de un contrato de vivienda solo puede actualizarse una vez al año, en el aniversario, y hay que notificarlo por escrito al inquilino. La renta nueva se cobra desde el mes siguiente a esa notificación y nunca antes del aniversario (art. 18 de la LAU). La calculadora aplica el porcentaje que indicas y calcula ese primer mes.',
          'Los contratos firmados desde el 26 de mayo de 2023 se actualizan con el IRAV, el índice del INE, que actúa como límite; los anteriores, con lo pactado, normalmente el IPC. Los límites aplicables cambian con frecuencia y el INE publica un valor nuevo cada mes, por eso la calculadora no trae un porcentaje precargado: consulta el vigente antes de notificar.',
        ],
      },
      faq: [
        ['¿Cuántas veces puedo actualizar la renta?', 'Una vez al año, en el aniversario del contrato, y siempre con notificación por escrito al inquilino.'],
        ['¿Qué es el IRAV?', 'El Índice de Referencia para la Actualización Anual de los Contratos de Arrendamiento de Vivienda, que publica el INE. Se aplica a los contratos firmados desde el 26 de mayo de 2023.'],
        ['¿Desde cuándo se cobra la renta nueva?', 'Desde el mes siguiente al de la notificación por escrito, y nunca antes del aniversario del contrato.'],
        ['¿Se aplica a los alquileres de temporada?', 'No. Los contratos de temporada quedan fuera del artículo 18 de la LAU: la renta es la que pacten las partes.'],
      ],
      related: ['tax', 'receipt'],
    },
    tax: {
      slug: 'reduccion-irpf-alquiler', lab: 'tax', short: 'Rendimiento neto y reducción del IRPF', blurb: 'Ingresos, gastos, amortización del 3 % y reducción del 50 % al 90 %.',
      h1: 'Calculadora del rendimiento neto del alquiler y la reducción en el IRPF',
      answer: 'Con 12.000 € de ingresos, 3.000 € de gastos deducibles y una vivienda con 80.000 € de valor de construcción, la amortización del 3 % es de 2.400 € y el rendimiento neto es de 6.600 €. Con una reducción del 50 %, el rendimiento neto reducido que se declara es de 3.300 €.',
      formula: 'neto = ingresos − gastos − 3 % × valor de construcción · reducido = neto × (1 − reducción)',
      meta: { title: 'Rendimiento neto del alquiler y reducción en el IRPF | {app}', description: 'Calcula el rendimiento neto de una vivienda alquilada: gastos deducibles, amortización del 3 % y reducción del 50 %, 60 %, 70 % o 90 %. Gratis y sin registro.' },
      how: {
        title: 'Cómo se calcula',
        paras: [
          'El rendimiento neto de un inmueble alquilado es lo que cobras menos los gastos deducibles (comunidad, IBI, tasas, seguros, reparaciones, gestor) y menos la amortización: el 3 % anual del valor de construcción, que es el mayor entre el coste de adquisición sin el suelo y el valor catastral de la construcción. Si la vivienda se alquila solo una parte del año, gastos y amortización se prorratean por los días alquilados.',
          'Si el inmueble es la vivienda habitual del inquilino se aplica una reducción sobre el rendimiento neto positivo: 50 % en general, 60 % si el contrato es anterior al 26 de mayo de 2023 o hay rehabilitación reciente, 70 % para jóvenes de 18 a 35 años en zona tensionada y 90 % si se baja la renta más de un 5 % en zona tensionada. No se aplica a los alquileres de temporada. Es la cuenta que hace la pestaña Fiscal de la app, que además imputa renta por los días sin alquilar.',
        ],
      },
      faq: [
        ['¿Qué gastos puedo deducir?', 'Los necesarios para obtener los ingresos: comunidad, IBI, tasas, seguros, reparaciones y conservación, gestor y la amortización del inmueble. Los suministros que repercutes al inquilino tienen un tratamiento propio: consulta a la Agencia Tributaria.'],
        ['¿Qué valor uso para la amortización?', 'El mayor entre el coste de adquisición sin el suelo y el valor catastral de la construcción. La calculadora te pide ese valor de construcción directamente.'],
        ['¿La reducción se aplica a las pérdidas?', 'No. Solo se aplica a un rendimiento neto positivo.'],
        ['¿Qué pasa con los días en que la vivienda está vacía?', 'Si no es tu vivienda y no está alquilada, se imputa una renta (el 1,1 % o el 2 % del valor catastral, prorrateada por días) y no se deducen los gastos de esos días. La calculadora prorratea gastos y amortización con los meses alquilados.'],
      ],
      related: ['rent-update', 'receipt'],
    },
    receipt: {
      slug: 'recibo-de-alquiler', lab: 'receipt', short: 'Recibo de alquiler', blurb: 'Con renta y suministros desglosados, para imprimir o guardar en PDF.',
      h1: 'Recibo de alquiler para imprimir o guardar en PDF',
      answer: 'El arrendador debe entregar recibo del pago, salvo que quede acreditado por otro medio, y el recibo detalla cada concepto por separado (art. 17.4 de la LAU). Rellena los datos y obtén un recibo con la renta y los suministros desglosados, listo para imprimir o guardar en PDF.',
      formula: 'total pagado = renta + suministros',
      meta: { title: 'Recibo de alquiler para imprimir o guardar en PDF | {app}', description: 'Genera un recibo de alquiler con la renta y los suministros desglosados, como pide el artículo 17.4 de la LAU. Gratis, sin registro y sin subir tus datos.' },
      how: {
        title: 'Qué debe llevar',
        paras: [
          'El recibo identifica al arrendador, al inquilino y la vivienda, el mes que se paga, la fecha del pago y cada concepto por separado: la renta y, aparte, los suministros u otros gastos repercutidos. Así lo pide el artículo 17.4 de la LAU, salvo que el pago ya quede acreditado, por ejemplo con una transferencia.',
          'Esta herramienta rellena el recibo en tu navegador y los datos no se envían a ningún sitio. Pulsa el botón y elige Guardar como PDF en el cuadro de impresión. La app genera el mismo recibo en formato A5 desde la ficha del inquilino y lo comparte con la hoja de compartir de iOS.',
        ],
      },
      faq: [
        ['¿Es obligatorio dar recibo del alquiler?', 'El arrendador debe entregar recibo del pago, salvo que este quede acreditado, por ejemplo con una transferencia bancaria.'],
        ['¿Tiene que llevar los suministros aparte?', 'Sí. El recibo debe desglosar cada concepto y distinguir la renta de los suministros u otros gastos.'],
        ['¿Se guardan mis datos?', 'No. El recibo se genera en tu navegador y no se envía ni se guarda en ningún servidor.'],
        ['¿Sirve para el alquiler de una habitación?', 'Sí. Escribe la habitación en el campo de la vivienda.'],
      ],
      related: ['rent-update', 'tax'],
    },
  },
};
