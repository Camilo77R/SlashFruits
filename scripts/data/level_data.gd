# scripts/data/level_data.gd
class_name LevelData
extends RefCounted

# Esta clase REPRESENTA una pregunta/nivel del juego
# Es SOLO datos, no tiene lógica de juego

var id: String
var game_id: String          # "culture" o "logic"
var category: String         # "capitales", "sumas"
var question: String         # Texto para mostrar
var correct_answer: String   # Respuesta correcta (ej: "PARIS")
var difficulty: int = 1      # 1=fácil, 5=difícil

static func from_json(data: Dictionary) -> LevelData:
	var level = LevelData.new()
	level.id = data.get("id", "")
	level.game_id = data.get("game_id", "")
	level.category = data.get("category", "")
	level.question = data.get("question", "")
	level.correct_answer = data.get("correct_answer", "")
	level.difficulty = data.get("difficulty", 1)
	return level
