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
# FUNCION: is_next_letter_in_sequence()
# ============================================
# QUE HACE:
# Verifica si una letra es exactamente la que el jugador debe cortar AHORA.
# 
# DIFERENCIA CON is_letter_correct():
# - is_letter_correct(): "¿Esta letra existe en la palabra?" (mas general)
# - is_next_letter_in_sequence(): "¿Es esta LA letra que toca cortar ahora?" (mas especifico)
# 
# EJEMPLO PRACTICO:
# Si target_word = "GATO" y current_letter_index = 1
# - is_next_letter_in_sequence("A") -> true  (es la que toca)
# - is_next_letter_in_sequence("T") -> false (esta en la palabra pero no es la que toca)
# - is_next_letter_in_sequence("X") -> false (ni siquiera esta en la palabra)
# 
# QUIEN LA LLAMA:
# Fruit.setup() cuando se configura cada fruta
# 
# CUANDO SE USA:
# Cada vez que Spawner crea una nueva fruta
# 
# POR QUE EXISTE:
# Para validar el orden secuencial, no solo la existencia de la letra
# ============================================
func is_next_letter_in_sequence(letter: String) -> bool:
	# Verificacion de seguridad 1: Juego activo
	if not is_game_active:
		return false
	
	# Verificacion de seguridad 2: No hemos pasado el final de la palabra
	if current_letter_index >= target_word.length():
		return false
	
	# Obtener la letra que toca en este momento
	var expected_letter = target_word[current_letter_index]
	
	# Comparar
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
# QUE HACE:
# Verifica si una letra existe EN ALGUNA PARTE de la palabra objetivo.
# 
# DIFERENCIA CON is_next_letter_in_sequence():
# Esta funcion NO considera el orden, solo la existencia.
# 
# PARA QUE SIRVE:
# Para diferenciar dos tipos de error:
# 1. Letra que esta en palabra pero cortada fuera de orden (puede dar feedback especifico)
# 2. Letra que ni siquiera esta en la palabra (error total)
# 
# EJEMPLO PRACTICO:
# Si target_word = "GATO"
# - is_letter_in_word("A") -> true  (esta en posicion 1)
# - is_letter_in_word("T") -> true  (esta en posicion 2)
# - is_letter_in_word("X") -> false (no existe)
# 
# USO EN UI:
# Permite mostrar mensajes mas especificos:
# - "Esa letra esta en la palabra, pero no es la que toca ahora"
# - "Esa letra no esta en la palabra"
# ============================================
func is_letter_in_word(letter: String) -> bool:
	# Verificacion de seguridad
	if not is_game_active:
		return false
	
	# Buscar la letra en toda la palabra
	var exists = target_word.contains(letter)
	
	print("[GameManager] Verificacion de existencia:")
	print("              Letra: '", letter, "'")
	print("              Palabra: '", target_word, "'")
	print("              Existe: ", exists)
	
	return exists

# ============================================
# FUNCION: handle_bomb_cut()
# ============================================
# QUE HACE:
# Procesa el caso especial de cortar una bomba.
# 
# COMPORTAMIENTO:
# - Game Over INMEDIATO (sin importar cuantas vidas tenga)
# - Las vidas se ponen en 0
# - El juego se desactiva
# - Se registran las metricas finales
# 
# CUANDO SE LLAMA:
# Desde register_fruit_cut() cuando detecta que value == "BOMB"
# 
# POR QUE ES ESPECIAL:
# Porque no sigue las reglas normales de vidas.
# Una bomba termina el juego instantaneamente.
# 
# FLUJO:
# 1. Fruta bomba es cortada
# 2. Emite señal fruit_cut("BOMB", false, false)
# 3. Spawner llama GameManager.register_fruit_cut("BOMB", ...)
# 4. register_fruit_cut detecta bomba y llama handle_bomb_cut()
# 5. handle_bomb_cut() termina el juego
# ============================================
func handle_bomb_cut() -> void:
	print("[GameManager] BOMBA CORTADA - Iniciando Game Over")
	
	# Forzar vidas a cero (para que UI lo refleje)
	current_lives = 0
	lives_updated.emit(current_lives)
	
	# Desactivar juego
	is_game_active = false
	
	# Emitir señal de game over (para que UI muestre pantalla)
	game_over.emit()
	
	print("[GameManager] Estado del juego:")
	print("              Vidas restantes: ", current_lives)
	print("              Juego activo: ", is_game_active)
	
	# Registrar el error en la sesion
	SessionManager.register_error()
	
	# Obtener metricas finales antes de limpiar
	var session_data: Dictionary = SessionManager.end_session()
	var metrics_summary: Dictionary = MetricsTracker.get_session_summary()
	
	print("[GameManager] Metricas de sesion finalizada:")
	print("              Total preguntas: ", metrics_summary.get("total_questions", 0))
	print("              Precision: ", metrics_summary.get("accuracy_percentage", 0), "%")
	
	# TODO: Cuando ApiClient este listo, descomentar:
	# ApiClient.send_session(session_data, metrics_summary)
	
	# Limpiar metricas para proxima sesion
	MetricsTracker.reset()
	
	print("[GameManager] Game Over por bomba completado")

# ============================================
# FUNCION MODIFICADA: register_fruit_cut()
# ============================================
# CAMBIOS RESPECTO A VERSION ANTERIOR:
# 1. Agrega parametro was_in_order
# 2. Detecta caso especial de bomba
# 3. Diferencia entre error de orden y error total
# 
# DONDE MODIFICAR:
# Buscar la funcion register_fruit_cut() existente en game_manager.gd
# Reemplazar TODA la funcion con esta version
# 
# PARAMETROS:
#   fruit_value: El valor de la fruta cortada ("G", "5", "BOMB")
#   was_correct: Si la letra/numero esta en la respuesta correcta
#   was_in_order: Si era la letra que tocaba EN ESTE MOMENTO
# 
# QUIEN LA LLAMA:
# Spawner._on_fruit_cut(), que a su vez recibe la señal de Fruit
# ============================================
func register_fruit_cut(fruit_value: String, was_correct: bool, was_in_order: bool = true) -> void:
	# Verificacion de seguridad
	if not is_game_active:
		print("[GameManager] Juego no activo, ignorando corte")
		return
	
	print("[GameManager] Procesando corte de fruta:")
	print("              Valor: '", fruit_value, "'")
	print("              Es correcta: ", was_correct)
	print("              Esta en orden: ", was_in_order)
	
	# CASO ESPECIAL: BOMBA
	# Manejo diferente porque termina el juego inmediatamente
	if fruit_value == "BOMB":
		print("[GameManager] Detectada bomba - desviando a handle_bomb_cut()")
		handle_bomb_cut()
		return
	
	# CASO NORMAL: LETRA O NUMERO
	# Solo es acierto si AMBAS condiciones son verdaderas:
	# 1. La letra es correcta (esta en la palabra)
	# 2. Es la que toca en este momento (orden)
	if was_correct and was_in_order:
		print("[GameManager] Evaluacion: ACIERTO")
		handle_correct_letter(fruit_value)
	else:
		# Cualquier otro caso es error:
		# - Letra incorrecta (ni siquiera esta en palabra)
		# - Letra correcta pero fuera de orden
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
	
	score_updated.emit(current_score)
	lives_updated.emit(current_lives)
	print("[GameManager] Juego reiniciado. Palabra: ", target_word)

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
		var metrics: Dictionary = MetricsTracker.get_session_summary()  # ← CORREGIDO
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
		
		# Cerrar sesión y calcular métricas
		# ¿Qué? Cerramos el cuaderno y sacamos el boletín.
		# ¿Por qué? Para enviar datos al backend.
		var session_data: Dictionary = SessionManager.end_session()
		var metrics: Dictionary = MetricsTracker.get_session_summary()  # ← CORREGIDO
		MetricsTracker.reset()
		# ApiClient.send_session(session_data, metrics) ← se hará en el paso de API

# ============================================
# CONSEJOS DE BUENA PRÁCTICA APLICADOS:
# 1. SINGLE RESPONSIBILITY: GameManager solo sabe reglas
# 2. ENCAPSULATION: Estado interno protegido
# 3. SIGNALS: Comunicación desacoplada
# 4. CLEAN CODE: Funciones cortas con un propósito
# 5. DEFENSIVE PROGRAMMING: Verificaciones de seguridad
# ============================================
