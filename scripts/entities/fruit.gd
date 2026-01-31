# scripts/entities/fruit.gd
extends Area2D

# ============================================
# DESCRIPCION:
# Representa una fruta individual en el juego.
# Responsabilidades:
#   - Moverse con fisica (lanzamiento + gravedad)
#   - Detectar cuando es cortada (input)
#   - Validar si el corte es correcto Y en el orden adecuado
#   - Emitir señal para notificar al sistema
# 
# ANALOGIA:
# Es como un "actor" en una obra de teatro.
# Sabe su papel (que letra representa) y cuando actuar (ser cortada),
# pero NO conoce toda la trama del juego (eso es trabajo del GameManager).
# ============================================

# ============================================
# SEÑALES
# ============================================
# QUE: Notifica cuando esta fruta fue cortada
# CUANDO: En el momento exacto del input del jugador
# PARAMETROS:
#   value: String - El valor que representa (ej: "G", "5", "bomba")
#   was_correct: bool - Si esta letra/numero esta en la respuesta
#   was_in_order: bool - Si era la letra que tocaba EN ESTE MOMENTO
signal fruit_cut(value: String, was_correct: bool, was_in_order: bool)

# ============================================
# CONFIGURACION EXPORTADA
# ============================================
# QUE: Variables editables desde el Inspector de Godot
# PARA QUE: Ajustar comportamiento sin modificar codigo
# DONDE VER: Selecciona el nodo Fruit en el editor -> Panel Inspector (derecha)
@export var launch_power: Vector2 = Vector2(0, -950)

# ============================================
# VARIABLES INTERNAS (ESTADO)
# ============================================
# CONVENCION: Variables con _ son privadas (solo esta clase las modifica)

# El valor que representa esta fruta ("G", "A", "5", etc.)
var _fruit_value: String = ""

# Indica si esta letra/numero aparece en la palabra objetivo
# EJEMPLO: Si palabra es "GATO", entonces "A" es correcta (true), pero "X" no (false)
var _is_correct_letter: bool = false

# Indica si esta letra es la que el jugador debe cortar AHORA MISMO
# EJEMPLO: Si palabra es "GATO" y ya corto "G", ahora solo "A" tendra esto en true
var _is_in_correct_order: bool = false

# Indica si este objeto es una bomba (cambia comportamiento)
var _is_bomb: bool = false

# Estado de fisica
var _velocity: Vector2 = Vector2.ZERO
var _gravity: float = 980.0

# Previene procesar corte multiples veces
var _is_cut: bool = false

# ============================================
# FUNCION: _ready()
# CUANDO SE EJECUTA: Una sola vez, cuando el nodo entra al arbol de escena
# QUE HACE: Inicializacion basica (en este caso, solo logging)
# DONDE ESTA EN EL FLUJO: Justo despues de que Spawner hace add_child(fruit)
# ============================================
func _ready() -> void:
	print("[Fruit] Fruta creada con ID: ", get_instance_id())

# ============================================
# FUNCION: setup()
# QUE: Configura esta fruta con sus propiedades especificas
# CUANDO: Inmediatamente despues de instanciar, ANTES de add_child()
# QUIEN LA LLAMA: Spawner, desde su funcion create_fruit()
# POR QUE EXISTE: Para separar creacion (instanciar) de configuracion (setup)
# 
# FLUJO COMPLETO:
# 1. Spawner crea fruta: var fruit = fruit_scene.instantiate()
# 2. Spawner configura: fruit.setup("G", Vector2(100, -950))
# 3. Spawner agrega al juego: add_child(fruit)
# 4. Se ejecuta _ready()
# ============================================
func setup(letter: String, launch_angle: Vector2 = Vector2.ZERO) -> void:
	_fruit_value = letter
	
	# CASO ESPECIAL: Bomba
	if _fruit_value == "BOMB":
		_is_bomb = true
		_is_correct_letter = false
		_is_in_correct_order = false
		print("[Fruit] Configurada como BOMBA")
	else:
		# Preguntamos al GameManager sobre esta letra
		# ANALOGIA: Como un estudiante preguntando al profesor "¿esta es la respuesta?"
		_is_in_correct_order = GameManager.is_next_letter_in_sequence(_fruit_value)
		_is_correct_letter = GameManager.is_letter_in_word(_fruit_value)
		
		print("[Fruit] Letra configurada: '", _fruit_value, "'")
		print("        Esta en la palabra: ", _is_correct_letter)
		print("        Es la que toca ahora: ", _is_in_correct_order)
	
	# Cargar sprite visual
	_load_sprite_for_value(_fruit_value)
	
	# Configurar velocidad inicial
	if launch_angle != Vector2.ZERO:
		_velocity = launch_angle
	else:
		_velocity = launch_power
	
	print("[Fruit] Velocidad inicial: ", _velocity)

# ============================================
# FUNCION: _load_sprite_for_value()
# QUE: Carga la textura visual apropiada segun el valor
# DONDE BUSCA: En assets/sprites/letters/, numbers/ o special/
# 
# ESTRUCTURA DE CARPETAS ESPERADA:
# assets/sprites/
#   letters/
#     fruit-a.png
#     fruit-b.png
#     ...
#   numbers/
#     number-0.png
#     number-1.png
#     ...
#   special/
#     bomb-black.png
# 
# NOTA: Si el sprite no existe, crea un Label temporal como fallback
# ============================================
func _load_sprite_for_value(value: String) -> void:
	var clean_value = value.strip_edges()
	var folder = ""
	var file_name = ""
	
	# Determinar carpeta y nombre de archivo segun el tipo
	if clean_value.length() == 1:
		var char_code = clean_value.unicode_at(0)
		
		# Es una letra (A-Z)
		if (char_code >= 65 and char_code <= 90) or (char_code >= 97 and char_code <= 122):
			folder = "letters"
			file_name = "fruit-%s.png" % clean_value.to_lower()
		
		# Es un numero (0-9)
		elif char_code >= 48 and char_code <= 57:
			folder = "numbers"
			file_name = "number-%s.png" % clean_value
	
	# Caso especial: bomba
	elif clean_value == "BOMB":
		folder = "special"
		file_name = "bomb-black.png"
	
	# Si no pudimos determinar el tipo, usar fallback
	if folder == "":
		print("[Fruit] Valor no reconocido, usando fallback: ", clean_value)
		_create_fallback_label(clean_value)
		return
	
	# Construir ruta completa y cargar
	var sprite_path = "res://assets/sprites/%s/%s" % [folder, file_name]
	
	if not ResourceLoader.exists(sprite_path):
		print("[Fruit] Sprite no encontrado en: ", sprite_path)
		_create_fallback_label(clean_value)
		return
	
	var texture = load(sprite_path)
	
	# IMPORTANTE: Tu escena fruit.tscn debe tener un nodo Sprite2D como hijo
	# DONDE VERIFICAR: Abre scenes/fruit.tscn y confirma que existe Sprite2D
	if has_node("Sprite2D"):
		$Sprite2D.texture = texture
		print("[Fruit] Sprite cargado exitosamente")
	else:
		print("[Fruit] ERROR: No existe nodo Sprite2D en fruit.tscn")
		print("        SOLUCION: Abre fruit.tscn y agrega un Sprite2D como hijo del Area2D")
		_create_fallback_label(clean_value)

# ============================================
# FUNCION: _create_fallback_label()
# QUE: Crea un texto visible cuando no hay sprite
# PARA QUE: Debugging visual - ver que valor tiene la fruta
# CUANDO USAR: Solo durante desarrollo, en produccion todos los sprites deben existir
# ============================================
func _create_fallback_label(text: String) -> void:
	var label = Label.new()
	label.name = "FallbackLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-20, -20)
	add_child(label)
	print("[Fruit] Fallback label creado con texto: '", text, "'")

# ============================================
# FUNCION: _physics_process()
# CUANDO SE EJECUTA: 60 veces por segundo (en cada frame de fisica)
# QUE HACE: Actualiza posicion aplicando gravedad
# 
# FISICA BASICA:
# - Gravedad aumenta velocidad hacia abajo (Y positivo)
# - Velocidad cambia la posicion
# - Delta es el tiempo transcurrido (para movimiento suave independiente de FPS)
# 
# ANALOGIA: Como una pelota que lanzas al aire
# - Al principio sube rapido (velocity.y negativo)
# - La gravedad la frena y luego la acelera hacia abajo
# - Eventualmente cae fuera de pantalla
# ============================================
func _physics_process(delta: float) -> void:
	# Aplicar gravedad (aumenta velocidad hacia abajo)
	_velocity.y += _gravity * delta
	
	# Aplicar velocidad a la posicion
	position += _velocity * delta
	
	# TODO: Detectar cuando sale de pantalla (perder vida si no fue cortada)
	# Esto se implementara cuando tengas el sistema de vidas funcionando

# ============================================
# FUNCION: _on_input_event()
# CUANDO SE EJECUTA: Cuando el jugador hace clic/tap sobre esta Area2D
# COMO SE CONECTA: En el editor, selecciona el nodo Fruit -> Panel Node (izquierda)
#                  -> Pestaña Signals -> Doble clic en "input_event"
#                  -> Conectar a esta funcion
# 
# PARAMETROS (Godot los pasa automaticamente):
#   viewport: El viewport donde ocurrio el evento (no lo usamos)
#   event: El evento de input (clic, tap, etc)
#   shape_idx: Indice de la forma de colision (no lo usamos)
# 
# DONDE CONFIGURAR LA COLISION:
# 1. Abre scenes/fruit.tscn
# 2. Selecciona el nodo Area2D
# 3. Agrega un CollisionShape2D como hijo
# 4. En Inspector, asigna una forma (CircleShape2D recomendado)
# ============================================
func _on_input_event(_viewport, event, _shape_idx):
	# Verificar que sea un clic/tap (no arrastre ni otro tipo)
	if event is InputEventMouseButton and event.pressed:
		print("[Fruit] Input detectado - procesando corte")
		_process_cut()

# ============================================
# FUNCION: _process_cut()
# QUE: Maneja toda la logica de "ser cortada"
# CUANDO: Llamada desde _on_input_event() cuando detecta clic
# 
# FLUJO COMPLETO:
# 1. Verificar que no fue cortada antes (seguridad)
# 2. Marcar como cortada
# 3. Determinar tipo de corte (bomba / correcto / error)
# 4. Emitir señal apropiada
# 5. Ejecutar efecto visual (placeholder para UI/UX)
# 6. Destruirse
# 
# CASOS POSIBLES:
# A) Es bomba -> Game Over inmediato
# B) Letra correcta Y en orden -> Acierto
# C) Letra correcta pero fuera de orden -> Error
# D) Letra incorrecta -> Error
# ============================================
func _process_cut() -> void:
	# PASO 1: Seguridad - evitar procesar corte multiple
	if _is_cut:
		print("[Fruit] Ya fue cortada, ignorando")
		return
	
	_is_cut = true
	
	# CASO A: BOMBA
	# QUE PASA: Game over inmediato, sin importar vidas
	# QUIEN MANEJA: GameManager.handle_bomb_cut()
	if _is_bomb:
		print("[Fruit] BOMBA cortada - notificando game over")
		fruit_cut.emit(_fruit_value, false, false)
		_play_bomb_effect()
		queue_free()
		return
	
	# CASO B: LETRA CORRECTA Y EN ORDEN
	# QUE PASA: Suma puntos, avanza al siguiente indice, incrementa combo
	# QUIEN MANEJA: GameManager.handle_correct_letter()
	if _is_in_correct_order:
		print("[Fruit] CORRECTO - Letra '", _fruit_value, "' en orden")
		fruit_cut.emit(_fruit_value, true, true)
		_play_correct_effect()
		queue_free()
		return
	
	# CASO C: LETRA CORRECTA PERO FUERA DE ORDEN
	# QUE PASA: Resta vida, resetea combo, NO avanza indice
	# EJEMPLO: Si palabra es "GATO" y ya corto "G", cortar "T" es este caso
	# QUIEN MANEJA: GameManager.handle_wrong_letter()
	if _is_correct_letter and not _is_in_correct_order:
		print("[Fruit] ERROR - Letra '", _fruit_value, "' correcta pero fuera de orden")
		fruit_cut.emit(_fruit_value, false, false)
		_play_wrong_order_effect()
		queue_free()
		return
	
	# CASO D: LETRA INCORRECTA
	# QUE PASA: Resta vida, resetea combo
	# EJEMPLO: Si palabra es "GATO", cortar "X" es este caso
	# QUIEN MANEJA: GameManager.handle_wrong_letter()
	print("[Fruit] ERROR - Letra '", _fruit_value, "' incorrecta")
	fruit_cut.emit(_fruit_value, false, false)
	_play_wrong_effect()
	queue_free()

# ============================================
# FUNCIONES DE EFECTOS VISUALES
# ============================================
# ESTADO: Placeholders (funciones vacias)
# QUIEN DEBE IMPLEMENTARLAS: Tu compañero de UI/UX
# COMO IMPLEMENTAR: Agregar nodos como Particles2D, AnimationPlayer, AudioStreamPlayer
# DONDE: Como hijos en scenes/fruit.tscn
# 
# RECURSOS A USAR:
# - Particles2D para efectos de particulas
# - AnimationPlayer para animaciones
# - AudioStreamPlayer2D para sonidos
# 
# EJEMPLO DE IMPLEMENTACION (para tu compañero):
# func _play_correct_effect() -> void:
#     if has_node("CorrectParticles"):
#         $CorrectParticles.emitting = true
#     if has_node("CorrectSound"):
#         $CorrectSound.play()
# ============================================

func _play_bomb_effect() -> void:
	# TODO UI/UX: Animacion de explosion, sonido fuerte, screen shake
	print("[Fruit] Efecto bomba (pendiente implementar)")

func _play_correct_effect() -> void:
	# TODO UI/UX: Particulas verdes/estrellas, sonido alegre
	print("[Fruit] Efecto acierto (pendiente implementar)")

func _play_wrong_order_effect() -> void:
	# TODO UI/UX: Particulas naranjas, sonido de advertencia
	print("[Fruit] Efecto orden incorrecto (pendiente implementar)")

func _play_wrong_effect() -> void:
	# TODO UI/UX: Particulas rojas, sonido de error
	print("[Fruit] Efecto error (pendiente implementar)")

# ============================================
# GETTERS (FUNCIONES DE ACCESO)
# ============================================
# QUE SON: Funciones que permiten leer variables privadas
# POR QUE: Encapsulamiento - controlar como se accede a datos internos
# QUIEN LAS USA: Otros scripts que necesiten saber propiedades de la fruta

func get_fruit_value() -> String:
	return _fruit_value

func is_in_correct_order() -> bool:
	return _is_in_correct_order

func is_bomb() -> bool:
	return _is_bomb

# ============================================
# NOTAS IMPORTANTES:
# ============================================
# 1. DONDE VA ESTE ARCHIVO: scripts/entities/fruit.gd
# 2. ESCENA RELACIONADA: scenes/fruit.tscn
# 3. NODOS REQUERIDOS EN fruit.tscn:
#    - Area2D (raiz)
#      - Sprite2D (para visual)
#      - CollisionShape2D (para deteccion de clic)
# 4. SEÑAL A CONECTAR: input_event -> _on_input_event()
# 5. AUTOLOAD NECESARIO: GameManager (ya configurado)
# ============================================
