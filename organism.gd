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

## Helper function to check if point is inside a triangle
func _point_in_triangle(px: float, py: float, x1: float, y1: float, x2: float, y2: float, x3: float, y3: float) -> bool:
	var area = abs((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1))
	var s = ((x2 - x1) * (py - y1) - (y2 - y1) * (px - x1))
	var t = ((x3 - x2) * (py - y2) - (y3 - y2) * (px - x2))
	
	if area == 0:
		return false
	
	if (s < 0) != (t < 0) and s != 0 and t != 0:
		return false
	
	var d = ((x1 - x3) * (py - y3) - (y1 - y3) * (px - x3))
	return d == 0 or (d < 0) == (s + t <= 0)

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
				# Moth: two right triangles forming wings (50% taller)
				# Right angle at bottom center, vertical sides meet at top, hypotenuses on outside
				var center_x = size / 2.0
				var bottom_y = size * 0.875  # Bottom of moth (moved down for taller wings)
				var top_y = size * 0.125     # Top point where wings meet (moved up for taller wings)
				var wing_width = size * 0.35  # How far wings extend horizontally (unchanged)
				
				# Left wing: right angle at bottom center, goes up and out to the left
				# Points: bottom center, bottom left, top center
				var left_x1 = center_x           # Bottom center (right angle)
				var left_y1 = bottom_y
				var left_x2 = center_x - wing_width  # Bottom left (base)
				var left_y2 = bottom_y
				var left_x3 = center_x           # Top center (where wings meet)
				var left_y3 = top_y
				
				# Right wing: right angle at bottom center, goes up and out to the right
				# Points: bottom center, bottom right, top center
				var right_x1 = center_x          # Bottom center (right angle)
				var right_y1 = bottom_y
				var right_x2 = center_x + wing_width  # Bottom right (base)
				var right_y2 = bottom_y
				var right_x3 = center_x          # Top center (where wings meet)
				var right_y3 = top_y
				
				var in_left_wing = _point_in_triangle(x, y, left_x1, left_y1, left_x2, left_y2, left_x3, left_y3)
				var in_right_wing = _point_in_triangle(x, y, right_x1, right_y1, right_x2, right_y2, right_x3, right_y3)
				
				if in_left_wing or in_right_wing:
					var color = phenotype_color
					
					# Apply pattern
					if pattern.type == "spotted":
						var spot_pattern = (sin(x * 0.8) * sin(y * 0.8) + 1.0) / 2.0
						if spot_pattern > 0.6:
							color = color.darkened(0.3 * pattern.intensity)
					elif pattern.type == "striped":
						if int(x / 4) % 2 == 0:
							color = color.darkened(0.2 * pattern.intensity)
					
					# Calculate distance from edges for soft blending
					var dist_from_center = sqrt(dx * dx + dy * dy)
					var max_dist = sqrt(wing_width * wing_width + ((bottom_y - top_y) / 2) * ((bottom_y - top_y) / 2))
					var edge_factor = dist_from_center / max_dist
					
					# Soft edge blending
					var alpha = 1.0
					if edge_factor > 0.85:
						alpha = (1.0 - edge_factor) / 0.15
					
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
