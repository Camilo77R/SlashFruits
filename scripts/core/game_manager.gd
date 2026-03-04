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
signal difficulty_changed(new_difficulty: int)  # NUEVA SEÑAL

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
# SECCIÓN: DIFICULTAD ADAPTATIVA
# Sistema que ajusta dificultad según rendimiento del niño
# ============================================
var consecutive_errors: int = 0
var consecutive_successes: int = 0
var adaptive_difficulty: int = 1  # 1=fácil, 2=medio, 3=difícil
var max_difficulty: int = 3
var min_difficulty: int = 1

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
func _ready() -> void:
	print("[GameManager] ¡Sistema central listo!")
	
	# Esperar a que QuestionLoader termine de cargar
	if has_node("/root/QuestionLoader"):
		question_loader = get_node("/root/QuestionLoader")
		question_loader.levels_loaded.connect(_on_levels_loaded)
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
	
	# CAMBIO: Usar dificultad adaptativa
	current_level = question_loader.get_random_level(game_type, adaptive_difficulty)

	if current_level:
		# Actualizar target_word con respuesta del nivel
		target_word = current_level.correct_answer
		current_letter_index = 0
		is_game_active = true
		
		# Reiniciar spawner si estaba detenido
		if has_node("/root/Main/Spawner"):
			get_node("/root/Main/Spawner").start_spawning()
		
		# NUEVO: Iniciar sesión en SessionManager
		SessionManager.start_session("child_demo_id", current_level.id)
		
		print("[GameManager] ✅ Nivel cargado: ", current_level.id)
		print("[GameManager] Pregunta: ", current_level.question)
		print("[GameManager] Respuesta: ", target_word)
		print("[GameManager] Dificultad actual: ", adaptive_difficulty)
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
# FUNCION: is_next_letter_in_sequence()
# ============================================
func is_next_letter_in_sequence(letter: String) -> bool:
	if not is_game_active:
		return false
	
	if current_letter_index >= target_word.length():
		return false
	
	var expected_letter = target_word[current_letter_index]
	var is_correct = (letter == expected_letter)
	
	print("[GameManager] Validacion de orden:")
	print("              Letra recibida: '", letter, "'")
	print("              Letra esperada: '", expected_letter, "'")
	print("              Indice actual: ", current_letter_index)
	print("              Resultado: ", "CORRECTO" if is_correct else "INCORRECTO")
	
	return is_correct

# ============================================
# FUNCION: is_letter_in_word()
# ============================================
func is_letter_in_word(letter: String) -> bool:
	if not is_game_active:
		return false
	
	var exists = target_word.contains(letter)
	
	print("[GameManager] Verificacion de existencia:")
	print("              Letra: '", letter, "'")
	print("              Palabra: '", target_word, "'")
	print("              Existe: ", exists)
	
	return exists

# ============================================
# FUNCION: handle_bomb_cut()
# ============================================
func handle_bomb_cut() -> void:
	print("[GameManager] BOMBA CORTADA - Iniciando Game Over")
	
	current_lives = 0
	lives_updated.emit(current_lives)
	
	is_game_active = false
	
	# Detener creación de frutas
	if has_node("/root/Main/Spawner"):
		get_node("/root/Main/Spawner").stop_spawning()
	
	game_over.emit()
	
	print("[GameManager] Estado del juego:")
	print("              Vidas restantes: ", current_lives)
	print("              Juego activo: ", is_game_active)
	
	SessionManager.register_error()
	
	var session_data: Dictionary = SessionManager.end_session()
	var metrics_summary: Dictionary = MetricsTracker.get_session_summary()
	
	print("[GameManager] Metricas de sesion finalizada:")
	print("              Total preguntas: ", metrics_summary.get("total_questions", 0))
	print("              Precision: ", metrics_summary.get("accuracy_percentage", 0), "%")
	
	MetricsTracker.reset()
	
	print("[GameManager] Game Over por bomba completado")

# ============================================
# FUNCION MODIFICADA: register_fruit_cut()
# ============================================
func register_fruit_cut(fruit_value: String, was_correct: bool, was_in_order: bool = true) -> void:
	if not is_game_active:
		print("[GameManager] Juego no activo, ignorando corte")
		return
	
	print("[GameManager] Procesando corte de fruta:")
	print("              Valor: '", fruit_value, "'")
	print("              Es correcta: ", was_correct)
	print("              Esta en orden: ", was_in_order)
	
	if fruit_value == "BOMB":
		print("[GameManager] Detectada bomba - desviando a handle_bomb_cut()")
		handle_bomb_cut()
		return
	
	if was_correct and was_in_order:
		print("[GameManager] Evaluacion: ACIERTO")
		handle_correct_letter(fruit_value)
	else:
		print("[GameManager] Evaluacion: ERROR")
		handle_wrong_letter(fruit_value)

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
	
	# Resetear sistema adaptativo
	consecutive_errors = 0
	consecutive_successes = 0
	adaptive_difficulty = 1
	
	score_updated.emit(current_score)
	lives_updated.emit(current_lives)
	print("[GameManager] Juego reiniciado. Palabra: ", target_word)

# ============================================
# FUNCIÓN: handle_correct_letter()
# CON SISTEMA ADAPTATIVO INTEGRADO
# ============================================
func handle_correct_letter(letter: String) -> void:
	current_score += points_per_correct
	score_updated.emit(current_score)
	
	current_letter_index += 1
	correct_letter_cut.emit(letter)
	
	# SISTEMA ADAPTATIVO: Incrementar racha de aciertos
	consecutive_successes += 1
	consecutive_errors = 0
	
	# Si acierta 5 seguidas, subir dificultad
	if consecutive_successes >= 5 and adaptive_difficulty < max_difficulty:
		adaptive_difficulty += 1
		consecutive_successes = 0
		difficulty_changed.emit(adaptive_difficulty)
		print("[GameManager] 🎯 DIFICULTAD AUMENTADA a nivel ", adaptive_difficulty)
		print("              Razón: 5 aciertos consecutivos")
	
	print("✅ ¡BIEN! Letra correcta: ", letter)
	print("   Puntos: ", current_score, " | Próxima letra: ", current_letter_index)
	print("   Racha de aciertos: ", consecutive_successes)
	
	if current_letter_index >= target_word.length():
		print("🎉 ¡FELICIDADES! Palabra completada: ", target_word)
		word_completed.emit(target_word)
		
		SessionManager.mark_success()

		var session_data: Dictionary = SessionManager.end_session()
		var metrics: Dictionary = MetricsTracker.get_session_summary()
		MetricsTracker.reset()

		load_random_level()

# ============================================
# FUNCIÓN: handle_wrong_letter()
# CON SISTEMA ADAPTATIVO INTEGRADO
# ============================================
func handle_wrong_letter(letter: String) -> void:
	current_score += points_per_wrong
	score_updated.emit(current_score)
	
	current_lives -= 1
	lives_updated.emit(current_lives)
	
	wrong_letter_cut.emit(letter)
	
	# SISTEMA ADAPTATIVO: Incrementar racha de errores
	consecutive_errors += 1
	consecutive_successes = 0
	
	# Si falla 3 seguidas, bajar dificultad
	if consecutive_errors >= 3 and adaptive_difficulty > min_difficulty:
		adaptive_difficulty -= 1
		consecutive_errors = 0
		difficulty_changed.emit(adaptive_difficulty)
		print("[GameManager] 📉 DIFICULTAD REDUCIDA a nivel ", adaptive_difficulty)
		print("              Razón: 3 errores consecutivos")
	
	print("❌ ¡ERROR! Letra incorrecta: ", letter)
	print("   Puntos: ", current_score, " | Vidas: ", current_lives)
	print("   Errores consecutivos: ", consecutive_errors)
	
	SessionManager.register_error()
	
	if current_lives <= 0:
		game_over.emit()
		is_game_active = false
		
		# Detener creación de frutas
		if has_node("/root/Main/Spawner"):
			get_node("/root/Main/Spawner").stop_spawning()
		
		print("💀 ¡GAME OVER! Puntuación final: ", current_score)
		
		var session_data: Dictionary = SessionManager.end_session()
		var metrics: Dictionary = MetricsTracker.get_session_summary()
		MetricsTracker.reset()

# ============================================
# FUNCIÓN NUEVA: get_current_difficulty()
# Para que UI pueda mostrar dificultad actual
# ============================================
func get_current_difficulty() -> int:
	return adaptive_difficulty

# ============================================
# FUNCIÓN NUEVA: get_difficulty_label()
# Retorna texto legible de dificultad
# ============================================
func get_difficulty_label() -> String:
	match adaptive_difficulty:
		1:
			return "Fácil"
		2:
			return "Medio"
		3:
			return "Difícil"
		_:
			return "Desconocido"

# ============================================
# CONSEJOS DE BUENA PRÁCTICA APLICADOS:
# 1. SINGLE RESPONSIBILITY: GameManager solo sabe reglas
# 2. ENCAPSULATION: Estado interno protegido
# 3. SIGNALS: Comunicación desacoplada
# 4. CLEAN CODE: Funciones cortas con un propósito
# 5. DEFENSIVE PROGRAMMING: Verificaciones de seguridad
# 6. ADAPTIVE LEARNING: Ajuste dinámico de dificultad
# ============================================
