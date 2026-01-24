# scripts/entities/fruit.gd
extends Area2D

# ============================================
# ¿QUÉ ES ESTE ARCHIVO?
# Es el "ACTOR" o "PERSONAJE" fruta en el juego.
# Sabe: cómo verse, cómo moverse, cómo ser cortada.
# NO sabe: reglas del juego, si es correcta o no.
# ============================================

# ============================================
# SEÑAL: fruit_cut
# ¿QUÉ ES? Un "GRITO" que la fruta emite cuando la cortan.
# ¿PARA QUÉ? Para avisar a otros sin saber quiénes son.
# PARÁMETROS:
#   - value: String = la letra que representa (ej: "G")
#   - was_correct: bool = si era correcta según GameManager
# ============================================
signal fruit_cut(value: String, was_correct: bool)

# ============================================
# SECCIÓN: CONFIGURACIÓN FÍSICA (@export)
# ¿QUÉ SON? Valores que aparecen en Inspector para variantes.
# Ejemplo: puedes crear FrutaRápida y FrutaLenta con distintos launch_power.
# ============================================

# Fuerza inicial de lanzamiento (impulso hacia arriba)
# Vector2(0, -950) = 0 en X (horizontal), -950 en Y (vertical, negativo = arriba)
@export var launch_power: Vector2 = Vector2(0, -950)




# ============================================
# SECCIÓN: ESTADO INTERNO (PRIVADO)
# ¿QUÉ SON? Variables que solo esta fruta conoce y modifica.
# ¿POR QUÉ PRIVADAS? Para controlar cómo se modifican (encapsulamiento).
# ============================================

# Letra/número que representa esta fruta (ej: "G", "7")
# PRIVADA: Solo se modifica mediante setup()
var _fruit_value: String = "A"

# ¿Era una fruta correcta según las reglas del juego?
# PRIVADA: Se calcula preguntando al GameManager
var _is_correct: bool = false

# Velocidad actual (cambia por gravedad)
var _velocity: Vector2 = Vector2.ZERO

# Fuerza de gravedad (píxeles/segundo²)
# 980 = similar a gravedad real, ajustable para dificultad
var _gravity: float = 980.0

# ¿Ya fue cortada? Evita cortarla dos veces
var _is_cut: bool = false

# ============================================
# FUNCIÓN: _ready()
# ¿CUÁNDO SE EJECUTA? Cuando la fruta aparece por primera vez.
# ¿QUÉ HACE? Configura el movimiento inicial.
# ANALOGÍA: Es el "DESPEGUE" de la fruta.
# ============================================
func _ready() -> void:

	
	# 2. Mensaje de depuración (solo desarrollo)
	print("[Fruit] ¡Nacida! ID: ", self.get_instance_id())
	print("[Fruit] Fuerza inicial: ", launch_power)

# ============================================
# FUNCIÓN: setup() - ¡NUEVA E IMPORTANTE!
# ¿QUÉ HACE? Configura la fruta cuando el Spawner la crea.
# ¿POR QUÉ EXISTE? Para que la fruta NO se autoconfigure.
# ¿CÓMO SE USA? Spawner llama: new_fruit.setup("G")
# ============================================
func setup(letter: String, launch_angle: Vector2 = Vector2.ZERO) -> void:
	print("[Fruit] Configurando...")

	_fruit_value = letter
	_is_correct = GameManager.is_letter_correct(_fruit_value)

	# NUEVO: Cargar sprite visual
	_load_sprite_for_value(_fruit_value)
	

	# DECISIÓN: ¿Usar ángulo personalizado o el por defecto?
	if launch_angle != Vector2.ZERO:
		# ¡ÁNGULO PERSONALIZADO DEL SPAWNER!
		_velocity = launch_angle
		print("[Fruit] 🎯 Velocidad CON ÁNGULO: ", _velocity)
		print("[Fruit]   X: ", _velocity.x, " (lateral)")
		print("[Fruit]   Y: ", _velocity.y, " (vertical)")

		# Diagnóstico del movimiento:
		if _velocity.x < -150:
			print("[Fruit]   ↖️ FUERTE a la IZQUIERDA")
		elif _velocity.x < 0:
			print("[Fruit]   ⬅️ Suave a la IZQUIERDA")
		elif _velocity.x > 150:
			print("[Fruit]   ↗️ FUERTE a la DERECHA")
		elif _velocity.x > 0:
			print("[Fruit]   ➡️ Suave a la DERECHA")
		else:
			print("[Fruit]   ⬆️ Recto hacia ARRIBA")
			
	else:
		# Fallback: usar el valor por defecto del Inspector
		_velocity = launch_power
		print("[Fruit] ⚠️ Sin ángulo, usando valor por defecto: ", _velocity)

	print("[Fruit] Letra: ", _fruit_value, " | Correcta: ", _is_correct)
	print("[Fruit] Velocidad FINAL: ", _velocity)




# En fruit.gd, agrega esta función después de setup():

# ============================================
# FUNCIÓN: _load_sprite_for_value()
# ¿QUÉ HACE? Carga el sprite correspondiente según la letra/número
# ¿POR QUÉ? Para mostrar imágenes reales en lugar de solo texto
# FLUJO: Letra "A" → busca "fruit-a.png" en carpeta fruits/
#        Número "5" → busca "5.png" en carpeta numbers/
#        Bomba "💣" → busca "bomb-black.png" en carpeta special/
# ============================================
func _load_sprite_for_value(value: String) -> void:
	print("[Fruit] 🔍 Buscando sprite para: '", value, "'")

	# PASO 1: Limpiar y normalizar el valor
	var clean_value = value.strip_edges()

	# PASO 2: Determinar qué carpeta buscar
	var folder = ""
	var file_name = ""

	if clean_value.length() == 1:
		var char_code = clean_value.unicode_at(0)
		
		# CASO A: ES UNA LETRA (A-Z)
		if (char_code >= 65 and char_code <= 90) or (char_code >= 97 and char_code <= 122):
			folder = "letters"
			# Convertir a minúscula para nombre de archivo
			file_name = "fruit-%s.png" % clean_value.to_lower()
			print("[Fruit]   Tipo: Letra → carpeta: ", folder, ", archivo: ", file_name)
		
		# CASO B: ES UN NÚMERO (0-9)
		elif char_code >= 48 and char_code <= 57:
			folder = "numbers"
			file_name = "number-%s.png" % clean_value  # "5.png" no "fruit-5.png"
			print("[Fruit]   Tipo: Número → carpeta: ", folder, ", archivo: ", file_name)
		
		# CASO C: ES BOMBA (💣)
		elif clean_value == "💣":
			folder = "special"
			file_name = "bomb-black.png"
			print("[Fruit]   Tipo: Bomba → carpeta: ", folder, ", archivo: ", file_name)
		
		else:
			print("[Fruit] ⚠️ Carácter no reconocido: ", clean_value)
			_create_fallback_label(clean_value)
			return

	else:
		print("[Fruit] ⚠️ Valor tiene más de 1 carácter: ", clean_value)
		_create_fallback_label(clean_value)
		return

	# PASO 3: Construir la ruta completa
	var sprite_path = "res://assets/sprites/%s/%s" % [folder, file_name]
	print("[Fruit]   Ruta completa: ", sprite_path)

	# PASO 4: Verificar si el archivo existe
	if not ResourceLoader.exists(sprite_path):
		print("[Fruit] ❌ ERROR: Archivo no encontrado: ", sprite_path)
		print("[Fruit]   Verifica que exista: assets/sprites/", folder, "/", file_name)
		_create_fallback_label(clean_value)
		return

	# PASO 5: Cargar la textura
	var texture = load(sprite_path)

	# PASO 6: Aplicar la textura al Sprite2D
	# IMPORTANTE: Asegúrate que tu fruit.tscn tenga un nodo Sprite2D
	if has_node("Sprite2D"):
		$Sprite2D.texture = texture
		print("[Fruit] ✅ Sprite cargado exitosamente!")
	else:
		print("[Fruit] ❌ ERROR: No hay nodo 'Sprite2D' en la escena")
		print("[Fruit]   Abre fruit.tscn y agrega un Sprite2D como hijo")
		_create_fallback_label(clean_value)

# ============================================
# FUNCIÓN: _create_fallback_label()
# ¿QUÉ HACE? Crea un Label temporal si no se puede cargar el sprite
# ¿POR QUÉ? Para debugging - ver qué valor debería mostrar
# ============================================
func _create_fallback_label(text: String) -> void:
	print("[Fruit] 🛠️ Creando fallback label...")

	var label = Label.new()
	label.name = "FallbackLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Posicionar en el centro
	label.position = Vector2(-20, -20)  # Ajusta según necesites

	add_child(label)
	print("[Fruit]   Label creado con texto: '", text, "'")



# ============================================
# FUNCIÓN: _physics_process()
# ¿CUÁNDO SE EJECUTA? 60 veces por segundo (física).
# ¿QUÉ HACE? Actualiza el movimiento usando gravedad.
# PARÁMETRO: delta = tiempo desde último frame (segundos).
# ¿POR QUÉ USAR delta? Para movimiento SMOOTH a cualquier FPS.
# ============================================
func _physics_process(delta: float) -> void:
	# ============================================
	# APLICAR GRAVEDAD
	# Fórmula física: v = v₀ + a·t
	# _velocity.y aumenta hacia abajo cada frame
	# ============================================
	_velocity.y += _gravity * delta
	
	# ============================================
	# APLICAR MOVIMIENTO
	# Fórmula física: p = p₀ + v·t
	# position cambia según velocidad
	# ============================================
	position += _velocity * delta
	
	# ============================================
	# DETECCIÓN DE SALIDA DE PANTALLA (FUTURO)
	# TODO: Si sale por abajo, avisar para perder vida
	# ============================================
	# if position.y > screen_height:
	#     _handle_screen_exit()

# ============================================
# FUNCIÓN: _on_input_event()
# ¿CUÁNDO SE EJECUTA? Cuando el jugador interactúa con esta Area2D.
# ¿QUÉ DETECTA? Clic de ratón o toque táctil.
# CONEXIÓN: Conectada a señal 'input_event' del nodo Area2D.
# ============================================
func _on_input_event(viewport, event, shape_idx):
	# ============================================
	# VERIFICAR: ¿Fue un clic/tap (no arrastre)?
	# InputEventMouseButton = evento de botón del mouse
	# event.pressed = true cuando se PRESIONA (no cuando se suelta)
	# ============================================
	if event is InputEventMouseButton and event.pressed:
		print("[Fruit] ¡Interacción detectada! Alguien me tocó")
		_process_cut()

# ============================================
# FUNCIÓN: _process_cut()
# ¿QUÉ HACE? Contiene toda la lógica de "ser cortada".
# ¿POR QUÉ SEPARADA? Para mantener _on_input_event() limpia.
# ANALOGÍA: Es el "PROTOCOLO DE DESTRUCCIÓN".
# ============================================
func _process_cut() -> void:
	print("[Fruit] Iniciando protocolo de corte...")
	
	# ============================================
	# PASO 1: VERIFICAR SEGURIDAD
	# ¿Ya estaba cortada? Evitar cortar dos veces (bug).
	# ============================================
	if _is_cut:
		print("[Fruit] ❌ ERROR: Ya estaba cortada, ignorando")
		return  # Salir temprano
	
	# ============================================
	# PASO 2: MARCAR COMO CORTADA
	# Cambiar estado para no procesar más cortes.
	# ============================================
	_is_cut = true
	print("[Fruit] Estado cambiado: _is_cut = true")
	
	# ============================================
	# PASO 3: EMITIR SEÑAL DE CORTE
	# "¡GRITO!" para que otros se enteren.
	# PARÁMETROS: mi letra y si era correcta.
	# ============================================
	print("[Fruit] 🗣️ EMITIENDO señal: fruit_cut")
	print("[Fruit] Mensaje: 'Letra = ", _fruit_value, ", Correcta = ", _is_correct, "'")
	fruit_cut.emit(_fruit_value, _is_correct)
	
	# ============================================
	# PASO 4: EFECTOS VISUALES/SONIDOS (FUTURO)
	# TODO: Animación, partículas, sonido
	# ============================================
	# _play_cut_animation()
	# _play_cut_sound()
	
	# ============================================
	# PASO 5: AUTO-DESTRUIRSE
	# queue_free() = pedir a Godot que nos elimine (seguro).
	# NO usar free() directamente (puede causar errores).
	# ============================================
	print("[Fruit] Solicitando auto-destrucción...")
	queue_free()
	print("[Fruit] ✅ Destrucción programada")
	print("[Fruit] ¡ADIÓS! Letra: ", _fruit_value)
	print("────────────────────────────────────────")

# ============================================
# FUNCIÓN: get_fruit_value() - GETTER
# ¿QUÉ HACE? Devuelve la letra de la fruta (solo lectura).
# ¿POR QUÉ? Para que otros lean pero NO modifiquen.
# PATRÓN: Getter/Setter (encapsulamiento).
# ============================================
func get_fruit_value() -> String:
	return _fruit_value

# ============================================
# FUNCIÓN: was_correct() - GETTER  
# ¿QUÉ HACE? Devuelve si era correcta (solo lectura).
# ¿POR QUÉ? Para consultas externas controladas.
# ============================================
func was_correct() -> bool:
	return _is_correct

# ============================================
# FUNCIÓN: _handle_screen_exit() - FUTURO
# ¿QUÉ HARÁ? Cuando la fruta sale por abajo sin ser cortada.
# ¿PARA QUÉ? Para restar vidas al jugador.
# ============================================
# func _handle_screen_exit() -> void:
#     print("[Fruit] ¡Salí de pantalla sin ser cortada!")
#     # Emitir señal screen_exited para GameManager
#     # screen_exited.emit(_fruit_value, _is_correct)
#     queue_free()

# ============================================
# CONSEJOS DE BUENA PRÁCTICA APLICADOS:
# 1. ENCAPSULAMIENTO: Variables privadas (_nombre)
# 2. GETTERS: Acceso controlado a datos
# 3. UNA FUNCIÓN = UNA RESPONSABILIDAD
# 4. VERIFICACIONES TEMPRANAS (_is_cut check)
# 5. MENSAJES DE DEPURACIÓN claros
# 6. SEPARACIÓN: Fruta no sabe reglas, solo pregunta
# ============================================
