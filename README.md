# Taller de Automatización de Pruebas Backend con Karate Framework

Proyecto de automatización de pruebas backend aplicando técnicas de diseño de pruebas de caja negra (**Transición de Estados** y **Tablas de Decisión**), implementado con **Karate Framework**, **JUnit 5**, **Gradle** y **GitHub Actions**.

---

## Resumen del Proyecto

Este repositorio contiene la implementación y automatización de al menos 10 escenarios (36 ejecuciones en total) distribuidos en los dos ejercicios seleccionados:

1. **Bloque 1 (Transición de Estados):** *Sistema de Control de Torniquetes en el Metro Inteligente*
   - Estados: `S1 (Bloqueado)`, `S2 (Autorizado)`, `S3 (Girando)`, `S4 (Mantenimiento)`.
   - Eventos: `Validar Tarjeta` (con guardia saldo), `Empujar`, `Completar Giro`, `Alarma` (con guardia falla de energía), `Reparar`.
   - Incluye transiciones válidas y un `Scenario Outline` con 14 casos negativos para validar el rechazo de transiciones inválidas.

2. **Bloque 2 (Tablas de Decisión):** *Sistema de Navegación de un Dron Agrícola Autónomo*
   - Condiciones evaluadas:
     - $C_1$: Velocidad del viento > 40 km/h.
     - $C_2$: Nivel de batería < 15%.
     - $C_3$: Sensor de proximidad lateral detecta obstáculo < 2m.
   - Acciones del sistema:
     - Esquive de emergencia ante obstáculo (Regla 1).
     - Retorno automático a base (RTL) por viento fuerte o batería baja (Reglas 2 y 3).
     - Continuar ruta de vuelo planificada con condiciones normales (Regla 4).
   - Incluye cobertura exhaustiva mediante `Scenario Outline` para la matriz completa de 8 combinaciones booleanas ($2^3$).

---

## Matriz de Trazabilidad y GitHub Issues

Cada escenario está etiquetado con su respectivo `@Issue-X` para vincularse de forma automática con los Issues del repositorio en GitHub:

| Issue | Tag Principal | Archivo Feature | Descripción de la Prueba |
| :---: | :--- | :--- | :--- |
| **#1** | `@smoke @GH-1 @Issue-1` | `torniquete.feature` | Consulta del estado actual y estructura de la máquina de estados (GET) |
| **#2** | `@smoke @GH-2 @Issue-2` | `torniquete.feature` | Reinicio del sistema al estado base S1 Bloqueado (POST) |
| **#3** | `@regression @GH-3 @Issue-3` | `torniquete.feature` | Transición válida: Validar tarjeta con saldo positivo (S1 -> S2) |
| **#4** | `@regression @GH-4 @Issue-4` | `torniquete.feature` | Transición válida: Empujar torniquete autorizado (S2 -> S3) |
| **#5** | `@regression @GH-5 @Issue-5` | `torniquete.feature` | Transición válida: Completar giro y volver a bloqueado (S3 -> S1) |
| **#6** | `@regression @GH-6 @Issue-6` | `torniquete.feature` | Transición válida: Alarma por falla desde bloqueado (S1 -> S4) |
| **#7** | `@regression @GH-7 @Issue-7` | `torniquete.feature` | Transición válida: Alarma por falla desde autorizado (S2 -> S4) |
| **#8** | `@regression @GH-8 @Issue-8` | `torniquete.feature` | Transición válida: Reparar y restaurar servicio desde mantenimiento (S4 -> S1) |
| **#9** | `@regression @negative @GH-9 @Issue-9` | `torniquete.feature` | Scenario Outline: Bloqueo de 14 transiciones no permitidas en diferentes estados |
| **#10** | `@smoke @GH-10 @Issue-10` | `dron.feature` | Consulta de la definición, condiciones y reglas del dron agrícola (GET) |
| **#11** | `@smoke @GH-11 @Issue-11` | `dron.feature` | Reinicio del historial de evaluaciones del dron (POST) |
| **#12** | `@regression @GH-12 @Issue-12` | `dron.feature` | Regla 1 (Prioridad): Maniobra de esquive de emergencia ante obstáculo imprevisto |
| **#13** | `@regression @GH-13 @Issue-13` | `dron.feature` | Regla 2: Abortar misión y retorno automático (RTL) por viento > 40 km/h |
| **#14** | `@regression @GH-14 @Issue-14` | `dron.feature` | Regla 3: Abortar misión y retorno automático (RTL) por batería < 15% |
| **#15** | `@regression @GH-15 @Issue-15` | `dron.feature` | Regla 4: Continuar ruta de vuelo planificada con condiciones normales |
| **#16** | `@regression @GH-16 @Issue-16` | `dron.feature` | Scenario Outline: Cobertura de las 8 combinaciones booleanas de la tabla de decisión |

---

## Stack Tecnológico

- **Lenguaje / Runtime:** Java 21
- **Framework de Pruebas:** Karate Framework 1.4.1
- **Motor de Ejecución:** JUnit 5 (JUnit Platform)
- **Gestor de Construcción:** Gradle 9.2.0 (con Gradle Wrapper)
- **CI/CD:** GitHub Actions (`.github/workflows/ci.yml`)

---

## Ejecución Local

### Ejecutar toda la suite de pruebas
```bash
./gradlew test
```

### Ejecutar por etiqueta (Tags)
```bash
# Ejecutar smoke tests
./gradlew test -Dkarate.options="--tags @smoke"

# Ejecutar un Issue específico (ejemplo Issue #3)
./gradlew test -Dkarate.options="--tags @Issue-3"

# Ejecutar escenarios del módulo torniquete
./gradlew test -Dkarate.options="--tags @moduloTorniquete"

# Ejecutar escenarios del módulo dron
./gradlew test -Dkarate.options="--tags @moduloDron"
```

---

## Reportes de Pruebas

Los reportes HTML generados se ubican en:
- **Karate Summary:** `target/karate-reports/karate-summary.html`
- **Cucumber JSON:** `target/karate-reports/features.<nombre>.json`

Al abrir `karate-summary.html` en el navegador es posible ver el detalle paso a paso, peticiones HTTP, headers, payloads y tiempos de respuesta.

---

## Integración Continua (GitHub Actions)

El flujo de trabajo en `.github/workflows/ci.yml` cuenta con:
1. Ejecución automática de pruebas de integración con `@smoketest` en cada `push` o `pull_request`.
2. Ejecución manual mediante `workflow_dispatch` ingresando el tag deseado (ej. `@Issue-2`).
3. Extracción automática del número de issue y actualización de estado (`status:passed` o `status:failed`) junto con un comentario del resultado y enlace a la ejecución.
