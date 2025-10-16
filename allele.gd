class_name Allele
extends Resource

## Represents a single allele (gene variant) with a color value and dominance level

@export var color: Color
@export var dominance: int = 0  # Higher values are more dominant
@export var pattern_type: String = "solid"  # "solid", "spotted", "striped"
@export var pattern_intensity: float = 1.0  # 0.0 to 1.0

func _init(p_color: Color = Color.WHITE, p_dominance: int = 0, p_pattern: String = "solid", p_intensity: float = 1.0) -> void:
	color = p_color
	dominance = p_dominance
	pattern_type = p_pattern
	pattern_intensity = p_intensity
