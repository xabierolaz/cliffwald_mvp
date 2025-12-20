# Auditoría Técnica del Proyecto "Cliffwald"
**Fecha:** 14 de Diciembre de 2025
**Estado:** Pre-Alpha / Prototipo
**Enfoque:** Auditoría "Zeroing" (Búsqueda de problemas reales ignorando comentarios)

## 1. Resumen Ejecutivo
El proyecto presenta una arquitectura base de MMO funcional (Gateway, Master, World) implementada en Godot. Sin embargo, contiene **vulnerabilidades de seguridad críticas** que lo hacen improcedente para cualquier despliegue público. La lógica de combate confía ciegamente en el cliente, y el sistema de persistencia de datos no es escalable ni seguro. Se requiere una refactorización mayor de la capa de seguridad y datos antes de continuar con nuevas características.

## 2. Hallazgos Críticos de Seguridad (Prioridad 0)

### 2.1. Confianza Ciega en RPCs de Combate (Game-Breaking)
**Archivo:** `source/common/gameplay/characters/player/net_player.gd`
**Función:** `rpc_cast_spell`

*   **Problema:** El servidor expone el RPC `rpc_cast_spell` con permisos `any_peer` y ejecuta la lógica de instanciación de proyectiles **sin ninguna validación**.
*   **Impacto:** Un atacante puede llamar a esta función remotamente (inyectando paquetes o modificando el cliente) para instanciar miles de proyectiles por segundo, ignorando cooldowns, maná, o si siquiera tiene el hechizo desbloqueado.
*   **Evidencia:**
    ```gdscript
    @rpc("any_peer", "call_remote", "reliable")
    func rpc_cast_spell(gesture_id: String, aim_yaw: float):
        if not multiplayer.is_server(): return
        # ... instancia proyectil directamente ...
    ```

### 2.2. Almacenamiento de Contraseñas en Texto Plano
**Archivo:** `source/server/master/components/database.gd`
**Función:** `validate_credentials`

*   **Problema:** Las contraseñas se almacenan sin encriptar en un archivo `.tres` y se comparan directamente (`if account.password == password:`).
*   **Impacto:** Compromiso total de todas las cuentas de usuario si se filtra el archivo de base de datos o se accede al servidor.
*   **Solución:** Implementar hashing (e.g., Argon2 o Bcrypt) y salting. Nunca guardar passwords reales.

### 2.3. Generación Débil de Tokens de Sesión
**Archivo:** `source/server/master/components/authentication_manager.gd`
**Función:** `generate_random_token`

*   **Problema:** Se utiliza `randi()` (generador pseudoaleatorio no criptográfico) para crear tokens de sesión.
*   **Impacto:** Los tokens son predecibles. Un atacante podría predecir tokens de sesión de otros usuarios y secuestrar sus cuentas.

## 3. Problemas de Arquitectura y Escalabilidad

### 3.1. Base de Datos en Memoria (Resource)
**Archivo:** `source/server/master/account_models/account_collection.gd`

*   **Problema:** La base de datos de usuarios es un `Resource` (`.tres`) que se carga completamente en RAM.
*   **Impacto:**
    1.  **Escalabilidad:** El servidor colapsará por uso de RAM con una base de usuarios moderada.
    2.  **Concurrencia:** Riesgo de corrupción de datos si hay escrituras simultáneas o crasheos durante el guardado (`ResourceSaver` no es atómico ni transaccional en este contexto).
    3.  **Migración:** Difícil de migrar a SQL/NoSQL en el futuro sin scripts de conversión complejos.

### 3.2. Lógica de Gestos 100% Cliente
**Archivo:** `source/client/local_player/gesture_manager.gd`

*   **Problema:** El reconocimiento de gestos ocurre exclusivamente en el cliente. El servidor solo recibe "He lanzado Fuego".
*   **Impacto:** Facilita la creación de bots y macros. El servidor debería, idealmente, validar al menos la cadencia y quizás recibir los puntos del trazo (simplificados) para validación heurística si se busca alta seguridad competitiva.

## 4. Calidad de Código y Deuda Técnica

### 4.1. Rutas "Hardcoded" y Dependencias Frágiles
**Archivo:** `source/common/gameplay/characters/player/net_player.gd`

*   **Problema:** Diccionario `spells` con rutas directas (`res://...`).
*   **Riesgo:** Si se mueven los archivos, el código rompe silenciosamente o en runtime. Usar `Export` variables o un `ContentRegistry` robusto.

### 4.2. TLS Inseguro en Desarrollo
**Archivo:** `source/server/world/components/world_manager_client.gd`

*   **Observación:** `TLSOptions.client_unsafe(cert)`.
*   **Nota:** Aceptable para desarrollo, pero se debe asegurar que esto no llegue a producción.

## 5. Plan de Acción Recomendado

1.  **Inmediato (Seguridad):**
    *   Reescribir `rpc_cast_spell` en el servidor para validar:
        *   ¿El jugador tiene el hechizo?
        *   ¿Tiene maná suficiente?
        *   ¿Está en cooldown?
    *   Integrar hashing de contraseñas en `AuthenticationManager`.
    *   Usar `Crypto.new().generate_random_bytes()` para los tokens.

2.  **Corto Plazo (Persistencia):**
    *   Reemplazar `AccountResourceCollection` con una base de datos real (SQLite para empezar, PostgreSQL para producción) usando el plugin Godot-SQL o un adaptador externo.

3.  **Medio Plazo (Gameplay):**
    *   Centralizar la definición de habilidades en `Resources` compartidos (Common) que definan daño, costo y cooldown, accesibles tanto por Cliente (UI) como Servidor (Validación).
