# scripts/core/main.gd
extends Node2D

# ============================================
# ¿QUÉ ES ESTE SCRIPT AHORA?
# Solo es el CONTENEDOR PRINCIPAL del juego.
# NO hace lógica, solo contiene otros módulos.
# ============================================

func _ready() -> void:
	print("=== JUEGO EDUCATIVO INICIADO ===")
	print("=== Sistema modular activado ===")
	
	# ⚡ TEMPORAL: Iniciar prueba de modos después de 3 segundos
	await get_tree().create_timer(3.0).timeout
	GameManager._test_switch_modes()
