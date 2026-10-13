@moduloTorniquete @req-transicion-estados
Feature: Sistema de Control de Torniquetes en el Metro Inteligente

  Como sistema central de control de acceso del metro
  Quiero gestionar las transiciones de estado del torniquete según los eventos de usuarios y sensores
  Para garantizar el flujo seguro de pasajeros y la respuesta ante emergencias

  Background:
    * url baseUrl
    * header Content-Type = 'application/json'
    * header Accept = 'application/json'

  @ignore @setupS2
  Scenario: Helper para transitar a S2 Autorizado
    Given path 'torniquete/evento'
    And request { evento: 'Validar Tarjeta', guardia: true }
    When method post
    Then status 200

  @ignore @setupS3
  Scenario: Helper para transitar a S3 Girando
    Given path 'torniquete/evento'
    And request { evento: 'Validar Tarjeta', guardia: true }
    When method post
    Then status 200
    Given path 'torniquete/evento'
    And request { evento: 'Empujar' }
    When method post
    Then status 200

  @ignore @setupS4
  Scenario: Helper para transitar a S4 Mantenimiento
    Given path 'torniquete/evento'
    And request { evento: 'Alarma', guardia: true }
    When method post
    Then status 200

  @smoke @smoketest @GH-1 @Issue-1
  Scenario: Consultar estado actual del torniquete del metro
    Given path 'torniquete/estado'
    When method get
    Then status 200
    And match response.estadoActual == '#string'
    And match response.maquina.estados == '#[4]'
    And match response.maquina.eventos == '#[5]'

  @smoke @GH-2 @Issue-2
  Scenario: Reiniciar el estado del torniquete al estado inicial S1 Bloqueado
    Given path 'torniquete/reiniciar'
    When method post
    Then status 200
    And match response.estadoActual == 'S1 (Bloqueado)'

  @regression @GH-3 @Issue-3
  Scenario: Transición válida: Validar tarjeta con saldo positivo (S1 Bloqueado -> S2 Autorizado)
    Given path 'torniquete/reiniciar'
    When method post
    Then status 200
    Given path 'torniquete/evento'
    And request { evento: 'Validar Tarjeta', guardia: true }
    When method post
    Then status 200
    And match response.estadoAnterior == 'S1 (Bloqueado)'
    And match response.estadoNuevo == 'S2 (Autorizado)'
    And match response.valida == true
    And match response.accion == 'Desbloquear paso'

  @regression @GH-4 @Issue-4
  Scenario: Transición válida: Empujar torniquete autorizado (S2 Autorizado -> S3 Girando)
    Given path 'torniquete/reiniciar'
    When method post
    Then status 200
    * call read('@setupS2')
    Given path 'torniquete/evento'
    And request { evento: 'Empujar' }
    When method post
    Then status 200
    And match response.estadoAnterior == 'S2 (Autorizado)'
    And match response.estadoNuevo == 'S3 (Girando)'
    And match response.valida == true
    And match response.accion == 'Girar molinete'

  @regression @GH-5 @Issue-5
  Scenario: Transición válida: Completar giro del torniquete (S3 Girando -> S1 Bloqueado)
    Given path 'torniquete/reiniciar'
    When method post
    Then status 200
    * call read('@setupS3')
    Given path 'torniquete/evento'
    And request { evento: 'Completar Giro' }
    When method post
    Then status 200
    And match response.estadoAnterior == 'S3 (Girando)'
    And match response.estadoNuevo == 'S1 (Bloqueado)'
    And match response.valida == true
    And match response.accion == null

  @regression @GH-6 @Issue-6
  Scenario: Transición válida: Alarma por fallo de energía desde Bloqueado (S1 Bloqueado -> S4 Mantenimiento)
    Given path 'torniquete/reiniciar'
    When method post
    Then status 200
    Given path 'torniquete/evento'
    And request { evento: 'Alarma', guardia: true }
    When method post
    Then status 200
    And match response.estadoAnterior == 'S1 (Bloqueado)'
    And match response.estadoNuevo == 'S4 (Mantenimiento)'
    And match response.valida == true
    And match response.accion == 'Cortar energía'

  @regression @GH-7 @Issue-7
  Scenario: Transición válida: Alarma por fallo de energía desde Autorizado (S2 Autorizado -> S4 Mantenimiento)
    Given path 'torniquete/reiniciar'
    When method post
    Then status 200
    * call read('@setupS2')
    Given path 'torniquete/evento'
    And request { evento: 'Alarma', guardia: true }
    When method post
    Then status 200
    And match response.estadoAnterior == 'S2 (Autorizado)'
    And match response.estadoNuevo == 'S4 (Mantenimiento)'
    And match response.valida == true
    And match response.accion == 'Cortar energía'

  @regression @GH-8 @Issue-8
  Scenario: Transición válida: Reparar torniquete en falla (S4 Mantenimiento -> S1 Bloqueado)
    Given path 'torniquete/reiniciar'
    When method post
    Then status 200
    * call read('@setupS4')
    Given path 'torniquete/evento'
    And request { evento: 'Reparar' }
    When method post
    Then status 200
    And match response.estadoAnterior == 'S4 (Mantenimiento)'
    And match response.estadoNuevo == 'S1 (Bloqueado)'
    And match response.valida == true
    And match response.accion == 'Restaurar servicio'

  @regression @negative @GH-9 @Issue-9
  Scenario Outline: Bloquear transiciones inválidas: <descripcion>
    Given path 'torniquete/reiniciar'
    When method post
    Then status 200

    * eval if ('<estado_inicial>' == 'S2 (Autorizado)') karate.call('@setupS2')
    * eval if ('<estado_inicial>' == 'S3 (Girando)') karate.call('@setupS3')
    * eval if ('<estado_inicial>' == 'S4 (Mantenimiento)') karate.call('@setupS4')

    Given path 'torniquete/evento'
    And request <payload_solicitud>
    When method post
    Then status 200
    And match response.valida == false
    And match response.estadoNuevo == '<estado_inicial>'
    And match response.estadoAnterior == '<estado_inicial>'

    Examples:
      | estado_inicial     | payload_solicitud                                 | descripcion                                                  |
      | S1 (Bloqueado)     | { evento: 'Empujar' }                             | Empujar sin autorizacion previa                              |
      | S1 (Bloqueado)     | { evento: 'Completar Giro' }                      | Completar giro sin haber iniciado giro                       |
      | S1 (Bloqueado)     | { evento: 'Reparar' }                             | Reparar cuando el torniquete no esta en mantenimiento        |
      | S1 (Bloqueado)     | { evento: 'Validar Tarjeta', guardia: false }     | Validar tarjeta con saldo insuficiente                       |
      | S1 (Bloqueado)     | { evento: 'Alarma', guardia: false }              | Disparar alarma sin falla de energia comprobada              |
      | S2 (Autorizado)    | { evento: 'Validar Tarjeta', guardia: true }      | Validar tarjeta cuando ya se encuentra autorizado            |
      | S2 (Autorizado)    | { evento: 'Completar Giro' }                      | Completar giro antes de empujar el torniquete                |
      | S2 (Autorizado)    | { evento: 'Reparar' }                             | Reparar en estado autorizado                                 |
      | S3 (Girando)       | { evento: 'Empujar' }                             | Empujar nuevamente durante el giro                           |
      | S3 (Girando)       | { evento: 'Validar Tarjeta', guardia: true }      | Validar tarjeta durante el giro                              |
      | S3 (Girando)       | { evento: 'Reparar' }                             | Reparar mientras el torniquete esta girando                  |
      | S4 (Mantenimiento) | { evento: 'Validar Tarjeta', guardia: true }      | Validar tarjeta cuando el torniquete esta en mantenimiento   |
      | S4 (Mantenimiento) | { evento: 'Empujar' }                             | Empujar cuando el torniquete esta en mantenimiento           |
      | S4 (Mantenimiento) | { evento: 'Completar Giro' }                      | Completar giro en estado de mantenimiento                    |
