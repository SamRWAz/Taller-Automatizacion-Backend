# 🎓 GUÍA MAESTRA PARA LA SUSTENTACIÓN ORAL
## Taller de Automatización de Pruebas Backend con Karate Framework

Esta guía contiene la explicación técnica y metodológica de todo lo implementado en el proyecto **TallerBackendKarate**, preparada para responder con total solvencia cualquier pregunta del docente o evaluador durante la sustentación oral (criterio 5.5 de la guía).

---

## 📌 1. Ficha Técnica del Proyecto

* **Proyecto:** Automatización de Pruebas Backend con Técnicas de Caja Negra
* **Framework:** Karate Framework `1.4.1` (no requiere *Step Definitions* en Java)
* **Runner y Aserciones:** JUnit 5 (`org.junit.jupiter.api.Test`)
* **Gestor de Construcción:** Gradle `9.2.0` (mediante Gradle Wrapper `gradlew`)
* **Entorno de Ejecución:** Java 21 LTS
* **Integración Continua:** GitHub Actions (`.github/workflows/ci.yml`) con integración bidireccional a GitHub Issues
* **Servidor Bajo Pruebas:** `https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api/`
* **Resultados Obtenidos:** 36 de 36 escenarios aprobados (100% de éxito local y en GitHub Actions)

---

## 🧠 2. Conceptos Clave que Debes Explicar

### ¿Por qué Karate Framework en lugar de Cucumber tradicional + RestAssured?
* **En Cucumber tradicional:** Cada línea de Gherkin (`Given`, `When`, `Then`) necesita una clase intermedia de Java (*Step Definitions*) con anotaciones `@Given`, `@When`, mapeo de variables y clientes HTTP como RestAssured o Apache HttpClient.
* **En Karate Framework:** Adopta la sintaxis Gherkin de Cucumber, pero **elimina por completo los Step Definitions**. Karate interpreta palabras clave nativas como `url`, `path`, `request`, `method`, `status` y `match` traduciéndolas directamente a peticiones HTTP y aserciones JSON/XML. Esto reduce el código *boilerplate*, acelera el desarrollo de pruebas y disminuye los costos de mantenimiento.

### ¿Qué hace `karate-config.js`?
* Es el archivo de inicialización que Karate ejecuta automáticamente antes de cada escenario.
* Centraliza configuraciones globales:
  * `baseUrl`: URL raíz de la API (`https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api/`).
  * `connectTimeout` y `readTimeout`: configurados en 60,000 ms (60s) para soportar el arranque en frío (*cold start*) de servidores cloud como Render.
  * `logPrettyRequest` y `logPrettyResponse`: formatean los JSON en consola para facilitar la auditoría y depuración.

### ¿Qué hace `Runner.java`?
* Es la clase que ejecuta JUnit 5.
* Utiliza `com.intuit.karate.Runner.path("classpath:features")` para escanear y ejecutar todos los `.feature`.
* Genera los reportes HTML en `target/karate-reports/karate-summary.html`.
* Activa la generación de JSON compatible con Cucumber (`outputCucumberJson(true)`).
* Incluye la aserción `assertEquals(0, results.getFailCount())` que asegura que si al menos una prueba falla, el build de Gradle falle (`BUILD FAILED`), notificando a CI/CD.

---

## 🚇 3. Bloque 1: Sistema de Control de Torniquetes en el Metro Inteligente (Transición de Estados)

### A. Modelo Teórico
La máquina de estados finitos modela el ciclo de vida del acceso al metro:
* **Estados posibles (4):**
  1. `S1 (Bloqueado)`: Estado inicial por defecto.
  2. `S2 (Autorizado)`: Torniquete desbloqueado tras validar saldo.
  3. `S3 (Girando)`: Pasajero empuja el brazo mecánico.
  4. `S4 (Mantenimiento)`: Emergencia o corte de energía.
* **Eventos (5):** `Validar Tarjeta`, `Empujar`, `Completar Giro`, `Alarma`, `Reparar`.
* **Guardias (Condiciones booleanas asociadas):**
  * `Validar Tarjeta`: Requiere `guardia: true` (Saldo Positivo). Si es `false`, se rechaza el paso.
  * `Alarma`: Requiere `guardia: true` (Falla de Energía detectada).

### B. Transiciones Válidas Implementadas
1. **S1 → S2:** Evento `Validar Tarjeta` con `guardia: true` $\rightarrow$ Acción: *"Desbloquear paso"*.
2. **S2 → S3:** Evento `Empujar` $\rightarrow$ Acción: *"Girar molinete"*.
3. **S3 → S1:** Evento `Completar Giro` $\rightarrow$ Retorno automático a bloqueado (Acción: `null`).
4. **S1 → S4:** Evento `Alarma` con `guardia: true` $\rightarrow$ Acción: *"Cortar energía"*.
5. **S2 → S4:** Evento `Alarma` con `guardia: true` $\rightarrow$ Acción: *"Cortar energía"*.
6. **S4 → S1:** Evento `Reparar` $\rightarrow$ Acción: *"Restaurar servicio"*.

### C. Estrategia de Aislamiento y Transiciones Inválidas (Pruebas Negativas)
* **Garantía de Independencia (Idempotencia):** Antes de probar un estado (`S2`, `S3`, `S4`), se ejecuta `POST torniquete/reiniciar` y helpers dinámicos (`@setupS2`, `@setupS3`, `@setupS4` marcados con `@ignore`) invocados mediante `karate.call`. Esto garantiza que los tests no dependan del orden de ejecución.
* **Escenario Negativo (`Scenario Outline`):** Se evalúan **14 combinaciones prohibidas** (por ejemplo: empujar sin pagar, validar tarjeta ya autorizada, reparar sin estar en falla, validar tarjeta con saldo negativo).
* **Aserción de seguridad:** Se valida que la API retorne `response.valida == false` y `response.estadoNuevo == estado_inicial`, comprobando que el sistema rechaza la acción y mantiene la integridad del estado.

---

## 🛸 4. Bloque 2: Sistema de Navegación de un Dron Agrícola Autónomo (Tablas de Decisión)

### A. Condiciones Evaluadas
* $C_1$: Velocidad del viento detectada supera los 40 km/h (`boolean`).
* $C_2$: Nivel de batería restante inferior al 15% (`boolean`).
* $C_3$: Sensor de proximidad detecta obstáculo imprevisto a menos de 2 metros (`boolean`).

### B. Matriz de Decisión y Jerarquía de Precedencia
El backend recibe un arreglo `valores: [C1, C2, C3]` y responde con la acción correspondiente:

| Regla | $C_1$ (Viento) | $C_2$ (Batería) | $C_3$ (Obstáculo) | Acción del Sistema | Precedencia / Razón |
| :---: | :---: | :---: | :---: | :--- | :--- |
| **R1** | `T / F` | `T / F` | **`True`** | **"Ejecutar maniobra de esquive de emergencia"** | **Prioridad Crítica:** Evitar colisión física inmediata prevalece sobre cualquier otra condición. |
| **R2** | **`True`** | `T / F` | **`False`** | **"Abortar misión y activar retorno automático (RTL)"** | Viento peligroso sin obstáculo presente. |
| **R3** | **`False`** | **`True`** | **`False`** | **"Abortar misión y activar retorno automático (RTL)"** | Batería crítica con viento calmo y sin obstáculo. |
| **R4** | **`False`** | **`False`** | **`False`** | **"Continuar ruta de vuelo planificada"** | Operación nominal: todas las condiciones son seguras. |

### C. Implementación en Karate
* **Escenarios Individuales:** Prueban cada regla de negocio de forma atómica (`@Issue-12` a `@Issue-15`).
* **Scenario Outline Exhaustivo:** Prueba las **8 combinaciones booleanas posibles ($2^3 = 8$)** garantizando 100% de cobertura de la tabla de verdad.

---

## 🏷️ 5. Trazabilidad con GitHub Issues y CI/CD

### A. ¿Cómo funciona la trazabilidad?
1. Cada escenario tiene tags:
   - Tag de Requisito: `@moduloTorniquete`, `@moduloDron`, `@req-transicion-estados`, `@req-tablas-decision`.
   - Tag de Criticidad: `@smoke`, `@smoketest`, `@regression`, `@negative`.
   - Tag de Issue: `@Issue-1` hasta `@Issue-16`.

### B. Pipeline en `.github/workflows/ci.yml`
* **Disparadores (*Triggers*):**
  * `push` / `pull_request`: Ejecuta automáticamente los tests marcados con `@smoketest`.
  * `workflow_dispatch` (Manual): Permite ingresar el tag deseado (ej. `@Issue-4` o `@Issue-16`).
* **Mecanismo de actualización automática del Issue:**
  1. El script extrae el número con la expresión regular: `if [[ $tag =~ Issue-([0-9]+) ]]`.
  2. Ejecuta el test: `./gradlew clean test ... -Dkarate.options="--tags $tag"`.
  3. Si la prueba pasa:
     - Remueve etiquetas previas `status:*`.
     - Añade la etiqueta `status:passed` (verde).
     - Publica un comentario automático con emoji ✅, timestamp y link a la corrida de Actions.
  4. Si la prueba falla:
     - Añade la etiqueta `status:failed` (rojo).
     - Publica comentario con emoji ❌ y hace fallar el job.

---

## 💡 6. Caso Real de Troubleshooting / Resolución de Problemas en QA

> **Pregunta típica del profesor:** *"¿Tuviste algún problema durante la automatización y cómo lo resolviste?"*

### El Problema: *Cold Start* en Render.com
* **Síntoma:** Al subir el código por primera vez a GitHub Actions, la prueba en CI falló con `SocketTimeoutException: Read timed out` en el primer escenario tras 21.6 segundos de espera, mientras que en la máquina local pasaba.
* **Causa Raíz:** Render.com en su plan gratuito suspende los contenedores inactivos para ahorrar recursos. Al llegar la primera petición desde el runner de GitHub en Estados Unidos, el servidor necesitó más de 20 segundos para iniciar desde cero. Como el timeout de Karate estaba configurado en 15 segundos, se venció la espera.
* **Solución de Ingeniería de Calidad:**
  1. **Aumento de Resiliencia:** Se configuraron `connectTimeout: 60000` y `readTimeout: 60000` en `karate-config.js`.
  2. **Paso de Warm-up en CI/CD:** Se añadió una tarea previa en `ci.yml` con `curl --retry 5 --retry-connrefused` que envía un ping de activación a la API antes de que Gradle comience la suite.
  3. **Resultado:** Todos los pipelines posteriores marcaron **SUCCESS (Verde ✅)**.

---

## 💻 7. Comandos Rápidos para Demostración en Vivo

Si durante la sustentación el docente te pide correr una prueba en vivo desde la terminal:

```powershell
# 1. Ubicarse en el proyecto
cd c:\Users\sambu\Desktop\2026-SegundoSemestre\Auto\TallerBackendKarate

# 2. Ejecutar toda la suite completa (36 escenarios)
.\gradlew test

# 3. Ejecutar solo el ejercicio de Torniquete
.\gradlew test "-Dkarate.options=--tags @moduloTorniquete"

# 4. Ejecutar solo el ejercicio de Dron
.\gradlew test "-Dkarate.options=--tags @moduloDron"

# 5. Ejecutar un Issue específico (ej. Issue 3 o Issue 12)
.\gradlew test "-Dkarate.options=--tags @Issue-3"

# 6. Abrir el reporte visual HTML en el navegador
Start-Process "target\karate-reports\karate-summary.html"
```
