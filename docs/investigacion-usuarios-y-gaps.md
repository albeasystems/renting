# Investigación: qué piden los caseros y qué huecos puede cubrir la app

*Octubre 2026. Enfoque: pequeño propietario particular en España (1–10 viviendas, alquiler tradicional, por habitaciones y de temporada).*

## Cómo se ha hecho y con qué límites

He revisado documentación fiscal (Agencia Tributaria, consultas de la DGT), guías de consumo (OCU, idealista), normativa reciente (Ley 12/2023 de vivienda, índice IRAV, registro único de alquileres), la comunicación pública de los competidores españoles (Homming, Rentger) y reseñas de apps de EE. UU. (Landlord Studio, RentRedi, Stessa).

Límite importante: casi no hay reseñas independientes de propietarios españoles sobre estas apps. Lo que hay es sobre todo marketing de las propias empresas, así que las conclusiones sobre "demandas" se basan en obligaciones legales y fiscales, que son verificables, más que en quejas de usuarios.

## Lo que más necesita un casero particular

1. **Saber quién ha pagado y quién no, de un vistazo.** Es el núcleo de cualquier app del sector. Las americanas mejor valoradas destacan el seguimiento de rentas y los recordatorios.
2. **Preparar la declaración de la renta sin hojas de cálculo.** Homming reconoce que muchos pequeños propietarios gestionan con Excel y que su plataforma no cubre la gestión fiscal. Los usuarios de Landlord Studio piden exportar a su programa de impuestos.
3. **Controlar gastos y vencimientos** (IBI, comunidad, tasas, seguros, suministros) y saber qué está pagado.
4. **Cumplir obligaciones legales sin conocerlas de memoria:** depositar la fianza, actualizar la renta con el índice correcto, entregar recibos, registros.
5. **Tener los papeles a mano:** contrato, recibos, inventario y comunicaciones. Rentger y Homming compiten por aquí, con firma online y gestión documental.

## Lo que ya cubre la app tras esta iteración

| Necesidad | Estado |
|---|---|
| Cobros por mes y calendario de pagos/impagos | Hecho: checklist mensual, matriz anual, tira de 12 meses por habitación en cada vivienda, historial completo por inquilino y estado del mes en cada vivienda e inquilino |
| Alquiler tradicional, por habitaciones y de temporada | Hecho (la temporada se marca como no apta para la reducción del IRPF) |
| Alquiler + suministros por separado | Hecho: cada cobro guarda las dos partes; los suministros no cuentan para el gestor ni para el informe fiscal |
| Gastos mensuales, trimestrales y anuales, marcados como pagados | Hecho: un toque por vencimiento, "Marcar todo pagado", sección de vencidos sin pagar y alertas |
| Gestor a porcentaje (+ IVA opcional) | Hecho: comisión mensual calculada sobre el alquiler cobrado |
| Pestaña fiscal con gastos deducibles configurables | Hecho: por defecto comunidad, IBI, tasas y gestión; aviso si se marcan suministros; amortización del 3 %; exportación PDF/CSV (suscripción) |
| Balance de suministros (lo cobrado frente a las facturas) | Hecho (vista anual de Gastos) |
| Recibos de alquiler en PDF (LAU art. 17.4) | Hecho: A5 con renta y suministros desglosados; se comparte desde Cobros o la ficha del inquilino |
| Reducción IRPF por contrato | Hecho: automática (0 % temporada, 60 % antes del 26/05/2023, 50 % después) y editable (60 % rehabilitación, 70 %, 90 %) |
| Imputación de rentas por días vacíos | Hecho: 1,1 % / 2 % del valor catastral por días sin alquilar; los gastos y la amortización de esos días no se deducen |

## Huecos que puede cubrir (por prioridad)

### A. Fiscalidad: el gran diferenciador frente a Homming y Rentger

1. ✅ *Hecho (oct 2026).* **Reducción por alquiler de vivienda habitual.**
   - Contratos anteriores al 26/05/2023: 60 %.
   - Contratos posteriores: 50 % general, 60 % si hay rehabilitación reciente, 70 % para jóvenes de 18 a 35 años en zona tensionada y 90 % si se baja la renta más de un 5 % en zona tensionada.
   - No aplica a la temporada. La DGT exige bajar realmente la renta para el 90 % (V0540/2025).
   - **Propuesta:** un campo "fecha de contrato + supuesto" por inquilino y la línea "Rendimiento neto reducido" en la pestaña Fiscal. Es lo que más dinero ahorra al usuario.
2. ✅ *Hecho (oct 2026).* **Imputación de rentas por días sin alquilar.**
   - Por los días en que una vivienda está vacía se imputa el 1,1 % o el 2 % del valor catastral, prorrateado por días y sin deducir gastos.
   - La app ya sabe qué días ha estado vacía cada vivienda; solo falta el campo "valor catastral" (y si se revisó en los últimos 10 años).
   - Muy pocos caseros lo calculan bien.
3. **Límite de intereses + reparación y conservación.**
   - Juntos no pueden superar los ingresos de cada inmueble.
   - El exceso se arrastra 4 años (AEAT).
   - **Propuesta:** aviso y arrastre automático entre ejercicios.
4. **Copropiedad.**
   - Cada copropietario declara su porcentaje: herencias entre hermanos, matrimonios, pisos a medias.
   - **Propuesta:** % de titularidad por vivienda y un informe por titular. Es muy habitual en España y no lo resuelve ninguna app sencilla.
5. **Saldos de dudoso cobro.** Los impagos con más de 6 meses de antigüedad y reclamados pueden deducirse. La app ya tiene los impagos; bastaría con sugerirlos en el informe.
6. **Tratamiento AEAT de los suministros repercutidos.**
   - Hacienda considera ingreso lo que repercutes y gasto deducible su coste (DGT V0537/2019 y V1643/2025).
   - Ahora se excluyen ambos y el efecto neto es parecido.
   - **Propuesta:** un modo "como Hacienda" opcional para quien quiera declararlo exacto.
7. **Mobiliario y mejoras amortizables.** Se amortizan, no se deducen de golpe. No he podido verificar en fuentes oficiales el coeficiente del 10 % para el mobiliario: hay que comprobarlo antes de implementarlo.

### B. Obligaciones legales y operativa diaria

8. ✅ *Hecho (oct 2026).* **Recibos de alquiler en PDF.**
   - La LAU (art. 17.4) obliga a entregar recibo, salvo que el pago quede acreditado, por ejemplo por transferencia.
   - El recibo debe desglosar cada concepto y la renta vigente.
   - Con el desglose alquiler/suministros ya implementado, generar y enviar el recibo por WhatsApp es casi inmediato. Alto valor y poco esfuerzo.
9. **Actualización anual de la renta.**
   - Desde 2025 los contratos firmados desde el 25/05/2023 se actualizan con el IRAV del INE; los anteriores, con el IPC.
   - Hay que notificarlo por escrito con un mes de antelación.
   - **Propuesta:** calculadora y carta de notificación; la alerta de revisión ya existe.
10. **Depósito de la fianza en el organismo autonómico.**
    - Es obligatorio en casi todas las comunidades.
    - Plazos: Madrid 30 días hábiles, Comunidad Valenciana 1 mes, Cataluña 2 meses.
    - Las multas van del 5 % al 75 % de la fianza.
    - Además, es un requisito para la cobertura pública de impagos de 2025.
    - **Propuesta:** casilla "fianza depositada", fecha y alerta de plazo.
11. **Recordatorio de pago al inquilino.** Un mensaje prellenado (WhatsApp/SMS) desde un impago, con importe y mes.
12. **Documentos por inquilino:** contrato, DNI, inventario y fotos de entrada y salida, guardados en el dispositivo como el resto de datos. Esto prepara los futuros recibos y la devolución de la fianza.
13. **Temporada.**
    - Registrar el motivo y la duración del contrato, porque la causa temporal debe constar.
    - Opcional: el número de registro único (NRUA).
    - Aviso: según OCU y net2rent, el Tribunal Supremo anuló el registro en mayo de 2026. Hay que verificarlo en el BOE antes de pedirlo como obligatorio.

### C. Producto

14. **Importar desde Excel/CSV.** Muchos vienen de hojas de cálculo y empezar desde cero frena la adopción.
15. **Sincronización con iCloud y acceso compartido** (copropietario o gestor en solo lectura) sin servidor propio.
16. ✅ *Hecho (nov 2026).* **Widget de "cobros del mes"** en la pantalla de inicio y de bloqueo: el vistazo diario que piden los usuarios.

## Recomendación de próximos pasos

- **Hecho en octubre de 2026:** recibos PDF (8), reducción IRPF por contrato (1) e imputación de días vacíos (2).
- **Siguiente:** fianza y su depósito (10), actualización IRAV/IPC (9) y copropiedad (4); después, el límite de intereses + reparaciones con arrastre (3).

## Fuentes

- [AEAT – Gastos deducibles del alquiler](https://sede.agenciatributaria.gob.es/Sede/vivienda-otros-inmuebles/tributacion-arrendador-viviendas-otros-inmuebles/calculo-rendimiento-alquiler-inmueble/gastos-deducibles.html)
- [DGT V0537/2019 – suministros repercutidos (resumen)](https://www.fiscal-impuestos.com/sites/fiscal-impuestos.com/files/NFC071587.pdf) · [DGT V1643/2025](https://www.fiscal-impuestos.com/sites/fiscal-impuestos.com/files/V1643-2025.pdf)
- [La Moncloa – deducciones fiscales vivienda 2025](https://www.lamoncloa.gob.es/serviciosdeprensa/notasprensa/vivienda-agenda-urbana/paginas/2025/310325-deducciones-fiscales-vivienda.aspx) · [DGT V0540/2025](https://www.fiscal-impuestos.com/sites/fiscal-impuestos.com/files/V0540-2025.pdf)
- [OCU – reducción IRPF en alquiler de habitaciones](https://www.ocu.org/fincas-y-casas/gestion/fiscalidad/analisis/2025/07/reduccion-irpf-alquiler-habitacion) · [Primera Lectura – reducción y vivienda habitual](https://primeralecturaediciones.com/consultas/archivo/permitida-la-reduccion-del-50-prevista-en-el-articulo-23-2-lirpf-si-el-arrendamiento-de-habitaciones-acredita-su-uso-como-vivienda-habitual/)
- [OCU – periodos no alquilados](https://www.ocu.org/fincas-y-casas/gestion/fiscalidad/analisis/2021/03/irpf-expectativa-alquiler) · [Legal Today – rentas inmobiliarias 2026](https://www.legaltoday.com/practica-juridica/derecho-fiscal/fiscal/analisis-del-regimen-de-rentas-inmobiliarias-y-rendimientos-del-capital-en-el-irpf-2026-05-19/)
- [idealista – piso heredado por varios hermanos](https://www.idealista.com/news/fiscalidad/2023/04/21/805521-renta-piso-o-casa-heredada-por-varios-hermanos)
- [OCU – índice de referencia de rentas](https://www.ocu.org/vivienda-y-energia/comprar-vender-alquilar/noticias/indice-referencia-rentas-alquiler) · [Osborne Clarke – IRAV](https://www.osborneclarke.com/es/insights/nuevo-indice-de-referencia-para-la-actualizacion-anual-de-la-renta-de-contratos-de)
- [ARAG – depósito de la fianza](https://www.arag.es/assets/document/20241112_ndp_-_depositar_fianza_alquiler.pdf) · [Diari de Tarragona – cobertura de impagos](https://www.diaridetarragona.com/espana/246970/gobierno-activa-sistema-compensar-propietarios-impagos-alquiler.html)
- [idealista – recibo de alquiler](https://www.idealista.com/news/node/799755)
- [OCU – registro alquiler de temporada](https://www.ocu.org/vivienda-y-energia/comprar-vender-alquilar/informe/registro-alquiler-temporada) · [net2rent – guía registro único](https://net2rent.com/guia-registro-unico/)
- [que.es – Homming](https://www.que.es/2022/05/04/homming-penetracion-mercado-property-management/) · [Software DOIT – Rentger](https://www.softwaredoit.es/rentger/rentger.html)
- [Capterra – Landlord Studio](https://www.capterra.com/p/182473/Landlord-Studio/reviews/?page=5) · [Capterra – RentRedi](https://www.capterra.com/p/199707/RentRedi/reviews/?page=2) · [App Store – Renta Fácil](https://apps.apple.com/app/id6748422986)

*No es asesoramiento fiscal: los porcentajes y plazos deben revisarse con la normativa vigente de cada ejercicio.*
