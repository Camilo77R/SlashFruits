# scripts/core/metrics_tracker.gd
extends Node

# ============================================
# VERSION MEJORADA - Métricas Granulares
# Compatible con tu código actual
# ============================================
# QUE ES:
# Sistema que guarda CADA pregunta individual con todos sus detalles.
# No solo promedios, sino datos específicos para análisis.
# 
# MEJORA RESPECTO A VERSION ANTERIOR:
# Antes: Solo guardaba promedios (accuracy general, tiempo promedio)
# Ahora: Guarda array de intentos individuales con tipo, tiempo, combo
# ============================================

# ============================================
# CLASE INTERNA: QuestionAttempt
# ============================================
# QUE ES:
# Representa UN intento de pregunta (un corte de fruta).
# 
# POR QUE CLASE:
# Para organizar datos relacionados en una estructura.
# ============================================
class QuestionAttempt:
	var question_type: String       # "letras_vocales", "sumas_simples", etc.
	var question_data: Dictionary   # {"question": "A", "correct": "GATO"}
	var user_answer: String         # Lo que cortó
	var is_correct: bool            # true/false
	var reaction_time_ms: int       # Milisegundos
	var difficulty_level: int       # 1-5
	var attempt_number: int         # Pregunta #1, #2, #3...
	var current_combo: int          # Racha actual
	var timestamp: int              # UNIX time
	
	func to_dict() -> Dictionary:
		return {
			"question_type": question_type,
			"question_data": question_data,
			"user_answer": user_answer,
			"is_correct": is_correct,
			"reaction_time_ms": reaction_time_ms,
			"difficulty_level": difficulty_level,
			"attempt_number": attempt_number,
			"current_combo": current_combo,
			"timestamp": timestamp
		}

# ============================================
# VARIABLES INTERNAS
# ============================================

# NUEVAS VARIABLES (métricas granulares)
var current_attempts: Array[QuestionAttempt] = []
var current_attempt_number: int = 0
var current_combo: int = 0
var max_combo: int = 0

# VARIABLES ORIGINALES (mantenidas para compatibilidad)
var fruit_spawn_time: Dictionary = {}
var total_fruits: int = 0
var correct_fruits: int = 0
var reaction_times: Array[int] = []

# ============================================
# FUNCION: register_spawn()
# ============================================
# MANTIENE FUNCIONALIDAD ORIGINAL
# Más preciso: usa ticks_msec en vez de unix_time
# ============================================
func register_spawn(fruit_id: int) -> void:
	fruit_spawn_time[fruit_id] = Time.get_ticks_msec()
	total_fruits += 1
	print("[MetricsTracker] Fruta registrada: ", fruit_id)

# ============================================
# FUNCION: register_cut()
# ============================================
# MANTIENE FUNCIONALIDAD ORIGINAL
# Para no romper código que ya la usa
# ============================================
func register_cut(fruit_id: int, was_correct: bool) -> void:
	if fruit_spawn_time.has(fruit_id):
		var spawn_time: int = fruit_spawn_time[fruit_id]
		var reaction: int = Time.get_ticks_msec() - spawn_time
		reaction_times.append(reaction)
		print("[MetricsTracker] Tiempo reacción: ", reaction, " ms")
		fruit_spawn_time.erase(fruit_id)
	
	if was_correct:
		correct_fruits += 1
		print("[MetricsTracker] Corte correcto")
	else:
		print("[MetricsTracker] Corte incorrecto")

# ============================================
# FUNCION NUEVA: register_question_attempt()
# ============================================
# QUE HACE:
# Registra UNA pregunta con TODOS los detalles.
# 
# CUANDO LLAMARLA:
# Desde Spawner._on_fruit_cut() para cada corte
# 
# PARAMETROS:
#   fruit_id: ID único de la fruta (para calcular tiempo)
#   question_type: Tipo específico (usa QuestionTypes.determine_type())
#   question_value: Lo que mostraba ("A", "5+3", etc.)
#   correct_answer: Respuesta esperada ("GATO", "8", etc.)
#   user_answer: Lo que cortó (normalmente igual a question_value)
#   is_correct: Si acertó (debe ser was_correct AND was_in_order)
#   difficulty: Dificultad del nivel (1-5)
# ============================================
func register_question_attempt(
	fruit_id: int,
	question_type: String,
	question_value: String,
	correct_answer: String,
	user_answer: String,
	is_correct: bool,
	difficulty: int = 1
) -> void:
	
	# PASO 1: Calcular tiempo de reacción
	var reaction_ms: int = 0
	if fruit_spawn_time.has(fruit_id):
		var spawn_time = fruit_spawn_time[fruit_id]
		reaction_ms = Time.get_ticks_msec() - spawn_time
		fruit_spawn_time.erase(fruit_id)
	
	# PASO 2: Actualizar combo
	if is_correct:
		current_combo += 1
		if current_combo > max_combo:
			max_combo = current_combo
	else:
		current_combo = 0
	
	# PASO 3: Incrementar contador
	current_attempt_number += 1
	
	# PASO 4: Crear registro del intento
	var attempt = QuestionAttempt.new()
	attempt.question_type = question_type
	attempt.question_data = {
		"question": question_value,
		"correct_answer": correct_answer
	}
	attempt.user_answer = user_answer
	attempt.is_correct = is_correct
	attempt.reaction_time_ms = reaction_ms
	attempt.difficulty_level = difficulty
	attempt.attempt_number = current_attempt_number
	attempt.current_combo = current_combo
	attempt.timestamp = Time.get_unix_time_from_system()
	
	# PASO 5: Guardar
	current_attempts.push_back(attempt)
	
	# PASO 6: Log detallado
	print("[MetricsTracker] Pregunta registrada:")
	print("                #", attempt.attempt_number, " | Tipo: ", question_type)
	print("                Correcta: ", is_correct, " | Tiempo: ", reaction_ms, "ms")
	print("                Combo: ", current_combo, " | Max: ", max_combo)

# ============================================
# FUNCION NUEVA: get_session_summary()
# ============================================
# QUE HACE:
# Calcula resumen completo de la sesión.
# 
# RETORNA:
# Dictionary con:
#   - Métricas agregadas (total, correctas, accuracy, tiempo promedio)
#   - Array de intentos individuales
#   - Max combo alcanzado
# 
# CUANDO USAR:
# Al finalizar sesión (victoria o game over)
# ============================================
func get_session_summary() -> Dictionary:
	var total = current_attempts.size()
	var correct = 0
	var total_reaction = 0
	
	for attempt in current_attempts:
		if attempt.is_correct:
			correct += 1
		total_reaction += attempt.reaction_time_ms
	
	var avg_reaction = 0
	if total > 0:
		avg_reaction = total_reaction / total
	
	var accuracy = 0.0
	if total > 0:
		accuracy = (float(correct) / float(total)) * 100.0
	
	var summary = {
		"total_questions": total,
		"correct_answers": correct,
		"wrong_answers": total - correct,
		"accuracy_percentage": accuracy,
		"avg_reaction_time_ms": avg_reaction,
		"max_combo": max_combo,
		"attempts": []
	}
	
	# Convertir intentos a diccionarios
	for attempt in current_attempts:
		summary.attempts.push_back(attempt.to_dict())
	
	print("[MetricsTracker] Resumen calculado:")
	print("                Total: ", total, " | Correctas: ", correct)
	print("                Precision: ", accuracy, "%")
	print("                Tiempo promedio: ", avg_reaction, "ms")
	print("                Max combo: ", max_combo)
	
	return summary

# ============================================
# FUNCION: calculate_metrics()
# ============================================
# MANTIENE FUNCIONALIDAD ORIGINAL
# Para compatibilidad con código que ya la usa
# ============================================
func calculate_metrics() -> Dictionary:
	var avg_reaction_sec: float = 0.0
	if reaction_times.size() > 0:
		var sum: int = 0
		for t in reaction_times:
			sum += t
		avg_reaction_sec = float(sum) / float(reaction_times.size())
	
	var accuracy: float = 0.0
	if total_fruits > 0:
		accuracy = float(correct_fruits) / float(total_fruits) * 100.0
	
	var metrics := {
		"reaction_time_ms": int(round(avg_reaction_sec)),
		"accuracy_percentage": accuracy
	}
	
	print("[MetricsTracker] Métricas calculadas: ", metrics)
	return metrics

# ============================================
# FUNCION NUEVA: get_stats_by_question_type()
# ============================================
# QUE HACE:
# Agrupa estadísticas por tipo de pregunta.
# 
# PARA QUE:
# Dashboard de fortalezas/debilidades.
# 
# EJEMPLO SALIDA:
# {
#   "letras_vocales": {
#     "total_attempts": 10,
#     "correct_count": 9,
#     "accuracy": 90.0,
#     "avg_reaction_ms": 1800
#   },
#   "sumas_simples": {
#     "total_attempts": 8,
#     "correct_count": 5,
#     "accuracy": 62.5,
#     "avg_reaction_ms": 3200
#   }
# }
# ============================================
func get_stats_by_question_type() -> Dictionary:
	var stats = {}
	
	for attempt in current_attempts:
		var type = attempt.question_type
		
		if not stats.has(type):
			stats[type] = {
				"total": 0,
				"correct": 0,
				"total_reaction": 0
			}
		
		stats[type].total += 1
		if attempt.is_correct:
			stats[type].correct += 1
		stats[type].total_reaction += attempt.reaction_time_ms
	
	# Calcular promedios
	var result = {}
	for type in stats.keys():
		var data = stats[type]
		result[type] = {
			"total_attempts": data.total,
			"correct_count": data.correct,
			"accuracy": (float(data.correct) / float(data.total)) * 100.0,
			"avg_reaction_ms": data.total_reaction / data.total
		}
	
	print("[MetricsTracker] Stats por tipo: ", result)
	return result

# ============================================
# FUNCION: reset()
# ============================================
# LIMPIA TODO para nueva sesión
# ============================================
func reset() -> void:
	# Limpiar variables nuevas
	current_attempts.clear()
	current_attempt_number = 0
	current_combo = 0
	max_combo = 0
	
	# Limpiar variables originales
	fruit_spawn_time.clear()
	total_fruits = 0
	correct_fruits = 0
	reaction_times.clear()
	
	print("[MetricsTracker] Estado reiniciado")

# ============================================
# RESUMEN DE FUNCIONES:
# ============================================
# FUNCIONES ORIGINALES (mantienen compatibilidad):
# - register_spawn(fruit_id)
# - register_cut(fruit_id, was_correct)
# - calculate_metrics()
# - reset()
# 
# FUNCIONES NUEVAS (métricas granulares):
# - register_question_attempt(...) <- La más importante
# - get_session_summary()
# - get_stats_by_question_type()
# 
# COMO MIGRAR:
# 1. Puedes seguir usando funciones originales
# 2. O cambiar a usar register_question_attempt() + get_session_summary()
# 3. Ambas funcionan en paralelo
# ============================================
