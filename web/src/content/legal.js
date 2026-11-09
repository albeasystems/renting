// Privacy, terms and support, in Spanish and English. They describe what the app does as the code stands:
// data in a local file on the device, optional iCloud sync (CloudKit, the user's private database), a home-screen
// widget fed through an App Group, local notifications, a backup file the user saves, Unity LevelPlay ads behind
// App Tracking Transparency and the Google consent form, and one auto-renewing subscription managed by Apple.
// Not reviewed by a lawyer. "{app}" is replaced by SITE_NAME (site.js).
export const legal = {
  es: {
    privacy: {
      title: 'Política de privacidad',
      description: 'Qué datos trata {app}: tus viviendas, inquilinos y cobros se guardan en tu dispositivo; la sincronización, los anuncios y la suscripción funcionan como se explica aquí.',
      updated: 'Última actualización: 9 de noviembre de 2026',
      sections: [
        ['Quién es el responsable', '{app} es una app de Albea Systems. Para cualquier duda sobre esta política escribe a albeasystems@gmail.com.'],
        ['Tus datos', '{app} no tiene cuentas de usuario. Lo que introduces (viviendas, habitaciones, inquilinos con sus nombres y datos de contacto, cobros, gastos y tus datos de arrendador para los recibos) se guarda en un archivo en tu dispositivo y no se envía a ningún servidor nuestro. Los ajustes, como el idioma o la moneda, también se guardan solo en el dispositivo. Eres responsable de los datos de terceros, como tus inquilinos, que introduces en la app.'],
        ['Sincronización con iCloud', 'Es opcional y forma parte de la suscripción. Si la activas, tus datos se copian en la base de datos privada de tu cuenta de iCloud mediante CloudKit, de Apple. Albea Systems no tiene acceso a esa base de datos ni a tu cuenta. Los datos de ejemplo nunca se sincronizan.'],
        ['Copia de seguridad en archivo', 'Puedes guardar todos tus datos en un archivo desde Ajustes y restaurarlos más tarde. El archivo lo guardas tú donde elijas; {app} no lo envía a ningún sitio.'],
        ['Widget y notificaciones', 'El widget de cobros del mes recibe del propio dispositivo un resumen de cifras a través de un contenedor compartido entre la app y el widget. Las alertas y recordatorios son notificaciones locales programadas en tu dispositivo; no usan un servidor de notificaciones nuestro.'],
        ['Anuncios', 'La versión gratuita muestra anuncios a través de Unity LevelPlay, que pone en competencia a redes publicitarias de terceros. Estas redes pueden tratar el identificador de publicidad del dispositivo, datos técnicos y datos de interacción con los anuncios para mostrarlos, limitar su frecuencia y medir su rendimiento. Los anuncios no se piden hasta que has visto la bienvenida y has creado una vivienda.', 'En iOS, el identificador de publicidad solo se usa para personalizar anuncios si autorizas el seguimiento en el aviso de App Tracking Transparency. Si no lo autorizas, los anuncios siguen apareciendo pero no se personalizan con ese identificador.', 'En el Espacio Económico Europeo y el Reino Unido, un formulario de consentimiento de Google te pide permiso antes de mostrar anuncios personalizados. Puedes revisar tu decisión en los ajustes de privacidad de la app. La suscripción elimina los anuncios.', 'Un vídeo con recompensa opcional quita los anuncios durante una hora y desbloquea la exportación fiscal durante ese tiempo.'],
        ['Suscripción', 'La suscripción mensual la gestiona Apple. Albea Systems no recibe tus datos de pago. La app solo comprueba con Apple si tienes una suscripción activa para activar las funciones.'],
        ['Tus derechos', 'Albea Systems no conserva datos personales de los usuarios de {app}. Los datos que tratan las redes publicitarias están sujetos a sus propias políticas. Si quieres ejercer tus derechos de acceso, rectificación, supresión u oposición, escríbenos y te indicaremos cómo hacerlo con cada proveedor.'],
        ['Menores', '{app} no está dirigida a niños.'],
        ['Cambios', 'Si esta política cambia, publicaremos aquí la versión nueva con su fecha.'],
      ],
    },
    terms: {
      title: 'Términos de uso',
      description: 'Condiciones de uso de la app {app} y de este sitio: herramienta informativa, plan gratuito con anuncios y suscripción mensual.',
      updated: 'Última actualización: 9 de noviembre de 2026',
      sections: [
        ['Uso de la app', '{app} es una app para iPhone y iPad para gestionar viviendas en alquiler. Se descarga gratis desde la App Store. Al usarla aceptas estos términos, además de las condiciones estándar de Apple para aplicaciones con licencia.'],
        ['Herramienta informativa', 'Las cifras que calcula {app}, incluidas las de la pestaña Fiscal y las de las herramientas de esta web, dependen de lo que introduces y de la normativa que se aplique en cada ejercicio. No son asesoramiento fiscal ni jurídico ni sustituyen a la Agencia Tributaria ni a un asesor. Los porcentajes, plazos e índices cambian: confírmalos antes de presentar una declaración o de notificar una actualización de renta.'],
        ['Planes y anuncios', '{app} es gratis hasta 3 viviendas y muestra anuncios de redes de terceros, cuyo contenido no controlamos. La suscripción mensual, que gestiona Apple y se renueva automáticamente hasta que la canceles en los ajustes de tu cuenta de Apple, quita el límite y los anuncios y añade las funciones avanzadas. Si la suscripción termina, no se borra nada de lo que ya has introducido: solo deja de poder añadirse más viviendas y las funciones avanzadas dejan de editarse.'],
        ['Tus datos', 'Eres responsable de los datos que introduces, entre ellos los de tus inquilinos, y de cumplir con la normativa de protección de datos que te corresponda como arrendador. Haz copias de seguridad: si desinstalas la app sin sincronización ni copia, los datos se pierden.'],
        ['Propiedad intelectual', '{app}, su nombre, su icono y su contenido pertenecen a Albea Systems. Puedes usar la app para tus propios fines.'],
        ['Sin garantías', 'Hacemos lo posible para que los cálculos sean correctos, pero la app y este sitio se ofrecen tal cual, sin garantías de ningún tipo. En la medida que permita la ley, Albea Systems no responde de las decisiones que tomes a partir de las cifras.'],
        ['Cambios y contacto', 'Podemos actualizar estos términos y publicaremos la versión nueva aquí. Para cualquier duda, escribe a albeasystems@gmail.com.'],
      ],
    },
    support: {
      title: 'Soporte',
      description: 'Ayuda con {app}: restaurar la suscripción, copia de seguridad, sincronización con iCloud, idioma y cómo contactarnos.',
      updated: 'Última actualización: 9 de noviembre de 2026',
      sections: [
        ['Contacto', 'Escribe a albeasystems@gmail.com con tu modelo de iPhone o iPad, la versión de iOS y qué ocurre. Respondemos lo antes posible.'],
        ['He suscrito y no se activan las funciones', 'Abre {app}, entra en Ajustes y pulsa Restaurar compras. Debes usar el mismo ID de Apple con el que te suscribiste.'],
        ['Copia de seguridad y cambio de dispositivo', 'En Ajustes, en Copia de seguridad, puedes guardar todos tus datos en un archivo y restaurarlos en otro dispositivo. Con la suscripción también puedes sincronizar con iCloud, que necesita iniciar sesión con un ID de Apple en el dispositivo.'],
        ['Cambiar el idioma o la moneda', 'En Ajustes puedes elegir el idioma de la app, entre nueve, y la moneda.'],
        ['Las cifras fiscales no coinciden con las mías', 'La pestaña Fiscal sigue la normativa española del IRPF y trabaja con los datos que has introducido. Revisa los gastos marcados como deducibles, el valor de construcción y los meses alquilados. Confirma siempre las cifras con la Agencia Tributaria o con tu asesor.'],
        ['Mis datos', 'Los datos se guardan en tu dispositivo. Si desinstalas la app sin copia de seguridad ni sincronización, se eliminan.'],
      ],
    },
  },
  en: {
    privacy: {
      title: 'Privacy policy',
      description: 'What data {app} handles: your homes, tenants and collections stay on your device; sync, ads and the subscription work as explained here.',
      updated: 'Last updated: 9 November 2026',
      sections: [
        ['Who is responsible', '{app} is an app by Albea Systems. For any question about this policy write to albeasystems@gmail.com.'],
        ['Your data', '{app} has no user accounts. What you enter (homes, rooms, tenants with their names and contact details, collections, expenses and your landlord details for receipts) is stored in a file on your device and is not sent to any server of ours. Settings such as the language or currency are also stored only on the device. You are responsible for the third-party data, such as your tenants\', that you enter in the app.'],
        ['iCloud sync', 'It is optional and part of the subscription. If you switch it on, your data is copied to the private database of your iCloud account through Apple\'s CloudKit. Albea Systems has no access to that database or to your account. Sample data is never synced.'],
        ['Backup file', 'You can save all your data to a file from Settings and restore it later. You save the file wherever you choose; {app} does not send it anywhere.'],
        ['Widget and notifications', 'The monthly collections widget receives a summary of figures from the device itself through a container shared by the app and the widget. Alerts and reminders are local notifications scheduled on your device; they do not use a notification server of ours.'],
        ['Ads', 'The free version shows ads through Unity LevelPlay, which runs an auction among third-party ad networks. These networks may process the device advertising identifier, technical device data and ad interaction data to show ads, cap their frequency and measure performance. Ads are not requested until you have seen the welcome screen and created a home.', 'On iOS the advertising identifier is used to personalise ads only if you allow tracking in the App Tracking Transparency prompt. If you do not, ads still appear but are not personalised with that identifier.', 'In the European Economic Area and the United Kingdom a Google consent form asks for your permission before personalised ads are shown. You can review your choice in the app\'s privacy settings. The subscription removes ads.', 'An optional rewarded video removes ads for one hour and unlocks the tax export for that time.'],
        ['Subscription', 'The monthly subscription is handled by Apple. Albea Systems does not receive your payment details. The app only checks with Apple whether you have an active subscription in order to switch the features on.'],
        ['Your rights', 'Albea Systems does not keep personal data about {app} users. Data handled by ad networks is subject to their own policies. If you want to exercise your rights of access, rectification, erasure or objection, write to us and we will tell you how to do it with each provider.'],
        ['Children', '{app} is not directed at children.'],
        ['Changes', 'If this policy changes we will publish the new version here with its date.'],
      ],
    },
    terms: {
      title: 'Terms of use',
      description: 'Terms for the {app} app and this site: an informational tool, a free plan with ads and a monthly subscription.',
      updated: 'Last updated: 9 November 2026',
      sections: [
        ['Using the app', '{app} is an iPhone and iPad app for managing rented homes. It is a free download from the App Store. By using it you accept these terms, in addition to Apple\'s standard terms for licensed applications.'],
        ['An informational tool', 'The figures {app} calculates, including those in the Tax tab and in the tools on this site, depend on what you enter and on the rules that apply each year. They are not tax or legal advice and do not replace the tax agency or an adviser. Percentages, deadlines and indexes change: confirm them before you file a return or give notice of a rent update.'],
        ['Plans and ads', '{app} is free for up to 3 homes and shows ads from third-party networks whose content we do not control. The monthly subscription, which Apple handles and which renews automatically until you cancel it in your Apple account settings, removes the limit and the ads and adds the advanced features. If the subscription ends, nothing you have already entered is deleted: you can no longer add more homes and the advanced fields stop being editable.'],
        ['Your data', 'You are responsible for the data you enter, including your tenants\', and for complying with the data-protection rules that apply to you as a landlord. Keep backups: if you delete the app without sync or a backup, the data is lost.'],
        ['Intellectual property', '{app}, its name, its icon and its content belong to Albea Systems. You may use the app for your own purposes.'],
        ['No warranties', 'We do our best to make the calculations correct, but the app and this site are provided as is, without warranties of any kind. To the extent the law allows, Albea Systems is not liable for the decisions you make from the figures.'],
        ['Changes and contact', 'We may update these terms and will publish the new version here. For any question write to albeasystems@gmail.com.'],
      ],
    },
    support: {
      title: 'Support',
      description: 'Help with {app}: restoring the subscription, the backup file, iCloud sync, the language and how to contact us.',
      updated: 'Last updated: 9 November 2026',
      sections: [
        ['Contact', 'Write to albeasystems@gmail.com with your iPhone or iPad model, the iOS version and what happens. We reply as soon as we can.'],
        ['I subscribed and the features are not on', 'Open {app}, go to Settings and tap Restore purchases. You must use the same Apple ID you subscribed with.'],
        ['Backup and changing device', 'In Settings, under Backup, you can save all your data to a file and restore it on another device. With the subscription you can also sync with iCloud, which needs an Apple ID signed in on the device.'],
        ['Changing the language or currency', 'In Settings you can choose the app language, from nine, and the currency.'],
        ['The tax figures do not match mine', 'The Tax tab follows Spanish income-tax rules and works with the data you entered. Check the expenses marked as deductible, the construction value and the months let. Always confirm the figures with the tax agency or your adviser.'],
        ['My data', 'The data is stored on your device. If you delete the app without a backup or sync, it is removed.'],
      ],
    },
  },
};
