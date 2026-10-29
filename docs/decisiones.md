# Decisiones de diseno y su razon

Cada decision explica que se hizo y por que, para poder defenderla.

1. **Bronze con Auto Loader y todo como texto.** Los archivos llegan en 3 formatos y a veces con columnas nuevas. Si se guardaran con tipos desde el inicio, un archivo inesperado romperia la carga. Como texto se guarda todo sin perder nada y la limpieza se hace en silver. Tambien se guarda el archivo de origen (`source_file`) para rastrear cada dato.
2. **Auto Loader en lugar de releer todo.** Solo procesa archivos nuevos. Si se vuelve a subir el mismo archivo con el mismo nombre, no se duplica.
3. **Unir los 3 formatos por nombre de columna.** El orden de las columnas cambia entre formatos, pero los nombres no. Unir por nombre evita mezclar datos.
4. **Identificador de ticket (tienda + fecha + numero de ticket).** El sistema no trae una llave unica y el numero de ticket se repite entre tiendas y dias. Sin un identificador propio no se pueden contar tickets ni calcular el ticket promedio.
5. **Monto por linea segun su tipo.** Las promociones aparecen como lineas con precio negativo y los modificadores o componentes de combo con precio cero. Si todas las lineas se sumaran igual, las ventas saldrian mal. Por eso cada linea se clasifica (`line_type`) y su monto (`line_amount`) depende de ese tipo.
6. **No usar la columna Total del punto de venta para medir ventas.** Su significado cambia entre periodos (con y sin impuesto), asi que compararla entre fechas seria enganoso. Las ventas se calculan con `line_amount`.
7. **Expectations con distinta severidad.** Una falla detiene el pipeline (falta la llave del ticket, porque sin ella no se puede seguir), una descarta filas (fecha invalida) y cuatro solo registran, para ver el problema sin perder datos.
8. **Gold como materialized views.** Son tablas ya calculadas para negocio y se actualizan de forma incremental cuando es posible, asi que el dashboard lee tablas pequenas y rapidas.
9. **Job con dos tareas dependientes.** Primero el pipeline y, solo si termina bien, la revision de calidad. Si algo falla, el Job queda en rojo y llega un correo.
10. **Trigger por llegada de archivo.** Llega un archivo por dia, asi que el Job corre solo cuando hay datos nuevos, sin depender de un horario fijo.
11. **Una ejecucion a la vez.** Evita que dos corridas se pisen si llegan varios archivos juntos.
12. **Comparacion descriptiva de promociones.** `mv_gold_promo_performance` compara cada promocion contra las 4 semanas previas y posteriores. No separa el efecto de la promocion del de la temporada, y por eso el siguiente paso es estimar el efecto real.
