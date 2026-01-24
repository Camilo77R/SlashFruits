extends Node

# ============================================
# ¿QUÉ ES ESTE ARCHIVO?
# Es el "SECRETARIO" del juego.
# Registra inicio y fin de cada sesión de un niño.
# ============================================

# ============================================
# SEÑALES
# ============================================
signal session_started(session_id: String)
signal session_ended(session_id: String)

# ============================================
# VARIABLES INTERNAS
# ============================================
var current_session_id: String = ""
var child_id: String = ""       # ID del niño (lo da la plataforma web)
var level_id: String = ""       # ID del nivel actual
var started_at: int = 0         # Hora de inicio (UNIX time)
var ended_at: int = 0           # Hora de fin (UNIX time)
var errors: int = 0
var success: bool = false

# ============================================
# FUNCIÓN: start_session()
# ¿QUÉ HACE? Inicia una nueva sesión.
# ¿CUÁNDO? Cuando el niño empieza un nivel.
# ANALOGÍA: Es como abrir un cuaderno nuevo para tomar notas.
# ============================================
func start_session(child: String, level: String) -> void:
	current_session_id = str(Time.get_unix_time_from_system())
	child_id = child
	level_id = level
	started_at = Time.get_unix_time_from_system()
	errors = 0
	success = false

	print("[SessionManager] 📒 Nueva sesión iniciada")
	print("   Niño: ", child_id, " | Nivel: ", level_id)
	print("   Hora inicio: ", started_at)

	session_started.emit(current_session_id)

# ============================================
# FUNCIÓN: register_error()
# ¿QUÉ HACE? Suma un error cuando el niño falla.
# ¿POR QUÉ? Para medir desempeño y precisión.
# ============================================
func register_error() -> void:
	errors += 1
	print("[SessionManager] ❌ Error registrado. Total: ", errors)

# ============================================
# FUNCIÓN: mark_success()
# ¿QUÉ HACE? Marca que el niño completó el nivel con éxito.
# ============================================
func mark_success() -> void:
	success = true
	print("[SessionManager] ✅ Nivel completado con éxito")

# ============================================
# FUNCIÓN: end_session()
# ¿QUÉ HACE? Cierra la sesión y devuelve los datos.
# ¿CUÁNDO? Al terminar el nivel o salir del juego.
# ANALOGÍA: Es como cerrar el cuaderno y entregar el reporte.
# ============================================
func end_session() -> Dictionary:
	ended_at = Time.get_unix_time_from_system()

	var session_data = {
		"session_id": current_session_id,
		"child_id": child_id,
		"level_id": level_id,
		"started_at": started_at,
		"ended_at": ended_at,
		"success": success,
		"errors": errors
	}

	print("[SessionManager] 📕 Sesión finalizada")
	print("   Datos: ", session_data)

	session_ended.emit(current_session_id)
	return session_data
