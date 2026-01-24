# scripts/data/question_loader.gd
extends Node


# Agregar al principio:
signal levels_loaded  # ← NUEVA SEÑAL


# Esta clase CARGA y MANEJA todos los niveles del juego
# Es como una "biblioteca de preguntas"

const CULTURE_PATH = "res://assets/data/levels_culture.json"
const LOGIC_PATH = "res://assets/data/levels_logic.json"
#res://assets/data/
var culture_levels: Array = []
var logic_levels: Array = []






func _ready() -> void:
	print("[QuestionLoader] Iniciando...")
	load_all_levels()
	levels_loaded.emit()  # ← EMITIR cuando termine



func load_all_levels() -> void:
	culture_levels = _load_json(CULTURE_PATH)
	logic_levels = _load_json(LOGIC_PATH)
	print("[QuestionLoader] Cargados: ", culture_levels.size(), " cultura, ", logic_levels.size(), " lógica")

func _load_json(path: String) -> Array:
	var levels = []
	
	if not FileAccess.file_exists(path):
		print("[QuestionLoader] ❌ Archivo no existe: ", path)
		return levels
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) != OK:
		print("[QuestionLoader] ❌ Error JSON: ", json.get_error_message())
		return levels
	
	for data in json.get_data():
		var level = LevelData.from_json(data)
		if level and level.id != "" and level.correct_answer != "":
			levels.append(level)
	
	return levels

func get_random_level(game_type: String, max_difficulty: int = 5) -> LevelData:
	var pool = culture_levels if game_type == "culture" else logic_levels
	
	if pool.is_empty():
		print("[QuestionLoader] ⚠️ No hay niveles, creando default")
		return _create_default_level(game_type)
	
	# Filtrar por dificultad
	var filtered = []
	for level in pool:
		if level.difficulty <= max_difficulty:
			filtered.append(level)
	
	if filtered.is_empty():
		return pool[0]  # Tomar cualquier nivel si ninguno cumple
	
	return filtered[randi() % filtered.size()]

func _create_default_level(game_type: String) -> LevelData:
	var level = LevelData.new()
	level.id = "default_" + str(Time.get_unix_time_from_system())
	level.game_id = game_type
	level.question = "Pregunta de ejemplo"
	level.correct_answer = "GATO" if game_type == "culture" else "13"
	return level
