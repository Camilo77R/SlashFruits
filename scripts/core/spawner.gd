# scripts/core/spawner.gd
extends Node2D

# ============================================
# ¿QUÉ ES ESTE ARCHIVO?
# Es la "LÍNEA DE PRODUCCIÓN" que crea frutas automáticamente.
# NO sabe reglas del juego, NO valida, NO decide.
# Solo CREA lo que le pidan.
# ============================================

# ============================================
# SECCIÓN: CONFIGURACIÓN (@export)
# ¿QUÉ SON? Variables que aparecen en el INSPECTOR.
# ¿PARA QUÉ? Para cambiar el comportamiento SIN tocar código.
# ============================================

@export var fruit_scene: PackedScene  # Escena fruit.tscn
@export var spawn_rate: float = 1.5   # Segundos entre frutas
@export var spawn_below_screen: float = 100  # Píxeles ABAJO de la pantalla

# ============================================
# SECCIÓN: REFERENCIAS (@onready)
# ¿QUÉ SON? Variables que Godot llena AUTOMÁTICAMENTE al cargar.
# ¿POR QUÉ? Más seguro que usar $NodePath directamente.
# ============================================

@onready var timer: Timer = $Timer

# ============================================
# SECCIÓN: CONTROL DE SPAWNING
# ¿PARA QUÉ? Controlar cuándo crear frutas y cuándo no
# ============================================
var is_spawning_active: bool = true

# ============================================
# FUNCIÓN: _ready()
# ¿CUÁNDO SE EJECUTA? Cuando el Spawner aparece por primera vez.
# ¿QUÉ HACE? Configura el sistema para empezar a trabajar.
# ============================================
func _ready() -> void:
	timer.wait_time = spawn_rate
	print("[Spawner] Sistema de producción INICIADO")
	print("[Spawner] Frecuencia: cada ", spawn_rate, " segundos")

# ============================================
# FUNCIÓN: _on_timer_timeout()
# ¿CUÁNDO SE EJECUTA? Cuando el Timer termina su cuenta.
# ¿QUÉ HACE? Dice "¡Hora de crear otra fruta!".
# CONEXIÓN: Conectada a señal 'timeout' del Timer.
# 
# MODIFICACIÓN: Ahora verifica si spawning está activo
# ¿POR QUÉ? Para detener creación después de Game Over
# ============================================
func _on_timer_timeout() -> void:
	if is_spawning_active:
		create_fruit()

# ============================================
# FUNCIÓN: create_fruit()
# ¿QUÉ HACE? Los pasos CONCRETOS para fabricar UNA fruta.
# ¿POR QUÉ SEPARADA? Para poder crear frutas desde otros lugares también.
# FLUJO LÓGICO: Verificar → Crear → Configurar → Posicionar → Soltar
# ============================================
func create_fruit() -> void:
	# PASO 1: VERIFICAR MATERIA PRIMA
	if fruit_scene == null:
		print("[Spawner] ERROR: No hay escena de fruta asignada")
		return
	
	# PASO 2: FABRICAR LA FRUTA (INSTANCIAR)
	var new_fruit = fruit_scene.instantiate()
	
	# PASO 3: OBTENER VALOR SEGÚN MODO DE JUEGO
	var next_value = get_value_for_current_mode()
	
	# PASO 4: CONFIGURAR FRUTA CON ÁNGULO
	var launch_angle = get_random_launch_angle()
	new_fruit.setup(next_value, launch_angle)
	
	# PASO 5: CONECTAR SEÑAL DE CORTE
	# IMPORTANTE: Usa .bind() para pasar fruit_id junto con la señal
	new_fruit.fruit_cut.connect(_on_fruit_cut.bind(new_fruit.get_instance_id()))
	
	# PASO 6: POSICIONAR EN PANTALLA
	var screen_size = get_viewport().get_visible_rect().size
	new_fruit.position = Vector2(
		randf_range(100, screen_size.x - 100),
		screen_size.y + spawn_below_screen
	)
	
	# PASO 7: AGREGAR AL JUEGO
	add_child(new_fruit)
	
	# PASO 8: REGISTRAR EN MÉTRICAS
	# ¿PARA QUÉ? Para calcular tiempo de reacción después
	MetricsTracker.register_spawn(new_fruit.get_instance_id())

	print("[Spawner] Fruta creada: '", next_value, "' en ", new_fruit.position)

# ============================================
# FUNCIÓN: get_value_for_current_mode()
# ¿QUÉ HACE? Genera valores según el modo actual de juego.
# PRINCIPIO: Spawner PREGUNTA al GameManager qué necesita.
# CULTURA: Letras (70% correctas si hay, 30% aleatorias)
# LÓGICA: Números (70% correctos si hay, 30% aleatorios)
# AMBOS: 10% chance de bomba
# ============================================
func get_value_for_current_mode() -> String:
	print("[Spawner] Generando valor según modo actual...")

	# 1. Chance de bomba (10% en ambos modos)
	if randf() < 0.1:
		print("[Spawner] BOMBA generada!")
		return "BOMB"

	# 2. Preguntar al GameManager QUÉ tipo necesita
	var value_type = GameManager.get_value_type_needed()
	print("[Spawner] GameManager dice que necesita tipo: ", value_type)

	# 3. Preguntar valor específico si hay
	var needed_value = GameManager.get_next_letter()

	# 4. Si hay valor específico necesario, 70% chance de darlo
	if needed_value != "" and randf() < 0.7:
		print("[Spawner] Dando valor necesario: '", needed_value, "'")
		return needed_value

	# 5. Generar valor aleatorio según el TIPO que necesita
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

# ============================================
# FUNCIÓN: get_random_launch_angle()
# ¿QUÉ HACE? Genera ángulo aleatorio para física tipo Fruit Ninja.
# VALORES FRUIT NINJA: X para lateral, Y negativo para subir.
# ============================================
func get_random_launch_angle() -> Vector2:
	var angle_x = randf_range(-310, 310)    # Movimiento lateral
	var angle_y = randf_range(-1100, -900)  # Fuerza hacia arriba (negativo)
	return Vector2(angle_x, angle_y)

# ============================================
# FUNCIÓN: get_random_alphabet_letter()
# ¿QUÉ HACE? Letra aleatoria A-Z para modo CULTURA.
# ============================================
func get_random_alphabet_letter() -> String:
	var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var letter = alphabet[randi() % alphabet.length()]
	print("[Spawner] Letra aleatoria: ", letter)
	return letter

# ============================================
# FUNCIÓN: get_random_number()
# ¿QUÉ HACE? Número aleatorio 0-9 para modo LÓGICA.
# ============================================
func get_random_number() -> String:
	var numbers = "0123456789"
	var number = numbers[randi() % numbers.length()]
	print("[Spawner] Número aleatorio: ", number)
	return number

# ============================================
# FUNCIÓN: _on_fruit_cut()
# ¿CUÁNDO SE EJECUTA? Cuando una fruta es cortada.
# ¿QUÉ HACE? Recibe mensaje y lo reenvía al GameManager.
# PRINCIPIO: Spawner es solo "mensajero", no procesa lógica.
# 
# PARÁMETROS:
#   value: String - El valor de la fruta ("A", "5", "BOMB")
#   was_correct: bool - Si es correcta (de Fruit)
#   was_in_order: bool - Si es la que tocaba (de Fruit)
#   fruit_id: int - ID pasado por .bind()
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
	
	# Determinar tipo de pregunta usando QuestionTypes
	var question_type = QuestionTypes.determine_type(value)
	print("          Tipo: ", question_type)
	
	# Obtener respuesta correcta del GameManager
	var correct_answer = GameManager.target_word
	
	# Obtener dificultad del nivel actual
	var difficulty = 1
	if GameManager.current_level != null:
		difficulty = GameManager.current_level.difficulty
	
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
			difficulty                     # Dificultad del nivel actual
		)
	
	# Notificar a GameManager con los 3 parámetros
	GameManager.register_fruit_cut(value, was_correct, was_in_order)

# ============================================
# FUNCIÓN: stop_spawning()
# ¿QUÉ HACE? Detiene la creación de frutas
# ¿CUÁNDO USAR? Al terminar el juego (Game Over o Victoria)
# ¿QUIÉN LA LLAMA? GameManager cuando el juego termina
# ============================================
func stop_spawning() -> void:
	is_spawning_active = false
	print("[Spawner] Producción detenida")

# ============================================
# FUNCIÓN: start_spawning()
# ¿QUÉ HACE? Reinicia la creación de frutas
# ¿CUÁNDO USAR? Al iniciar un nuevo nivel
# ¿QUIÉN LA LLAMA? GameManager al cargar nuevo nivel
# ============================================
func start_spawning() -> void:
	is_spawning_active = true
	print("[Spawner] Producción reiniciada")

# ============================================
# NOTAS IMPORTANTES:
# ============================================
# 1. CONEXIÓN DE TIMER:
#    - En el editor, asegúrate de conectar la señal "timeout" 
#      del nodo Timer a la función _on_timer_timeout()
#
# 2. ESCENA DE FRUTA:
#    - Asigna fruit.tscn en la variable @export fruit_scene
#    - Hazlo desde el Inspector cuando selecciones el Spawner
#
# 3. CONTROL DE SPAWNING:
#    - is_spawning_active permite detener/reiniciar producción
#    - Útil para pausas, game over, transiciones
#
# 4. INTEGRACIÓN CON MÉTRICAS:
#    - Cada fruta creada se registra en MetricsTracker
#    - Permite calcular tiempo de reacción preciso
# ============================================
