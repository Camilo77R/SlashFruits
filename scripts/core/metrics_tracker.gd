extends Node

# ============================================
# ¿QUÉ ES ESTE ARCHIVO?
# Es el "CRONÓMETRO Y CALCULADORA".
# Mide tiempos de reacción y precisión del niño.
# ============================================

# ============================================
# VARIABLES INTERNAS
# ============================================
var fruit_spawn_time: Dictionary = {}   # fruit_id -> unix_time
var total_fruits: int = 0
var correct_fruits: int = 0
var reaction_times: Array[int] = []     # tiempos en segundos

# ============================================
# FUNCIÓN: register_spawn()
# ¿QUÉ HACE? Anota la hora en que apareció una fruta.
# ¿POR QUÉ? Para medir cuánto tarda el niño en cortarla.
# ANALOGÍA: Es como encender un cronómetro cuando empieza una carrera.
# ============================================
func register_spawn(fruit_id: int) -> void:
	fruit_spawn_time[fruit_id] = Time.get_unix_time_from_system()
	total_fruits += 1
	print("[MetricsTracker] ⏱️ Fruta registrada: ", fruit_id)

# ============================================
# FUNCIÓN: register_cut()
# ¿QUÉ HACE? Calcula tiempo de reacción y acierto/error.
# ¿CUÁNDO? En el momento exacto del corte.
# ANALOGÍA: Es como parar el cronómetro y anotar si la respuesta fue correcta.
# ============================================
func register_cut(fruit_id: int, was_correct: bool) -> void:
	if fruit_spawn_time.has(fruit_id):
		var spawn_time: int = fruit_spawn_time[fruit_id]
		var reaction: int = Time.get_unix_time_from_system() - spawn_time
		reaction_times.append(reaction)
		print("[MetricsTracker] ⏱️ Tiempo reacción: ", reaction, " seg")
		fruit_spawn_time.erase(fruit_id)  # limpieza

	if was_correct:
		correct_fruits += 1
		print("[MetricsTracker] ✅ Corte correcto")
	else:
		print("[MetricsTracker] ❌ Corte incorrecto")

# ============================================
# FUNCIÓN: calculate_metrics()
# ¿QUÉ HACE? Devuelve métricas de la sesión.
# ¿POR QUÉ? Para que padres/tutores vean progreso real.
# ANALOGÍA: Es como sacar el promedio de notas al final del examen.
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
		"reaction_time_ms": int(round(avg_reaction_sec * 1000.0)),
		"accuracy_percentage": accuracy
	}

	print("[MetricsTracker] 📊 Métricas calculadas: ", metrics)
	return metrics

# ============================================
# FUNCIÓN: reset()
# ¿QUÉ HACE? Limpia el estado para una nueva sesión.
# ¿CUÁNDO? Al iniciar o terminar sesión.
# ============================================
func reset() -> void:
	fruit_spawn_time.clear()
	total_fruits = 0
	correct_fruits = 0
	reaction_times.clear()
	print("[MetricsTracker] 🔄 Estado reiniciado")
