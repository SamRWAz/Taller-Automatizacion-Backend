@moduloDron @req-tablas-decision
Feature: Sistema de Navegación de un Dron Agrícola Autónomo

  Como operador del sistema de control de vuelo agrícola
  Quiero evaluar las condiciones climáticas y operativas mediante la tabla de decisión
  Para determinar de forma autónoma si el dron debe esquivar, abortar o continuar su ruta

  Background:
    * url baseUrl
    * header Content-Type = 'application/json'
    * header Accept = 'application/json'

  @smoke @smoketest @GH-10 @Issue-10
  Scenario: Consultar definición, condiciones operativas y reglas del dron agrícola
    Given path 'decision/dron-agricola/definicion'
    When method get
    Then status 200
    And match response.nombre == 'Sistema de Navegación de un Dron Agrícola Autónomo'
    And match response.condiciones == '#[3]'
    And match response.condiciones[0] == 'Viento > 40 km/h'
    And match response.condiciones[1] == 'Batería < 15%'
    And match response.condiciones[2] == 'Obstáculo a menos de 2m'
    And match response.totalReglas == 4

  @smoke @GH-11 @Issue-11
  Scenario: Reiniciar el historial de evaluaciones del dron agrícola
    Given path 'decision/dron-agricola/reiniciar'
    When method post
    Then status 200
    And match response.ok == true

  @regression @GH-12 @Issue-12
  Scenario: Regla 1 (Prioridad Máxima) - Ejecutar maniobra de esquive de emergencia ante obstáculo imprevisto
    Given path 'decision/dron-agricola/evaluar'
    And request { valores: [false, false, true] }
    When method post
    Then status 200
    And match response.accion == 'Ejecutar maniobra de esquive de emergencia'
    And match response.reglaIndex == 0
    And match response.noDefinida == false

  @regression @GH-13 @Issue-13
  Scenario: Regla 2 - Abortar misión y retorno automático (RTL) por viento fuerte superior a 40 km/h
    Given path 'decision/dron-agricola/evaluar'
    And request { valores: [true, false, false] }
    When method post
    Then status 200
    And match response.accion == 'Abortar misión y activar retorno automático (RTL)'
    And match response.reglaIndex == 1
    And match response.noDefinida == false

  @regression @GH-14 @Issue-14
  Scenario: Regla 3 - Abortar misión y retorno automático (RTL) por batería crítica inferior al 15%
    Given path 'decision/dron-agricola/evaluar'
    And request { valores: [false, true, false] }
    When method post
    Then status 200
    And match response.accion == 'Abortar misión y activar retorno automático (RTL)'
    And match response.reglaIndex == 2
    And match response.noDefinida == false

  @regression @GH-15 @Issue-15
  Scenario: Regla 4 - Continuar ruta de vuelo planificada cuando todas las condiciones son óptimas
    Given path 'decision/dron-agricola/evaluar'
    And request { valores: [false, false, false] }
    When method post
    Then status 200
    And match response.accion == 'Continuar ruta de vuelo planificada'
    And match response.reglaIndex == 3
    And match response.noDefinida == false

  @regression @GH-16 @Issue-16
  Scenario Outline: Cobertura exhaustiva de la Tabla de Decisión (Matriz 2^3): <descripcion>
    Given path 'decision/dron-agricola/evaluar'
    And request { valores: [<viento>, <bateria>, <obstaculo>] }
    When method post
    Then status 200
    And match response.accion == <accion_esperada>
    And match response.reglaIndex == <regla_index>
    And match response.noDefinida == false

    Examples:
      | viento | bateria | obstaculo | accion_esperada                                      | regla_index | descripcion                                                                         |
      | true   | true    | true      | 'Ejecutar maniobra de esquive de emergencia'          | 0           | C1=T, C2=T, C3=T: Viento fuerte, batería baja y obstáculo (Prevalece esquive R1)   |
      | true   | false   | true      | 'Ejecutar maniobra de esquive de emergencia'          | 0           | C1=T, C2=F, C3=T: Viento fuerte y obstáculo presente (Prevalece esquive R1)        |
      | false  | true    | true      | 'Ejecutar maniobra de esquive de emergencia'          | 0           | C1=F, C2=T, C3=T: Batería baja y obstáculo presente (Prevalece esquive R1)         |
      | false  | false   | true      | 'Ejecutar maniobra de esquive de emergencia'          | 0           | C1=F, C2=F, C3=T: Únicamente obstáculo imprevisto (R1 pura)                         |
      | true   | true    | false     | 'Abortar misión y activar retorno automático (RTL)'  | 1           | C1=T, C2=T, C3=F: Viento fuerte y batería baja sin obstáculo (R2 compuesta)         |
      | true   | false   | false     | 'Abortar misión y activar retorno automático (RTL)'  | 1           | C1=T, C2=F, C3=F: Únicamente viento fuerte sin obstáculo (R2 pura)                  |
      | false  | true    | false     | 'Abortar misión y activar retorno automático (RTL)'  | 2           | C1=F, C2=T, C3=F: Batería baja sin viento ni obstáculo (R3 pura)                    |
      | false  | false   | false     | 'Continuar ruta de vuelo planificada'                | 3           | C1=F, C2=F, C3=F: Todas las condiciones normales y seguras (R4 pura)                |
