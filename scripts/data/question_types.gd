# scripts/data/question_types.gd
class_name QuestionTypes
extends RefCounted

# ============================================
# SISTEMA CENTRALIZADO DE TIPOS DE PREGUNTA
# ============================================
# QUE ES:
# Una clase que define TODOS los tipos posibles de pregunta.
# 
# POR QUE EXISTE:
# Para evitar errores de tipeo y tener un lugar central donde ver
# todos los tipos disponibles.
# 
# COMO USAR:
# QuestionTypes.VOCALES  # "letras_vocales"
# QuestionTypes.SUMAS    # "sumas_simples"
# 
# BENEFICIOS:
# 1. Autocompletado en editor (escribe QuestionTypes. y ves opciones)
# 2. No puedes escribir mal un tipo (error de compilacion si no existe)
# 3. Facil agregar nuevos tipos (solo agregas aqui)
# ============================================

# ============================================
# TIPOS DE PREGUNTA - CULTURA
# ============================================

# Letras vocales: A, E, I, O, U
const VOCALES: String = "letras_vocales"

# Letras consonantes: B, C, D, F, G, etc.
const CONSONANTES: String = "letras_consonantes"

# Palabras completas: PARIS, BOGOTA, GATO
const PALABRAS: String = "palabras_completas"

# Capitales de paises: ¿Capital de Francia?
const CAPITALES: String = "capitales"

# Animales: GATO, PERRO, LEON
const ANIMALES: String = "animales"

# Colores: ROJO, AZUL, VERDE
const COLORES: String = "colores"

# ============================================
# TIPOS DE PREGUNTA - LOGICA
# ============================================

# Numeros del 0 al 9
const NUMEROS_BASICOS: String = "numeros_basicos"

# Numeros del 10 al 99
const NUMEROS_DOBLE_DIGITO: String = "numeros_doble_digito"

# Sumas simples: 2+3, 5+1
const SUMAS_SIMPLES: String = "sumas_simples"

# Sumas con resultado mayor a 10: 8+5, 9+7
const SUMAS_AVANZADAS: String = "sumas_avanzadas"

# Restas simples: 5-2, 8-3
const RESTAS_SIMPLES: String = "restas_simples"

# Restas con resultado negativo o complejo
const RESTAS_AVANZADAS: String = "restas_avanzadas"

# Secuencias numericas: 2,4,6,?
const SECUENCIAS: String = "secuencias_numericas"

# Multiplicaciones basicas: 2x3, 3x4
const MULTIPLICACIONES: String = "multiplicaciones_simples"

# ============================================
# TIPOS ESPECIALES
# ============================================

# Bombas (obstaculos)
const BOMB: String = "bomb"

# Tipo generico cuando no se puede clasificar
const GENERAL: String = "general"

# ============================================
# FUNCION: determine_type()
# ============================================
# QUE HACE:
# Determina automaticamente el tipo de pregunta basado en el valor.
# 
# CUANDO USAR:
# Cuando tienes un valor ("A", "5", "BOMB") y necesitas saber su tipo.
# 
# PARAMETROS:
#   value: String - El valor a clasificar
#   mode: String - "culture" o "logic" (opcional, ayuda a clasificar)
# 
# RETORNA:
#   String - El tipo de pregunta (una de las constantes de arriba)
# 
# EJEMPLOS:
#   determine_type("A") → "letras_vocales"
#   determine_type("B") → "letras_consonantes"
#   determine_type("5") → "numeros_basicos"
#   determine_type("BOMB") → "bomb"
# ============================================
static func determine_type(value: String, mode: String = "") -> String:
	# Caso especial: bomba
	if value == "BOMB":
		return BOMB
	
	# Si es un caracter individual
	if value.length() == 1:
		var char_code = value.unicode_at(0)
		
		# Es letra (A-Z)
		if (char_code >= 65 and char_code <= 90) or (char_code >= 97 and char_code <= 122):
			var upper_value = value.to_upper()
			
			# Clasificar vocal vs consonante
			if upper_value in ["A", "E", "I", "O", "U"]:
				return VOCALES
			else:
				return CONSONANTES
		
		# Es numero (0-9)
		elif char_code >= 48 and char_code <= 57:
			return NUMEROS_BASICOS
	
	# Si es palabra completa (mas de 1 caracter)
	elif value.length() > 1:
		# Si todos son numeros
		if value.is_valid_int():
			var num = int(value)
			if num >= 10 and num <= 99:
				return NUMEROS_DOBLE_DIGITO
			else:
				return NUMEROS_BASICOS
		
		# Si contiene operador matematico
		if "+" in value:
			return SUMAS_SIMPLES
		elif "-" in value:
			return RESTAS_SIMPLES
		elif "x" in value or "*" in value:
			return MULTIPLICACIONES
		
		# Es palabra de letras
		return PALABRAS
	
	# Tipo generico si no pudimos clasificar
	return GENERAL

# ============================================
# FUNCION: get_all_types()
# ============================================
# QUE HACE:
# Retorna un diccionario con TODOS los tipos disponibles.
# 
# PARA QUE:
# Util para debugging, UI de admin, o listar tipos.
# 
# RETORNA:
#   Dictionary con categorias y sus tipos
# ============================================
static func get_all_types() -> Dictionary:
	return {
		"cultura": [
			VOCALES,
			CONSONANTES,
			PALABRAS,
			CAPITALES,
			ANIMALES,
			COLORES
		],
		"logica": [
			NUMEROS_BASICOS,
			NUMEROS_DOBLE_DIGITO,
			SUMAS_SIMPLES,
			SUMAS_AVANZADAS,
			RESTAS_SIMPLES,
			RESTAS_AVANZADAS,
			SECUENCIAS,
			MULTIPLICACIONES
		],
		"especiales": [
			BOMB,
			GENERAL
		]
	}

# ============================================
# FUNCION: get_display_name()
# ============================================
# QUE HACE:
# Convierte el tipo tecnico en nombre legible para UI.
# 
# EJEMPLOS:
#   "letras_vocales" → "Letras Vocales"
#   "sumas_simples" → "Sumas Simples"
# 
# PARA QUE:
# Mostrar en dashboards de padres/tutores.
# ============================================
static func get_display_name(type: String) -> String:
	var names = {
		VOCALES: "Letras Vocales",
		CONSONANTES: "Letras Consonantes",
		PALABRAS: "Palabras Completas",
		CAPITALES: "Capitales",
		ANIMALES: "Animales",
		COLORES: "Colores",
		NUMEROS_BASICOS: "Números Básicos",
		NUMEROS_DOBLE_DIGITO: "Números de Dos Dígitos",
		SUMAS_SIMPLES: "Sumas Simples",
		SUMAS_AVANZADAS: "Sumas Avanzadas",
		RESTAS_SIMPLES: "Restas Simples",
		RESTAS_AVANZADAS: "Restas Avanzadas",
		SECUENCIAS: "Secuencias Numéricas",
		MULTIPLICACIONES: "Multiplicaciones",
		BOMB: "Bomba",
		GENERAL: "General"
	}
	
	return names.get(type, type)

# ============================================
# NOTAS DE USO:
# ============================================
# DONDE CREAR ESTE ARCHIVO:
# scripts/data/question_types.gd
# 
# NO NECESITA SER AUTOLOAD:
# Es una clase utilitaria, se usa con QuestionTypes.CONSTANTE
# 
# COMO USAR EN OTROS SCRIPTS:
# var type = QuestionTypes.determine_type("A")
# var name = QuestionTypes.get_display_name(type)
# print(name)  # "Letras Vocales"
# 
# VENTAJAS:
# 1. Centralizacion (un solo lugar para tipos)
# 2. Consistencia (todos usan mismos strings)
# 3. Mantenibilidad (agregar tipo = agregar aqui)
# 4. Documentacion (lista completa de tipos)
# ============================================
