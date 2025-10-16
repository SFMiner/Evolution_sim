class_name Organism
extends Area2D

## Represents an individual organism with genetic traits and visual appearance

signal clicked(organism: Organism)

var genotype: Genotype
var species_type: String = "moth"
var fitness: float = 0.0  # How well camouflaged (0-1, lower is better camouflage)
var is_alive: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

const scr_debug = true
var debug : bool
var original_modulate: Color = Color.WHITE  # Store original color for resetting

func _ready() -> void:
	debug = scr_debug
	input_event.connect(_on_input_event)

## Initialize organism with a genotype
func initialize(geno: Genotype, species: String) -> void:
	if debug: print("initializing genotype")
	genotype = geno
	species_type = species
	update_appearance()

## Update visual appearance based on genotype
func update_appearance() -> void:
	if not sprite:
		return
	
	var phenotype_color = genotype.get_phenotype_color()
	var pattern = genotype.get_phenotype_pattern()
	
	# Create a simple texture based on species type
	var size = 32
	if species_type == "moth":
		size = 40
	elif species_type == "spider":
		size = 24
	elif species_type == "beetle":
		size = 28
	
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Draw organism shape with pattern
	for x in range(size):
		for y in range(size):
			var dx = x - size / 2
			var dy = y - size / 2
			var dist = sqrt(dx * dx + dy * dy)

			# Create circular/oval shape
			var threshold = size / 2.0 - 2
			if species_type == "moth":
				# Moth: wider oval with soft edges (no visible outline)
				var moth_threshold = size / 2.0
				var ellipse_dist = (dx * dx) / float(moth_threshold * moth_threshold) + (dy * dy) / float((moth_threshold * 0.7) * (moth_threshold * 0.7))

				if ellipse_dist < 1.0:
					var color = phenotype_color

					# Apply pattern
					if pattern.type == "spotted":
						var spot_pattern = (sin(x * 0.8) * sin(y * 0.8) + 1.0) / 2.0
						if spot_pattern > 0.6:
							color = color.darkened(0.3 * pattern.intensity)
					elif pattern.type == "striped":
						if int(x / 4) % 2 == 0:
							color = color.darkened(0.2 * pattern.intensity)

					# Soft edge blending - fade alpha near the edge
					var alpha = 1.0
					if ellipse_dist > 0.85:
						alpha = (1.0 - ellipse_dist) / 0.15  # Fade from 0.85 to 1.0

					color.a = alpha
					image.set_pixel(x, y, color)
			
			elif species_type == "spider":
				# Spider: smaller, rounder with soft edges
				var spider_threshold = size / 2.0
				var normalized_dist = dist / spider_threshold

				if normalized_dist < 1.0:
					var color = phenotype_color

					if pattern.type == "spotted":
						var spot_pattern = (sin(x * 1.2) * sin(y * 1.2) + 1.0) / 2.0
						if spot_pattern > 0.5:
							color = color.darkened(0.4 * pattern.intensity)

					# Soft edge blending - fade alpha near the edge
					var alpha = 1.0
					if normalized_dist > 0.85:
						alpha = (1.0 - normalized_dist) / 0.15  # Fade from 0.85 to 1.0

					color.a = alpha
					image.set_pixel(x, y, color)
			
			elif species_type == "beetle":
				# Beetle: oval with soft edges
				var beetle_threshold = size / 2.0
				var normalized_dist = dist / beetle_threshold

				if normalized_dist < 1.0:
					var color = phenotype_color

					if pattern.type == "spotted":
						var checker = int((x / 6) + (y / 6)) % 2
						if checker == 0:
							color = color.darkened(0.3 * pattern.intensity)
					elif pattern.type == "striped":
						if int(y / 5) % 2 == 0:
							color = color.lightened(0.2 * pattern.intensity)

					# Soft edge blending - fade alpha near the edge
					var alpha = 1.0
					if normalized_dist > 0.85:
						alpha = (1.0 - normalized_dist) / 0.15  # Fade from 0.85 to 1.0

					color.a = alpha
					image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture

## Calculate fitness against a background color (and optional secondary colors)
func calculate_fitness(background_color: Color, secondary_colors: Array = []) -> void:
	var phenotype_color = genotype.get_phenotype_color()
	
	# Calculate color difference against primary background
	var primary_fitness = calculate_color_distance(phenotype_color, background_color)
	
	# If there are secondary colors (multiple niches), check against all
	var best_fitness = primary_fitness
	
	for secondary_color in secondary_colors:
		var secondary_fitness = calculate_color_distance(phenotype_color, secondary_color)
		# Take the BEST match (lowest distance)
		if secondary_fitness < best_fitness:
			best_fitness = secondary_fitness
	
	fitness = best_fitness

## Helper function to calculate color distance
func calculate_color_distance(color1: Color, color2: Color) -> float:
	var r_diff = abs(color1.r - color2.r)
	var g_diff = abs(color1.g - color2.g)
	var b_diff = abs(color1.b - color2.b)
	
	# Average difference (0 = perfect match, 1 = opposite colors)
	return (r_diff + g_diff + b_diff) / 3.0

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if is_alive:
				clicked.emit(self)

## Mark organism as caught
func catch_organism() -> void:
	is_alive = false
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

## Show or hide survivor highlighting by modulating color
func set_outline(show: bool, color: Color) -> void:
	if show:
		# Store original modulation
		original_modulate = modulate
		# Apply highlight color modulation
		modulate = color
	else:
		# Restore original modulation
		modulate = original_modulate
