class_name GeneticSystem
extends Node

## Handles genetic reproduction, mutation, and population genetics

const MUTATION_RATE: float = 0.05  # 5% chance of mutation

## Perform sexual reproduction between two organisms
static func reproduce(parent1: Organism, parent2: Organism) -> Genotype:
	# Get one allele from each parent (Mendelian inheritance)
	var allele_from_p1 = get_random_allele_from_genotype(parent1.genotype)
	var allele_from_p2 = get_random_allele_from_genotype(parent2.genotype)

	# Apply possible mutations
	if randf() < MUTATION_RATE:
		allele_from_p1 = mutate_allele(allele_from_p1)
	if randf() < MUTATION_RATE:
		allele_from_p2 = mutate_allele(allele_from_p2)

	return Genotype.new(allele_from_p1, allele_from_p2)

## Perform sexual reproduction for moths (discrete morphs)
static func reproduce_moth(parent1: Organism, parent2: Organism) -> Genotype:
	# Get one allele from each parent (Mendelian inheritance)
	var allele_from_p1 = get_random_allele_from_genotype(parent1.genotype)
	var allele_from_p2 = get_random_allele_from_genotype(parent2.genotype)

	# Apply possible mutations (discrete: light <-> dark)
	if randf() < MUTATION_RATE:
		allele_from_p1 = mutate_moth_allele(allele_from_p1)
	if randf() < MUTATION_RATE:
		allele_from_p2 = mutate_moth_allele(allele_from_p2)

	return Genotype.new(allele_from_p1, allele_from_p2)

## Get a random allele from a genotype (simulates meiosis)
static func get_random_allele_from_genotype(geno: Genotype) -> Allele:
	if randf() < 0.5:
		return duplicate_allele(geno.allele1)
	else:
		return duplicate_allele(geno.allele2)

## Duplicate an allele (to avoid reference issues)
static func duplicate_allele(allele: Allele) -> Allele:
	return Allele.new(allele.color, allele.dominance, allele.pattern_type, allele.pattern_intensity, allele.habitat_preference)

## Mutate an allele slightly
static func mutate_allele(allele: Allele) -> Allele:
	var new_color = allele.color
	var new_habitat_pref = allele.habitat_preference

	# Slight color shift
	var shift = 0.1
	new_color.r = clamp(new_color.r + randf_range(-shift, shift), 0.0, 1.0)
	new_color.g = clamp(new_color.g + randf_range(-shift, shift), 0.0, 1.0)
	new_color.b = clamp(new_color.b + randf_range(-shift, shift), 0.0, 1.0)
	
	# Small chance to mutate habitat preference (10% of mutations)
	if randf() < 0.1:
		var prefs = ["flower", "foliage", "any"]
		new_habitat_pref = prefs[randi() % prefs.size()]

	return Allele.new(new_color, allele.dominance, allele.pattern_type, allele.pattern_intensity, new_habitat_pref)

## Mutate a moth allele (discrete morphs: light <-> dark)
static func mutate_moth_allele(allele: Allele) -> Allele:
	# Moths have discrete morphs - mutation flips between light and dark
	var light_color = Color(0.85, 0.82, 0.75)
	var dark_color = Color(0.25, 0.25, 0.28)

	# Check if current allele is light or dark (by brightness)
	var brightness = (allele.color.r + allele.color.g + allele.color.b) / 3.0

	if brightness > 0.5:
		# Currently light, mutate to dark
		return Allele.new(dark_color, 1, allele.pattern_type, allele.pattern_intensity, allele.habitat_preference)
	else:
		# Currently dark, mutate to light
		return Allele.new(light_color, 0, allele.pattern_type, allele.pattern_intensity, allele.habitat_preference)

## Create a random genotype for initial population with habitat preference based on color
static func create_random_genotype(base_color: Color, variation: float = 0.3, pattern: String = "solid") -> Genotype:
	var color1 = Color(
		clamp(base_color.r + randf_range(-variation, variation), 0.0, 1.0),
		clamp(base_color.g + randf_range(-variation, variation), 0.0, 1.0),
		clamp(base_color.b + randf_range(-variation, variation), 0.0, 1.0)
	)
	var color2 = Color(
		clamp(base_color.r + randf_range(-variation, variation), 0.0, 1.0),
		clamp(base_color.g + randf_range(-variation, variation), 0.0, 1.0),
		clamp(base_color.b + randf_range(-variation, variation), 0.0, 1.0)
	)
	
	# Randomly assign dominance
	var dom1 = 1 if randf() < 0.5 else 0
	var dom2 = 1 if randf() < 0.5 else 0
	
	# Determine habitat preference based on color brightness/greenness
	var habitat_pref1 = determine_habitat_preference_from_color(color1)
	var habitat_pref2 = determine_habitat_preference_from_color(color2)
	
	var allele1 = Allele.new(color1, dom1, pattern, randf_range(0.5, 1.0), habitat_pref1)
	var allele2 = Allele.new(color2, dom2, pattern, randf_range(0.5, 1.0), habitat_pref2)
	
	return Genotype.new(allele1, allele2)

## Determine habitat preference based on color (green = foliage, bright = flower)
static func determine_habitat_preference_from_color(color: Color) -> String:
	# Calculate greenness (high green, low red/blue)
	var greenness = color.g - (color.r + color.b) / 2.0
	
	# Calculate brightness
	var brightness = (color.r + color.g + color.b) / 3.0
	
	# Green colors prefer foliage
	if greenness > 0.15:
		return "foliage"
	# Very bright colors prefer flowers
	elif brightness > 0.6 and (color.r > 0.5 or color.b > 0.4):
		return "flower"
	# Intermediate or unclear - generalist
	else:
		return "any"

## Calculate allele frequencies in a population
static func calculate_allele_frequencies(population: Array[Organism]) -> Dictionary:
	var dominant_count = 0
	var recessive_count = 0
	var total_alleles = population.size() * 2
	
	for org in population:
		if org.genotype.allele1.dominance > 0:
			dominant_count += 1
		else:
			recessive_count += 1
		
		if org.genotype.allele2.dominance > 0:
			dominant_count += 1
		else:
			recessive_count += 1
	
	return {
		"dominant": dominant_count / float(total_alleles) if total_alleles > 0 else 0.0,
		"recessive": recessive_count / float(total_alleles) if total_alleles > 0 else 0.0
	}

## Calculate genotype frequencies (AA, Aa, aa)
static func calculate_genotype_frequencies(population: Array[Organism]) -> Dictionary:
	var homozygous_dominant = 0  # AA
	var heterozygous = 0  # Aa
	var homozygous_recessive = 0  # aa
	
	for org in population:
		var a1_dom = org.genotype.allele1.dominance > 0
		var a2_dom = org.genotype.allele2.dominance > 0
		
		if a1_dom and a2_dom:
			homozygous_dominant += 1
		elif not a1_dom and not a2_dom:
			homozygous_recessive += 1
		else:
			heterozygous += 1
	
	var total = population.size()
	return {
		"AA": homozygous_dominant / float(total) if total > 0 else 0.0,
		"Aa": heterozygous / float(total) if total > 0 else 0.0,
		"aa": homozygous_recessive / float(total) if total > 0 else 0.0
	}
