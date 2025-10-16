class_name HabitatConfig
extends Resource

## Configuration for a specific habitat/species combination

@export var species_name: String = "Moth"
@export var species_type: String = "moth"  # moth, spider, beetle
@export var habitat_description: String = "Tree Bark"
@export var background_color: Color = Color(0.8, 0.8, 0.7)
@export var secondary_colors: Array[Color] = []  # Additional color niches in environment
@export var initial_population_base_color: Color = Color(0.5, 0.5, 0.5)
@export var initial_population_size: int = 50
@export var pattern_type: String = "solid"  # solid, spotted, striped

## Factory methods for predefined habitats
static func create_clean_bark_moths() -> HabitatConfig:
	var config = HabitatConfig.new()
	config.species_name = "Pepper Moth"
	config.species_type = "moth"
	config.habitat_description = "Clean Tree Bark"
	config.background_color = Color(0.85, 0.82, 0.75)  # Light bark
	config.initial_population_base_color = Color(0.6, 0.6, 0.6)  # Mixed light/dark
	config.initial_population_size = 50
	config.pattern_type = "spotted"
	return config

static func create_sooty_bark_moths() -> HabitatConfig:
	var config = HabitatConfig.new()
	config.species_name = "Pepper Moth"
	config.species_type = "moth"
	config.habitat_description = "Sooty Tree Bark"
	config.background_color = Color(0.26, 0.26, 0.29)  # Dark bark - closer to dark moth color
	config.initial_population_base_color = Color(0.6, 0.6, 0.6)  # Mixed light/dark
	config.initial_population_size = 50
	config.pattern_type = "spotted"
	return config

static func create_flower_spiders() -> HabitatConfig:
	var config = HabitatConfig.new()
	config.species_name = "Crab Spider"
	config.species_type = "spider"
	config.habitat_description = "Yellow Flowers"
	config.background_color = Color(0.95, 0.85, 0.2)  # Bright yellow
	config.initial_population_base_color = Color(0.75, 0.7, 0.3)  # Yellowish
	config.initial_population_size = 40
	config.pattern_type = "solid"
	return config

static func create_pink_flower_spiders() -> HabitatConfig:
	var config = HabitatConfig.new()
	config.species_name = "Crab Spider"
	config.species_type = "spider"
	config.habitat_description = "Pink Flowers"
	config.background_color = Color(0.95, 0.6, 0.7)  # Pink
	config.initial_population_base_color = Color(0.8, 0.7, 0.7)  # Pinkish
	config.initial_population_size = 40
	config.pattern_type = "solid"
	return config

static func create_red_flower_beetles() -> HabitatConfig:
	var config = HabitatConfig.new()
	config.species_name = "Flower Beetle"
	config.species_type = "beetle"
	config.habitat_description = "Red Flowers & Green Foliage"
	config.background_color = Color(0.25, 0.55, 0.25)  # Green foliage base
	config.secondary_colors = [Color(0.85, 0.15, 0.15)] as Array[Color]  # Red flowers
	config.initial_population_base_color = Color(0.5, 0.4, 0.3)  # Varied starting point
	config.initial_population_size = 50
	config.pattern_type = "solid"
	return config

static func create_white_flower_beetles() -> HabitatConfig:
	var config = HabitatConfig.new()
	config.species_name = "Flower Beetle"
	config.species_type = "beetle"
	config.habitat_description = "White Flowers & Green Foliage"
	config.background_color = Color(0.25, 0.55, 0.25)  # Green foliage base
	config.secondary_colors = [Color(0.95, 0.95, 0.95)] as Array[Color]  # White flowers
	config.initial_population_base_color = Color(0.5, 0.5, 0.4)  # Varied starting point
	config.initial_population_size = 50
	config.pattern_type = "solid"
	return config

static func create_purple_flower_beetles() -> HabitatConfig:
	var config = HabitatConfig.new()
	config.species_name = "Flower Beetle"
	config.species_type = "beetle"
	config.habitat_description = "Purple Flowers & Green Foliage"
	config.background_color = Color(0.25, 0.55, 0.25)  # Green foliage base
	config.secondary_colors = [Color(0.6, 0.3, 0.7)] as Array[Color]  # Purple flowers
	config.initial_population_base_color = Color(0.5, 0.4, 0.5)  # Varied starting point
	config.initial_population_size = 50
	config.pattern_type = "solid"
	return config

static func create_mixed_garden_bugs() -> HabitatConfig:
	var config = HabitatConfig.new()
	config.species_name = "Garden Bug"
	config.species_type = "beetle"
	config.habitat_description = "Mixed Garden (Multiple Flower Colors)"
	config.background_color = Color(0.25, 0.55, 0.25)  # Green foliage base
	config.secondary_colors = [
		Color(0.85, 0.15, 0.15),  # Red flowers
		Color(0.95, 0.95, 0.95),  # White flowers
		Color(0.6, 0.3, 0.7),     # Purple flowers
		Color(0.95, 0.6, 0.7)     # Pink flowers
	] as Array[Color]
	config.initial_population_base_color = Color(0.5, 0.5, 0.5)  # Very diverse start
	config.initial_population_size = 60
	config.pattern_type = "solid"
	return config

static func create_autumn_leaf_bugs() -> HabitatConfig:
	var config = HabitatConfig.new()
	config.species_name = "Leaf Bug"
	config.species_type = "beetle"
	config.habitat_description = "Autumn Leaves (Multiple Colors)"
	config.background_color = Color(0.8, 0.5, 0.2)  # Orange-brown (averaged)
	config.secondary_colors = [
		Color(0.9, 0.2, 0.1),   # Red leaves
		Color(0.95, 0.7, 0.1),  # Yellow leaves
		Color(0.6, 0.3, 0.15),  # Brown leaves
		Color(0.85, 0.5, 0.15)  # Orange leaves
	] as Array[Color]
	config.initial_population_base_color = Color(0.6, 0.5, 0.4)  # Mixed warm colors
	config.initial_population_size = 55
	config.pattern_type = "solid"
	return config

## Get all available habitats
static func get_all_habitats() -> Array[HabitatConfig]:
	var habitats: Array[HabitatConfig] = []
	# Moths - simple selection
	habitats.append(create_clean_bark_moths())
	habitats.append(create_sooty_bark_moths())
	# Spiders - simple selection
	habitats.append(create_flower_spiders())
	habitats.append(create_pink_flower_spiders())
	# Beetles - diverse color environments (can show polymorphism!)
	habitats.append(create_red_flower_beetles())
	habitats.append(create_white_flower_beetles())
	habitats.append(create_purple_flower_beetles())
	habitats.append(create_mixed_garden_bugs())
	habitats.append(create_autumn_leaf_bugs())
	return habitats
