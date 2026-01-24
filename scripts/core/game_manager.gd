# scripts/core/game_manager.gd
extends Node

# ============================================
# ¿QUÉ ES ESTE SCRIPT?
# Es el "DIRECTOR DE ORQUESTA" del juego.
# Controla TODAS las reglas, puntos, vidas y progreso.
# Es un SINGLETON (Autoload) - accesible desde cualquier parte.
# ============================================

# ============================================
# SECCIÓN: SEÑALES (SIGNALS)
# ¿QUÉ SON? "GRITOS" que otros módulos pueden escuchar.
# ¿PARA QUÉ? Comunicación entre módulos SIN que se conozcan.
# ============================================
signal score_updated(new_score: int)
signal lives_updated(new_lives: int)
signal game_over()
signal word_completed(word: String)
signal correct_letter_cut(letter: String)
signal wrong_letter_cut(letter: String)

# ============================================
# SECCIÓN: CONFIGURACIÓN EDITABLE (@export)
# ¿QUÉ SON? Variables que aparecen en el INSPECTOR.
# ¿PARA QUÉ? Cambiar valores SIN tocar código (modularidad).
# ============================================
@export var starting_lives: int = 3
@export var points_per_correct: int = 10
@export var points_per_wrong: int = 5  # Negativo = resta puntos



# ============================================
# SECCIÓN: ESTADO DEL JUEGO (VARIABLES)
# ¿QUÉ SON? Datos que GameManager recuerda durante el juego.
# ¿POR QUÉ AQUÍ? Porque GameManager es el único que sabe estado global.
# ============================================
var current_score: int = 0
var current_lives: int = 3
var target_word: String = "GATO"
var current_letter_index: int = 0
var is_game_active: bool = true
# --- NUEVAS VARIABLES PARA NIVELES ---
var current_level: LevelData = null
var question_loader = null



# ============================================
# SECCIÓN: MODOS DE JUEGO (ENUM)
# ¿QUÉ SON? Tipos predefinidos de juego.
# CULTURE: Letras, palabras (Capitales, etc.)
# LOGIC: Números, operaciones matemáticas
# ============================================
enum GameMode { CULTURE, LOGIC }
var current_mode: GameMode = GameMode.CULTURE

func get_current_mode() -> GameMode:
	return current_mode

func get_value_type_needed() -> String:
	if not is_game_active:
		return "any"

	if current_letter_index >= target_word.length():
		return "any"

	if current_mode == GameMode.CULTURE:
		return "letter"
	else:  # LOGIC
		return "number"



# ============================================
# FUNCIÓN: _ready()
# ¿CUÁNDO SE EJECUTA? Cuando Godot carga el GameManager.
# ¿QUÉ HACE? Inicializa el sistema llamando a reset_game().
# ============================================
# Modificar _ready():
func _ready() -> void:
	print("[GameManager] ¡Sistema central listo!")
	
	# Esperar a que QuestionLoader termine de cargar
	if has_node("/root/QuestionLoader"):
		question_loader = get_node("/root/QuestionLoader")
		question_loader.levels_loaded.connect(_on_levels_loaded)  # ← CONECTAR
		print("[GameManager] Esperando que QuestionLoader cargue niveles...")
	else:
		print("[GameManager] ⚠️ QuestionLoader no encontrado")
		reset_game()

# --- NUEVA FUNCIÓN ---
func _on_levels_loaded() -> void:
	print("[GameManager] QuestionLoader terminó de cargar")
	load_random_level()


# --- NUEVA FUNCIÓN: load_random_level() ---
func load_random_level() -> void:
	if question_loader == null:
		print("[GameManager] ❌ No hay QuestionLoader")
		return

	# Obtener nivel según modo actual
	var game_type = "culture" if current_mode == GameMode.CULTURE else "logic"
	current_level = question_loader.get_random_level(game_type, 3)  # max dificultad 3

	if current_level:
		# Actualizar target_word con respuesta del nivel
		target_word = current_level.correct_answer
		current_letter_index = 0
		is_game_active = true
		
		# NUEVO: Iniciar sesión en SessionManager
		# ¿Qué? Abrimos un "cuaderno" para esta partida.
		# ¿Por qué? Para registrar inicio/fin y métricas asociadas.
		# ¿Cuándo? Justo al cargar un nivel nuevo.
		# ¿Para qué? Que padres/tutores sepan qué jugó el niño.
		SessionManager.start_session("child_demo_id", current_level.id)


		
		print("[GameManager] ✅ Nivel cargado: ", current_level.id)
		print("[GameManager] Pregunta: ", current_level.question)
		print("[GameManager] Respuesta: ", target_word)
	else:
		print("[GameManager] ⚠️ No se pudo cargar nivel, usando valores por defecto")
		reset_game()



# ============================================
# FUNCIÓN: set_game_mode()
# ¿QUÉ HACE? Cambia entre modos CULTURA y LÓGICA.
# ¿CUÁNDO USAR? Cuando el jugador selecciona categoría.
# ============================================
func set_game_mode(mode: GameMode) -> void:
	current_mode = mode
	print("[GameManager] Modo cambiado a: ", 
		  "CULTURA" if mode == GameMode.CULTURE else "LÓGICA")
	reset_game()

# ============================================
# FUNCIÓN: get_next_letter()
# ¿QUÉ HACE? Le dice al Spawner qué letra necesita el jugador ahora.
# RETORNA: String - la letra que toca, o "" si no necesita específica.
# ============================================
func get_next_letter() -> String:
	if not is_game_active:
		return ""
	
	if current_letter_index >= target_word.length():
		return ""
	
	var next_letter = target_word[current_letter_index]
	print("[GameManager] Próxima letra necesaria: ", next_letter)
	return next_letter

# ============================================
# FUNCIÓN: is_letter_correct()
# ¿QUÉ HACE? Le dice a la Fruit si es correcta o no.
# PRINCIPIO: Verificación segura para evitar "out of bounds".
# ============================================
func is_letter_correct(letter: String) -> bool:
	if not is_game_active:
		return false
	
	if current_letter_index >= target_word.length():
		return false
	
	return letter == target_word[current_letter_index]

# ============================================
# FUNCIÓN: set_new_word()
# ¿QUÉ HACE? Cambia a una nueva palabra objetivo (sube de nivel).
# ============================================
func set_new_word(new_word: String) -> void:
	target_word = new_word.to_upper()
	current_letter_index = 0
	print("[GameManager] Nueva palabra: ", target_word)

# ============================================
# FUNCIÓN: reset_game()
# ¿QUÉ HACE? Reinicia TODO el estado del juego a valores iniciales.
# ============================================
func reset_game() -> void:
	current_score = 0
	current_lives = starting_lives
	target_word = "GATO"
	current_letter_index = 0
	is_game_active = true
	
	score_updated.emit(current_score)
	lives_updated.emit(current_lives)
	print("[GameManager] Juego reiniciado. Palabra: ", target_word)

# ============================================
# FUNCIÓN: register_fruit_cut()
# ¿QUÉ HACE? Procesa cuando cortan una fruta.
# PRINCIPIO: Decide si fue acierto/error y actúa en consecuencia.
# ============================================
func register_fruit_cut(fruit_value: String, was_correct: bool) -> void:
	if not is_game_active:
		return
	
	print("[GameManager] Fruta cortada: ", fruit_value, " | Correcta: ", was_correct)
	
	if was_correct and fruit_value == target_word[current_letter_index]:
		handle_correct_letter(fruit_value)
	else:
		handle_wrong_letter(fruit_value)

# ============================================
# FUNCIÓN: handle_correct_letter()
# ¿QUÉ HACE? Gestiona las consecuencias de acertar.
# FLUJO: Sumar puntos → Avanzar índice → Verificar si completó palabra.
# ============================================
func handle_correct_letter(letter: String) -> void:
	current_score += points_per_correct
	score_updated.emit(current_score)
	
	current_letter_index += 1
	correct_letter_cut.emit(letter)
	
	print("✅ ¡BIEN! Letra correcta: ", letter)
	print("   Puntos: ", current_score, " | Próxima letra: ", current_letter_index)
	
	if current_letter_index >= target_word.length():
		print("🎉 ¡FELICIDADES! Palabra completada: ", target_word)
		word_completed.emit(target_word)
		
		# NUEVO: Marcar éxito en SessionManager
		# ¿Qué? Anotamos que el niño logró la meta.
		# ¿Por qué? Para diferenciar sesiones exitosas de fallidas.
		SessionManager.mark_success()

		# NUEVO: Cerrar sesión y calcular métricas
		var session_data: Dictionary = SessionManager.end_session()
		var metrics: Dictionary = MetricsTracker.calculate_metrics()
		MetricsTracker.reset()
		# ApiClient.send_session(session_data, metrics)

		set_new_word("CASA")

# ============================================
# FUNCIÓN: handle_wrong_letter()
# ¿QUÉ HACE? Gestiona las consecuencias de errar.
# FLUJO: Restar puntos → Quitar vida → Verificar Game Over.
# ============================================
func handle_wrong_letter(letter: String) -> void:
	current_score += points_per_wrong  # points_per_wrong es negativo
	score_updated.emit(current_score)

	
	current_lives -= 1
	lives_updated.emit(current_lives)
	
	wrong_letter_cut.emit(letter)
	print("❌ ¡ERROR! Letra incorrecta: ", letter)
	print("   Puntos: ", current_score, " | Vidas: ", current_lives)
	
	
	# Registrar error en SessionManager
	# ¿Qué? Anotamos un fallo en el cuaderno.
	# ¿Por qué? Para medir precisión y dar feedback a padres/tutores.
	SessionManager.register_error()
	if current_lives <= 0:
		game_over.emit()
		is_game_active = false
		print("💀 ¡GAME OVER! Puntuación final: ", current_score)
		
		#  Cerrar sesión y calcular métricas
		# ¿Qué? Cerramos el cuaderno y sacamos el boletín.
		# ¿Por qué? Para enviar datos al backend.
		var session_data: Dictionary = SessionManager.end_session()
		var metrics: Dictionary = MetricsTracker.calculate_metrics()
		MetricsTracker.reset()
		# ApiClient.send_session(session_data, metrics) ← se hará en el paso de API



# ============================================
# AGREGAR AQUÍ (al final, antes del comentario final)
# ============================================

# FUNCIÓN: _test_switch_modes() - SOLO PARA TESTING
func _test_switch_modes() -> void:
	print("\n[TEST] 🔄 Iniciando prueba de cambio de modos...")

	await get_tree().create_timer(5.0).timeout

	set_game_mode(GameMode.LOGIC)
	target_word = "13"
	current_letter_index = 0

	print("[TEST] 🔢 Modo LÓGICA activado")
	print("[TEST] Palabra objetivo: '", target_word, "' (números)")

	await get_tree().create_timer(10.0).timeout

	set_game_mode(GameMode.CULTURE)
	target_word = "GATO"
	current_letter_index = 0

	print("[TEST] 🔤 Modo CULTURA reactivado")
	print("[TEST] Palabra objetivo: '", target_word, "' (letras)")

# ============================================
# CONSEJOS DE BUENA PRÁCTICA APLICADOS:
# (este comentario ya estaba al final)
# ============================================
# ============================================
# CONSEJOS DE BUENA PRÁCTICA APLICADOS:
# 1. SINGLE RESPONSIBILITY: GameManager solo sabe reglas
# 2. ENCAPSULATION: Estado interno protegido
# 3. SIGNALS: Comunicación desacoplada
# 4. CLEAN CODE: Funciones cortas con un propósito
# 5. DEFENSIVE PROGRAMMING: Verificaciones de seguridad
# ============================================
