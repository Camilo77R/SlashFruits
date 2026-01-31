# scripts/core/spawner.gd
extends Node2D

# ============================================
# VERSION MEJORADA - Validación de orden + Métricas granulares
# Basado en tu código actual
# ============================================

@export var fruit_scene: PackedScene
@export var spawn_rate: float = 1.5
@export var spawn_below_screen: float = 100

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = spawn_rate
	print("[Spawner] Sistema de producción INICIADO")
	print("[Spawner] Frecuencia: cada ", spawn_rate, " segundos")

func _on_timer_timeout() -> void:
	create_fruit()

# ============================================
# FUNCION: create_fruit() - MODIFICADA
# Cambios:
# 1. Ahora pasa fruit_id con .bind()
# 2. La señal fruit_cut tiene 3 parámetros
# ============================================
func create_fruit() -> void:
	if fruit_scene == null:
		print("[Spawner] ERROR: No hay escena de fruta asignada")
		return
	
	var new_fruit = fruit_scene.instantiate()
	
	# Obtener valor según modo
	var next_value = get_value_for_current_mode()
	
	# Configurar fruta
	var launch_angle = get_random_launch_angle()
	new_fruit.setup(next_value, launch_angle)
	
	# MODIFICACION: Conectar señal con bind para pasar fruit_id
	# La señal fruit_cut ahora emite: (value, was_correct, was_in_order)
	# Con bind agregamos: fruit_id
	# Total recibido: (value, was_correct, was_in_order, fruit_id)
	new_fruit.fruit_cut.connect(_on_fruit_cut.bind(new_fruit.get_instance_id()))
	
	# Posicionar
	var screen_size = get_viewport().get_visible_rect().size
	new_fruit.position = Vector2(
		randf_range(100, screen_size.x - 100),
		screen_size.y + spawn_below_screen
	)
	
	add_child(new_fruit)
	
	# Registrar spawn en métricas
	MetricsTracker.register_spawn(new_fruit.get_instance_id())
	
	print("[Spawner] Fruta creada: '", next_value, "' en ", new_fruit.position)

func get_value_for_current_mode() -> String:
	print("[Spawner] Generando valor según modo actual...")
	
	# 1. Chance de bomba (10%)
	if randf() < 0.1:
		print("[Spawner] BOMBA generada!")
		return "BOMB"
	
	# 2. Preguntar tipo necesario
	var value_type = GameManager.get_value_type_needed()
	print("[Spawner] GameManager dice que necesita tipo: ", value_type)
	
	# 3. Preguntar valor específico
	var needed_value = GameManager.get_next_letter()
	
	# 4. 70% de dar el valor necesario
	if needed_value != "" and randf() < 0.7:
		print("[Spawner] Dando valor necesario: '", needed_value, "'")
		return needed_value
	
	# 5. Generar aleatorio según tipo
	print("[Spawner] Generando valor aleatorio del tipo: ", value_type)
	
	match value_type:
		"letter":
			return get_random_alphabet_letter()
		"number":
			return get_random_number()
		"any":
			if randf() < 0.5:
				return get_random_alphabet_letter()
			else:
				return get_random_number()
		_:
			print("[Spawner] Tipo desconocido, usando letra por defecto")
			return get_random_alphabet_letter()

func get_random_launch_angle() -> Vector2:
	var angle_x = randf_range(-310, 310)
	var angle_y = randf_range(-1100, -900)
	return Vector2(angle_x, angle_y)

func get_random_alphabet_letter() -> String:
	var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var letter = alphabet[randi() % alphabet.length()]
	print("[Spawner] Letra aleatoria: ", letter)
	return letter

func get_random_number() -> String:
	var numbers = "0123456789"
	var number = numbers[randi() % numbers.length()]
	print("[Spawner] Número aleatorio: ", number)
	return number

# ============================================
# FUNCION: _on_fruit_cut() - MODIFICADA PARA 3 PARAMETROS
# ============================================
# QUE CAMBIO:
# Ahora recibe 3 parámetros de la señal + 1 del bind
# 
# PARAMETROS:
#   value: String - Emitido por fruit_cut
#   was_correct: bool - Emitido por fruit_cut
#   was_in_order: bool - Emitido por fruit_cut (NUEVO)
#   fruit_id: int - Pasado por .bind()
# 
# FLUJO:
# 1. Determina tipo de pregunta basado en valor
# 2. Registra en MetricsTracker (si no es bomba)
# 3. Notifica a GameManager con los 3 parámetros
# ============================================
func _on_fruit_cut(
	value: String,
	was_correct: bool,
	was_in_order: bool,
	fruit_id: int
) -> void:
	print("[Spawner] Fruta cortada:")
	print("          Valor: '", value, "'")
	print("          Correcta: ", was_correct)
	print("          En orden: ", was_in_order)
	
	# Determinar tipo de pregunta
	var question_type = QuestionTypes.determine_type(value)
	print("          Tipo: ", question_type)
	
	# Obtener respuesta correcta del GameManager
	var correct_answer = GameManager.target_word
	
	# NO registrar bombas como preguntas normales
	if value != "BOMB":
		# Registrar en MetricsTracker con datos granulares
		# NOTA: Solo es correcto si AMBOS son true
		MetricsTracker.register_question_attempt(
			fruit_id,                      # ID único de la fruta
			question_type,                 # Tipo determinado automáticamente
			value,                         # Lo que mostraba
			correct_answer,                # Respuesta esperada
			value,                         # Lo que cortó (mismo)
			was_correct and was_in_order,  # Solo correcto si ambos true
			1                              # Difficulty (después usarás current_level.difficulty)
		)
	
	# Notificar a GameManager con los 3 parámetros
	GameManager.register_fruit_cut(value, was_correct, was_in_order)

# ============================================
# NOTAS DE INTEGRACION:
# ============================================
# CAMBIOS RESPECTO A TU VERSION ORIGINAL:
# 1. create_fruit(): Agregué .bind(new_fruit.get_instance_id())
# 2. _on_fruit_cut(): Ahora recibe 4 parámetros en vez de 2
# 3. _on_fruit_cut(): Determina question_type automáticamente
# 4. _on_fruit_cut(): Llama a MetricsTracker.register_question_attempt()
# 
# DEPENDEN DE:
# - QuestionTypes.determine_type() (archivo nuevo que crear)
# - MetricsTracker.register_question_attempt() (función nueva)
# - GameManager.register_fruit_cut() con 3 parámetros (modificado)
# - fruit.gd emitiendo señal con 3 parámetros (modificado)
# ============================================
