extends Node2D

## Main game controller for the evolution simulation

const ORGANISM_SCENE = preload("res://organism.tscn")
const ROUND_DURATION: float = 15.0  # seconds to catch organisms
const SURVIVAL_THRESHOLD: float = 0.2  # End round when 20% remain
const FLOWER_SIZE_MULTIPLIER: float = 8.0  # Tweakable flower size (multiplied by beetle diameter)

var current_habitat: HabitatConfig
var current_generation: int = 1
var population: Array[Organism] = []
var initial_population_size: int = 50

var round_active: bool = false
var round_time_remaining: float = 0.0
var organisms_caught: int = 0
var survivors_shown: bool = false

# Data tracking for graphs
var generation_data: Array[Dictionary] = []

# UI References
@onready var background_rect: TextureRect = $Background
@onready var organism_container: Node2D = $OrganismContainer
@onready var ui: Control = $UI
@onready var top_panel : PanelContainer = $UI/TopPanel
@onready var species_label: Label = $UI/TopPanel/HBoxContainer/LeftInfo/SpeciesLabel
@onready var habitat_label: Label = $UI/TopPanel/HBoxContainer/LeftInfo/HabitatLabel
@onready var generation_label: Label = $UI/TopPanel/HBoxContainer/LeftInfo/GenerationLabel
@onready var allele_freq_label: Label = $UI/TopPanel/HBoxContainer/VBoxContainer/AlleleFreqLabel
@onready var genotype_freq_label: Label = $UI/TopPanel/HBoxContainer/VBoxContainer/GenotypeFreqLabel
@onready var graph_container: Control = $UI/TopPanel/HBoxContainer/VBoxContainer/GraphContainer
@onready var panel_container: Control = $UI/PanelContainer
@onready var start_round_button: Button = $UI/PanelContainer/MarginContainer/CenterPanel/StartRoundButton
@onready var next_gen_button: Button = $UI/PanelContainer/MarginContainer/CenterPanel/NextGenButton
@onready var show_survivors_button: Button = $UI/PanelContainer/MarginContainer/CenterPanel/ShowSurvivorsButton
@onready var select_habitat_button: Button = $UI/PanelContainer/MarginContainer/CenterPanel/SelectHabitatButton
@onready var timer_label: Label = $UI/PanelContainer/MarginContainer/CenterPanel/TimerLabel
@onready var caught_label: Label = $UI/PanelContainer/MarginContainer/CenterPanel/CaughtLabel
@onready var continue_button: Button = $ScorePopup/Panel/VBoxContainer/ContinueButton
@onready var habitat_selection: Control = $UI/HabitatSelection
@onready var score_popup: CanvasLayer = $ScorePopup
@onready var yoink_player : AudioStreamPlayer = $YoinkPlayer 

func _ready() -> void:
	start_round_button.pressed.connect(_on_start_round_pressed)
	next_gen_button.pressed.connect(_on_next_generation_pressed)
	select_habitat_button.pressed.connect(_on_select_habitat_pressed)
	show_survivors_button.pressed.connect(_on_show_survivors_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)

	next_gen_button.visible = false
	
	# Setup habitat selection
	setup_habitat_selection()
	habitat_selection.visible = true

func setup_habitat_selection() -> void:
	var habitats = HabitatConfig.get_all_habitats()
	var vbox = habitat_selection.get_node("Panel/VBoxContainer")
	
	# Clear existing buttons (except title)
	for child in vbox.get_children():
		if child is Button:
			child.queue_free()
	
	for habitat in habitats:
		var button = Button.new()
		button.text = "%s - %s" % [habitat.species_name, habitat.habitat_description]
		button.pressed.connect(_on_habitat_selected.bind(habitat))
		vbox.add_child(button)

func _on_habitat_selected(habitat: HabitatConfig) -> void:
	current_habitat = habitat
	habitat_selection.visible = false
	panel_container.visible = true
	initialize_simulation()


func _on_select_habitat_pressed() -> void:
	habitat_selection.visible = true

func _on_show_survivors_pressed() -> void:
	survivors_shown = not survivors_shown

	# Determine outline color based on background
	var outline_color: Color = Color.MAGENTA

	# Check if background is too close to magenta
	var bg: Color = current_habitat.background_color
	var magenta_distance: float = abs(bg.r - 1.0) + abs(bg.g - 0.0) + abs(bg.b - 1.0)

	# If background is magenta-ish, use cyan instead
	if magenta_distance < 0.6:
		outline_color = Color.CYAN

	# Apply outline to all living organisms
	for org in population:
		if is_instance_valid(org) and org.is_alive:
			org.set_outline(survivors_shown, outline_color)

	# Update button text
	if survivors_shown:
		show_survivors_button.text = "Hide Survivors"
	else:
		show_survivors_button.text = "Show Survivors"

## Create a moth genotype with only two discrete color morphs (light and dark)
func create_moth_genotype() -> Genotype:
	# Define the two moth morphs (classic peppered moth genetics)
	var light_color = Color(0.85, 0.82, 0.75)  # Light morph (typica)
	var dark_color = Color(0.25, 0.25, 0.28)   # Dark morph (carbonaria)

	# Dark is dominant (historically accurate)
	var light_allele_dominance = 0  # Recessive
	var dark_allele_dominance = 1   # Dominant

	# Pattern matches the bark
	var pattern = "spotted"
	var pattern_intensity = randf_range(0.6, 0.9)

	# Randomly create two alleles (each can be light or dark)
	var allele1: Allele
	var allele2: Allele

	if randf() < 0.5:
		allele1 = Allele.new(light_color, light_allele_dominance, pattern, pattern_intensity)
	else:
		allele1 = Allele.new(dark_color, dark_allele_dominance, pattern, pattern_intensity)

	if randf() < 0.5:
		allele2 = Allele.new(light_color, light_allele_dominance, pattern, pattern_intensity)
	else:
		allele2 = Allele.new(dark_color, dark_allele_dominance, pattern, pattern_intensity)

	return Genotype.new(allele1, allele2)

func initialize_simulation() -> void:
	current_generation = 1
	generation_data.clear()
	clear_population()
	
	# Create initial population with random genetics
	initial_population_size = current_habitat.initial_population_size

	# Moths get discrete color morphs (light and dark only)
	if current_habitat.species_type == "moth":
		for i in range(initial_population_size):
			var genotype = create_moth_genotype()
			spawn_organism(genotype)
	else:
		# Determine color variation for other species
		var color_variation = 0.3  # Default for spiders

		# Bugs get much higher variation to create diverse populations
		if current_habitat.species_type == "beetle":
			color_variation = 0.5  # 50% variation for bugs - very diverse!

		for i in range(initial_population_size):
			var genotype = GeneticSystem.create_random_genotype(
				current_habitat.initial_population_base_color,
				color_variation,
				current_habitat.pattern_type
			)
			spawn_organism(genotype)
	
	# Update background - render multi-colored background if secondary colors exist
	render_background()
	
	# Update UI
	species_label.text = "Species: " + current_habitat.species_name
	habitat_label.text = "Habitat: " + current_habitat.habitat_description
	update_ui()
	
	start_round_button.visible = true
	next_gen_button.visible = false

func render_background() -> void:
	if current_habitat.secondary_colors.size() == 0:
		# Simple single-color background
		var image = Image.create(1280, 720, false, Image.FORMAT_RGB8)

		# If it's a moth habitat, add bark-like texture
		if current_habitat.species_type == "moth":
			render_bark_background(image)
		else:
			# Solid color for spiders
			image.fill(current_habitat.background_color)

		var texture = ImageTexture.create_from_image(image)
		background_rect.texture = texture
	else:
		# Multi-colored background with patches
		var image = Image.create(1280, 720, false, Image.FORMAT_RGB8)
		
		# Determine background pattern based on habitat description
		if "Flowers" in current_habitat.habitat_description or "Flower" in current_habitat.habitat_description:
			# Draw flowers with stems
			render_flower_background(image)
		elif "Autumn" in current_habitat.habitat_description or "Leaves" in current_habitat.habitat_description:
			# Draw scattered leaves
			render_leaf_background(image)
		elif "Garden" in current_habitat.habitat_description:
			# Draw mixed garden patches
			render_garden_background(image)
		else:
			# Default: color patches
			render_patch_background(image)
		
		var texture = ImageTexture.create_from_image(image)
		background_rect.texture = texture

func render_bark_background(image: Image) -> void:
	# Create bark-like spotted texture similar to moth patterns
	var base_color = current_habitat.background_color

	for y in range(720):
		for x in range(1280):
			# Create spotted pattern using sin waves like the moths
			var spot_pattern = (sin(x * 0.8) * sin(y * 0.8) + 1.0) / 2.0

			# Add some additional variation for more natural bark look
			var variation = (sin(x * 0.3) * cos(y * 0.5) + 1.0) / 2.0

			# Mix patterns for bark texture
			var combined = (spot_pattern * 0.6 + variation * 0.4)

			# Apply darkening in spotted areas (similar to moth pattern)
			var color = base_color
			if combined > 0.55:
				color = base_color.darkened(0.2)
			elif combined > 0.45:
				color = base_color.darkened(0.1)

			image.set_pixel(x, y, color)

func render_flower_background(image: Image) -> void:
	# NEW IMPROVED VERSION: Creates realistic flower habitat with blotchy green foliage
	# and large colorful flower circles
	
	# Get beetle diameter (from organism.gd, default is 28 pixels)
	var beetle_diameter = 28.0
	var flower_diameter = int(beetle_diameter * FLOWER_SIZE_MULTIPLIER)
	
	# Define green shades for blotchy foliage background
	var base_green = current_habitat.background_color
	var dark_green = base_green.darkened(0.25)
	var light_green = base_green.lightened(0.2)
	var stem_green = base_green.darkened(0.15)
	
	# Step 1: Create blotchy green background using multiple noise patterns
	for y in range(720):
		for x in range(1280):
			# Three types of noise for organic variation
			var noise1 = (sin(x * 0.05) * cos(y * 0.05) + 1.0) / 2.0
			var noise2 = (sin(x * 0.08 + 10) * sin(y * 0.07 + 5) + 1.0) / 2.0
			var noise3 = (cos(x * 0.03) * cos(y * 0.04) + 1.0) / 2.0
			
			# Combine noise patterns (weighted)
			var combined = (noise1 * 0.4 + noise2 * 0.3 + noise3 * 0.3)
			
			# Map to four shades of green for depth
			var color = base_green
			if combined > 0.65:
				color = light_green  # Lightest areas
			elif combined < 0.35:
				color = dark_green   # Darkest areas
			elif combined < 0.45:
				color = stem_green   # Stem-like darker areas
			# else: base_green (middle tone)
			
			image.set_pixel(x, y, color)
	
	# Step 2: Draw large circular flowers on top
	if current_habitat.secondary_colors.size() > 0:
		var flower_color = current_habitat.secondary_colors[0]
		
		# Calculate flower grid layout (with some spacing for overlap)
		var flowers_per_row = int(1280 / (flower_diameter * 0.8))
		var flowers_per_col = int(720 / (flower_diameter * 0.8))
		
		# Draw flowers in a grid with random offsets
		for row in range(flowers_per_col):
			for col in range(flowers_per_row):
				# Base position on grid
				var base_x = col * (flower_diameter * 1.2) + flower_diameter / 2
				var base_y = row * (flower_diameter * 1.2) + flower_diameter / 2
				
				# Add random offset for natural look (±15% of diameter)
				var offset_range = flower_diameter * 0.15
				var flower_x = int(base_x + randf_range(-offset_range, offset_range))
				var flower_y = int(base_y + randf_range(-offset_range, offset_range))
				
				# Draw circular flower with soft edge blending
				var radius = flower_diameter / 2
				for dy in range(-radius, radius):
					for dx in range(-radius, radius):
						var dist = sqrt(dx * dx + dy * dy)
						if dist < radius:
							var px = flower_x + dx
							var py = flower_y + dy
							
							if px >= 0 and px < 1280 and py >= 0 and py < 720:
								# Blend color slightly for depth (95-105% of base color)
								var color_variation = randf_range(0.95, 1.05)
								var varied_color = Color(
									clamp(flower_color.r * color_variation, 0.0, 1.0),
									clamp(flower_color.g * color_variation, 0.0, 1.0),
									clamp(flower_color.b * color_variation, 0.0, 1.0)
								)
								
								# Soft edge blending (fade near edge)
								if dist > radius * 0.9:
									var edge_blend = 1.0 - ((dist - radius * 0.9) / (radius * 0.1))
									var bg_color = image.get_pixel(px, py)
									varied_color = bg_color.lerp(varied_color, edge_blend)
								
								image.set_pixel(px, py, varied_color)

func render_leaf_background(image: Image) -> void:
	# Start with base color
	image.fill(current_habitat.background_color)
	
	# Add leaf patches in various colors
	for i in range(200):  # 200 leaves
		var leaf_x = randi() % 1280
		var leaf_y = randi() % 720
		var leaf_color = current_habitat.background_color
		
		# Randomly choose from available colors (including secondary)
		if current_habitat.secondary_colors.size() > 0 and randi() % 100 < 50:
			leaf_color = current_habitat.secondary_colors[randi() % current_habitat.secondary_colors.size()]
		
		# Draw leaf-like shape
		for dy in range(-15, 16):
			for dx in range(-10, 11):
				var dist = sqrt(dx * dx * 1.5 + dy * dy)
				if dist < 12:
					var px = leaf_x + dx
					var py = leaf_y + dy
					if px >= 0 and px < 1280 and py >= 0 and py < 720:
						image.set_pixel(px, py, leaf_color)

func render_garden_background(image: Image) -> void:
	# Create a diverse mixed garden
	var all_colors = [current_habitat.background_color] + current_habitat.secondary_colors
	
	# Draw random patches of different colors
	for i in range(300):
		var patch_x = randi() % 1280
		var patch_y = randi() % 720
		var patch_color = all_colors[randi() % all_colors.size()]
		var patch_size = 20 + randi() % 30
		
		for dy in range(-patch_size, patch_size):
			for dx in range(-patch_size, patch_size):
				var dist = sqrt(dx * dx + dy * dy)
				if dist < patch_size:
					var px = patch_x + dx
					var py = patch_y + dy
					if px >= 0 and px < 1280 and py >= 0 and py < 720:
						image.set_pixel(px, py, patch_color)

func render_patch_background(image: Image) -> void:
	# Generic patchy background
	image.fill(current_habitat.background_color)
	
	var all_colors = current_habitat.secondary_colors
	for color in all_colors:
		for i in range(100):
			var patch_x = randi() % 1280
			var patch_y = randi() % 720
			var patch_size = 25 + randi() % 25
			
			for dy in range(-patch_size, patch_size):
				for dx in range(-patch_size, patch_size):
					var dist = sqrt(dx * dx + dy * dy)
					if dist < patch_size:
						var px = patch_x + dx
						var py = patch_y + dy
						if px >= 0 and px < 1280 and py >= 0 and py < 720:
							image.set_pixel(px, py, color)

func spawn_organism(genotype: Genotype) -> void:
	var organism = ORGANISM_SCENE.instantiate()
	organism_container.add_child(organism)
	
	# Random position
	var margin = 50
	organism.position = Vector2(
		randf_range(margin, get_viewport_rect().size.x - margin),
		randf_range(margin + 100, get_viewport_rect().size.y - margin - 100)
	)
	
	organism.initialize(genotype, current_habitat.species_type)
	organism.calculate_fitness(current_habitat.background_color, current_habitat.secondary_colors)
	organism.clicked.connect(_on_organism_clicked)
	
	population.append(organism)

func _on_start_round_pressed() -> void:
	start_round()

func start_round() -> void:
	top_panel.visible = false
	start_round_button.visible = false
#	show_survivors_button.visible = false
	round_active = true
	round_time_remaining = ROUND_DURATION
	organisms_caught = 0
	update_ui()

func _process(delta: float) -> void:
	if round_active:
		round_time_remaining -= delta
		
		if round_time_remaining <= 0 or should_end_round():
			end_round()
		
		update_ui()

func should_end_round() -> bool:
	var alive_count = 0
	for org in population:
		if org.is_alive:
			alive_count += 1
	
	var survival_rate = alive_count / float(initial_population_size)
	return survival_rate <= SURVIVAL_THRESHOLD

func _on_organism_clicked(organism: Organism) -> void:
	if round_active and organism.is_alive:
		organism.catch_organism()
		yoink_player.play()
		organisms_caught += 1
		population.erase(organism)

func end_round() -> void:
	round_active = false
	next_gen_button.visible = true
#	show_survivors_button.visible = true
	start_round_button.visible = false
	top_panel.visible = true
	# Record data for this generation
	var data = record_generation_data()
	generation_data.append(data)
	
	update_ui()
	update_graph()
	score_popup.visible = true
	next_gen_button.visible = false
	timer_label.text = str(round_time_remaining)
	caught_label.text = str(organisms_caught) + "/" + str(initial_population_size)
	next_gen_button.visible = true

func record_generation_data() -> Dictionary:
	var allele_freq = GeneticSystem.calculate_allele_frequencies(population)
	var genotype_freq = GeneticSystem.calculate_genotype_frequencies(population)
	
	return {
		"generation": current_generation,
		"population_size": population.size(),
		"allele_freq": allele_freq,
		"genotype_freq": genotype_freq,
		"caught": organisms_caught
	}

func _on_next_generation_pressed() -> void:
	create_next_generation()

## Find the nearest organism to a given organism (excluding itself)
func find_nearest_neighbor(organism: Organism, others: Array[Organism]) -> Organism:
	var nearest: Organism = null
	var min_distance = INF
	
	for other in others:
		if other == organism:
			continue  # Don't mate with yourself!
		
		var distance = organism.position.distance_to(other.position)
		if distance < min_distance:
			min_distance = distance
			nearest = other
	
	return nearest

func create_next_generation() -> void:
	if population.size() < 2:
		push_warning("Population too small to reproduce!")
		return
	
	# Store survivors
	next_gen_button.visible = true
#	show_survivors_button.visible = false
	var survivors = population.duplicate()
	
	# Clear current population
	clear_population()
	
	# Create next generation through SPATIAL ASSORTATIVE MATING
	# Each organism breeds with its nearest neighbor
	var target_population = initial_population_size
	
	for i in range(target_population):
		# Select a random survivor as parent1
		var parent1 = survivors[randi() % survivors.size()]
		
		# Find parent1's nearest neighbor as parent2
		var parent2 = find_nearest_neighbor(parent1, survivors)
		
		if parent2 == null:
			# Fallback: use random mate if no neighbor found
			parent2 = survivors[randi() % survivors.size()]

		# Create offspring (use moth-specific reproduction for discrete morphs)
		var offspring_genotype: Genotype
		if current_habitat.species_type == "moth":
			offspring_genotype = GeneticSystem.reproduce_moth(parent1, parent2)
		else:
			offspring_genotype = GeneticSystem.reproduce(parent1, parent2)

		spawn_organism(offspring_genotype)
	
	# Clean up survivor nodes
	for survivor in survivors:
		survivor.queue_free()
	
	current_generation += 1
	next_gen_button.visible = false
#	start_round_button.visible = true
	start_round()
	update_ui()

func clear_population() -> void:
	for org in population:
		if is_instance_valid(org):
			org.queue_free()
	population.clear()

func update_ui() -> void:
	generation_label.text = "Generation: %d" % current_generation
	
	if round_active:
		timer_label.text = "Time: %.1fs" % round_time_remaining
	else:
		timer_label.text = "Time: --"
	
	caught_label.text = "Caught: %d" % organisms_caught
	
	# Update frequency displays
	if population.size() > 0:
		var allele_freq = GeneticSystem.calculate_allele_frequencies(population)
		var genotype_freq = GeneticSystem.calculate_genotype_frequencies(population)
		
		allele_freq_label.text = "Allele Frequencies:\nDominant (A): %.2f%%\nRecessive (a): %.2f%%" % [
			allele_freq.dominant * 100,
			allele_freq.recessive * 100
		]
		
		genotype_freq_label.text = "Genotype Frequencies:\nAA: %.2f%%\nAa: %.2f%%\naa: %.2f%%" % [
			genotype_freq.AA * 100,
			genotype_freq.Aa * 100,
			genotype_freq.aa * 100
		]
	else:
		allele_freq_label.text = "Allele Frequencies:\n--"
		genotype_freq_label.text = "Genotype Frequencies:\n--"

func update_graph() -> void:
	queue_redraw()

func _draw() -> void:
	if generation_data.size() < 2:
		return
	
	# Draw graph in the graph container area
	var graph_rect = graph_container.get_global_rect()
	var local_rect = Rect2(
		graph_rect.position - global_position,
		graph_rect.size
	)
	
	var margin = 10
	var plot_rect = Rect2(
		local_rect.position.x + margin,
		local_rect.position.y + margin,
		local_rect.size.x - margin * 2,
		local_rect.size.y - margin * 2
	)
	
	# Draw background
	draw_rect(plot_rect, Color(0.1, 0.1, 0.1, 0.5))
	
	# Draw allele frequency lines
	var max_gen = generation_data.size()
	
	if max_gen > 1:
		var points_dominant: PackedVector2Array = []
		var points_recessive: PackedVector2Array = []
		
		for i in range(generation_data.size()):
			var data = generation_data[i]
			var x = plot_rect.position.x + (i / float(max_gen - 1)) * plot_rect.size.x
			
			var y_dom = plot_rect.position.y + plot_rect.size.y - (data.allele_freq.dominant * plot_rect.size.y)
			var y_rec = plot_rect.position.y + plot_rect.size.y - (data.allele_freq.recessive * plot_rect.size.y)
			
			points_dominant.append(Vector2(x, y_dom))
			points_recessive.append(Vector2(x, y_rec))
		
		# Draw lines
		draw_polyline(points_dominant, Color.GREEN, 2.0)
		draw_polyline(points_recessive, Color.RED, 2.0)
		
		# Draw legend
		draw_line(
			Vector2(plot_rect.position.x + 5, plot_rect.position.y + 5),
			Vector2(plot_rect.position.x + 25, plot_rect.position.y + 5),
			Color.GREEN, 2.0
		)
		draw_line(
			Vector2(plot_rect.position.x + 5, plot_rect.position.y + 15),
			Vector2(plot_rect.position.x + 25, plot_rect.position.y + 15),
			Color.RED, 2.0
		)

func _on_continue_button_pressed():
	score_popup.visible = false
	create_next_generation()
	panel_container.visible = true
