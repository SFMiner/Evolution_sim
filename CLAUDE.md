# CLAUDE.md - Guide for AI Agents

This document provides everything an AI agent needs to help modify, extend, or debug the Evolution Simulator project.

## Project Overview

**Type**: Educational evolution simulation game  
**Engine**: Godot 4.4+ (GDScript)  
**Purpose**: Teach natural selection and Mendelian genetics through interactive gameplay  
**Target Audience**: Middle school through college students  
**Code Style**: Tabs for indentation (per user preference)

## Core Concept

Students act as predators catching organisms (moths, spiders, beetles) in various environments. Poorly camouflaged organisms are easier to catch and get removed from the population. Survivors reproduce, passing their genes to the next generation. Over multiple rounds, the population adapts to match the background.

## Project Structure

```
evolution_sim/
├── project.godot              # Godot project configuration
├── main.tscn                  # Main scene with UI layout
├── main.gd                    # Game manager (round logic, population, UI)
├── organism.tscn              # Organism node template
├── organism.gd                # Organism behavior (visuals, genetics, fitness)
├── allele.gd                  # Allele (gene variant) class
├── genotype.gd                # Genotype (2 alleles) with dominance logic
├── genetic_system.gd          # Reproduction, inheritance, mutations
├── habitat_config.gd          # Habitat/species configurations (9 total)
├── icon.svg                   # Project icon
├── README.md                  # User documentation
├── TEACHERS_GUIDE.md          # Lesson plans and activities
└── export_presets.cfg         # Export settings for Windows/HTML5
```

## Key Systems

### 1. Genetics System

**Diploid Genetics**: Each organism has 2 alleles per gene

```gdscript
class Genotype:
	var allele1: Allele
	var allele2: Allele
```

**Allele Structure**:

```gdscript
class Allele:
	var color: Color
	var dominance: int  # 0 = recessive, 1 = dominant
	var pattern_type: String  # "solid", "spotted", "striped"
	var pattern_intensity: float  # 0.0 to 1.0
```

**Phenotype Determination**:

- If dominance differs: Use dominant allele's color
- If dominance equal: Blend colors (co-dominance)

**Reproduction** (in genetic_system.gd):

```gdscript
static func reproduce(parent1: Organism, parent2: Organism) -> Genotype:
	# Random allele from each parent (meiosis simulation)
	var allele_from_p1 = get_random_allele_from_genotype(parent1.genotype)
	var allele_from_p2 = get_random_allele_from_genotype(parent2.genotype)
	
	# 5% mutation chance per allele
	if randf() < MUTATION_RATE:
		allele_from_p1 = mutate_allele(allele_from_p1)
	
	return Genotype.new(allele_from_p1, allele_from_p2)
```

### 2. Fitness Calculation

**Multi-Niche Support** (organism.gd):

```gdscript
func calculate_fitness(background_color: Color, secondary_colors: Array = []) -> void:
	var phenotype_color = genotype.get_phenotype_color()
	
	# Calculate distance from primary background
	var best_fitness = calculate_color_distance(phenotype_color, background_color)
	
	# Check each secondary niche
	for secondary_color in secondary_colors:
		var secondary_fitness = calculate_color_distance(phenotype_color, secondary_color)
		if secondary_fitness < best_fitness:
			best_fitness = secondary_fitness  # Use BEST match
	
	fitness = best_fitness

func calculate_color_distance(color1: Color, color2: Color) -> float:
	var r_diff = abs(color1.r - color2.r)
	var g_diff = abs(color1.g - color2.g)
	var b_diff = abs(color1.b - color2.b)
	return (r_diff + g_diff + b_diff) / 3.0  # 0 = perfect match, 1 = opposite
```

**Key Insight**: Organisms check ALL available colors (primary + secondary) and use the best match. This allows beetles to hide on either flowers OR stems.

### 3. Habitat System

**9 Pre-configured Habitats** (habitat_config.gd):

**Simple (4)** - Single color, directional selection:

- Clean Bark Moths (light)
- Sooty Bark Moths (dark)
- Yellow Flower Spiders
- Pink Flower Spiders

**Complex (5)** - Multiple niches, polymorphism:

- Red Flowers & Green Stems (2 niches)
- White Flowers & Green Stems (2 niches)
- Purple Flowers & Green Stems (2 niches)
- Mixed Garden (4 niches: red, white, green, purple)
- Autumn Leaves (4 niches: red, yellow, orange, brown)

**Habitat Structure**:

```gdscript
class HabitatConfig:
	var species_name: String
	var species_type: String  # "moth", "spider", "beetle"
	var habitat_description: String
	var background_color: Color  # Primary color
	var secondary_colors: Array[Color]  # Additional niches (empty for simple habitats)
	var initial_population_base_color: Color  # Starting color
	var initial_population_size: int
	var pattern_type: String
```

### 4. Game Loop (main.gd)

**Round Flow**:

1. **Initialization**: Create population with random genetics (start_round_button visible)
2. **Round Start**: 15-second timer begins
3. **Catching Phase**: Player clicks organisms (easier to see = easier to catch)
4. **Round End**: Timer expires OR 80% caught (next_gen_button appears)
5. **Data Recording**: Calculate allele/genotype frequencies
6. **Reproduction**: Survivors mate randomly to create next generation (automatically calls start_round)
7. **Repeat**: New round with adapted population (next_gen_button continues to appear each round)

**Key Constants** (easily tweakable):

```gdscript
const ROUND_DURATION: float = 15.0  # Seconds to catch organisms
const SURVIVAL_THRESHOLD: float = 0.2  # End when 20% remain
const MUTATION_RATE: float = 0.05  # In genetic_system.gd
```

### 5. Visual Rendering

**Organism Appearance** (organism.gd):

- Procedurally generated based on genotype
- Species-specific shapes (moths: oval, spiders: round, beetles: harder edges)
- Pattern overlay (spotted, striped, solid)
- Size: 24-40 pixels depending on species

**Background Rendering** (main.gd):

- **Simple habitats**: Solid color fill
- **Flower habitats**: Flower color + vertical stem patterns
- **Mixed Garden**: 300 random circular patches
- **Autumn Leaves**: 200 leaf-shaped patches

## Common Modification Scenarios

### Adding a New Habitat

1. **Create factory function** in habitat_config.gd:

```gdscript
static func create_my_habitat() -> HabitatConfig:
	var config = HabitatConfig.new()
	config.species_name = "My Species"
	config.species_type = "beetle"  # or "moth" or "spider"
	config.habitat_description = "My Description"
	config.background_color = Color(r, g, b)
	config.secondary_colors = [Color(...), Color(...)]  # Optional
	config.initial_population_base_color = Color(r, g, b)
	config.initial_population_size = 50
	config.pattern_type = "solid"  # or "spotted" or "striped"
	return config
```

2. **Add to habitat list** in get_all_habitats():

```gdscript
habitats.append(create_my_habitat())
```

3. **Optional**: Add custom background renderer in main.gd if needed

### Adjusting Selection Pressure

**Make selection easier** (organisms caught faster):

- Decrease ROUND_DURATION (less time to catch)
- Increase SURVIVAL_THRESHOLD (round ends with more survivors)

**Make selection harder** (slower evolution):

- Increase ROUND_DURATION (more time to catch)
- Decrease SURVIVAL_THRESHOLD (need to catch more to end round)

### Changing Mutation Rate

In genetic_system.gd:

```gdscript
const MUTATION_RATE: float = 0.05  # Change to 0.01 (less) or 0.10 (more)
```

**Effects**:

- Lower: Population more stable, slower adaptation to new environments
- Higher: More variation, faster adaptation, can prevent fixation

### Adding New Traits

Example: Add a size trait

1. **Add to Allele**:

```gdscript
@export var size: float = 1.0  # 0.5 to 1.5
```

2. **Add to Genotype**:

```gdscript
func get_phenotype_size() -> float:
	if allele1.dominance > allele2.dominance:
		return allele1.size
	elif allele2.dominance > allele1.dominance:
		return allele2.size
	else:
		return (allele1.size + allele2.size) / 2.0
```

3. **Use in organism.gd**:

```gdscript
var size_multiplier = genotype.get_phenotype_size()
# Scale sprite or collision based on size_multiplier
```

4. **Update mutation function** in genetic_system.gd

### Modifying UI

All UI is in main.tscn. Key nodes:

- `UI/TopPanel/HBoxContainer/LeftInfo`: Species, habitat, generation labels
- `UI/TopPanel/HBoxContainer/VBoxContainer`: Allele frequencies, genotype frequencies, graph container
- `UI/PanelContainer/MarginContainer/CenterPanel`: Timer, caught count, control buttons
- `UI/HabitatSelection`: Habitat selection popup

Labels updated in main.gd's `update_ui()` function.

**UI Structure Details:**
The UI has two main sections:
1. **TopPanel/HBoxContainer**: Displays information in two columns (hidden during rounds)
   - **LeftInfo** (VBoxContainer): Species, habitat, generation labels
   - **VBoxContainer**: Population genetics data (allele/genotype frequencies and graph)
2. **PanelContainer/MarginContainer/CenterPanel** (VBoxContainer, positioned right): Round information and control buttons
   - Timer and caught count labels
   - Start round, next generation, show survivors, change habitat buttons

**UI Visibility Behavior:**
- `start_round()`: Hides `top_panel` and `show_survivors_button` to maximize play area
- `end_round()`: Shows `top_panel` and `show_survivors_button` to display genetics data

**Button Flow:**
- `start_round_button`: Only visible at simulation start (initial population)
- `next_gen_button`: Appears at `end_round()`, automatically calls `start_round()` via `create_next_generation()`
- Flow: Start Simulation → Round Ends → Next Gen Button → (auto) Start Round → Round Ends → Next Gen Button → ...

### Exporting the Game

**Windows**:

1. Open Project → Export
2. Select "Windows Desktop" preset
3. Click "Export Project"
4. Choose location and filename

**HTML5**:

1. Open Project → Export
2. Select "Web" preset
3. Click "Export Project"
4. Upload files to web server

Export templates must be installed first (Godot downloads automatically).

## Important Implementation Details

### Tab Indentation

**Critical**: User prefers tabs, not spaces. Always use tabs for indentation in GDScript files.

### Typed Arrays

When possible, use typed arrays for better performance:

```gdscript
var population: Array[Organism] = []  # Good
var population = []  # Works but less type-safe
```

### Signal Connections

Organisms emit `clicked` signal when pressed:

```gdscript
organism.clicked.connect(_on_organism_clicked)
```

### Node Management

Always check if nodes are valid before accessing:

```gdscript
if is_instance_valid(organism):
	organism.queue_free()
```

### Random Number Generation

Use built-in functions:

```gdscript
randf()  # Random float 0.0 to 1.0
randi()  # Random integer
randf_range(min, max)  # Random float in range
```

### Image Manipulation

For procedural graphics:

```gdscript
var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
image.set_pixel(x, y, color)
var texture = ImageTexture.create_from_image(image)
sprite.texture = texture
```

## Data Structures

### Population Data Tracking

```gdscript
var generation_data: Array[Dictionary] = []

# Each entry contains:
{
	"generation": int,
	"population_size": int,
	"allele_freq": {
		"dominant": float,  # 0.0 to 1.0
		"recessive": float  # 0.0 to 1.0
	},
	"genotype_freq": {
		"AA": float,  # Homozygous dominant
		"Aa": float,  # Heterozygous
		"aa": float   # Homozygous recessive
	},
	"caught": int
}
```

### Frequency Calculations

In genetic_system.gd:

```gdscript
static func calculate_allele_frequencies(population: Array[Organism]) -> Dictionary:
	var dominant_count = 0
	var recessive_count = 0
	var total_alleles = population.size() * 2  # Diploid
	
	for org in population:
		if org.genotype.allele1.dominance > 0:
			dominant_count += 1
		else:
			recessive_count += 1
		# Same for allele2...
	
	return {
		"dominant": dominant_count / float(total_alleles),
		"recessive": recessive_count / float(total_alleles)
	}
```

## Debugging Tips

### Common Issues

**Organisms not visible**:

- Check if organism.tscn is in project
- Verify update_appearance() is called
- Check z-index (organisms should be above background)

**No evolution happening**:

- Verify fitness is being calculated
- Check if survivors are actually reproducing
- Ensure population isn't going extinct (min 2 survivors needed)

**UI not updating**:

- Check if update_ui() is called in _process()
- Verify labels exist in scene tree
- Check signal connections

**Graph not drawing**:

- Need at least 2 generations of data
- Verify _draw() is being called (queue_redraw())
- Check graph_container exists and has size

### Debug Printing

Use print() statements strategically:

```gdscript
print("Population size: ", population.size())
print("Allele freq: ", GeneticSystem.calculate_allele_frequencies(population))
print("Organism fitness: ", organism.fitness)
```

### Testing Scenarios

**Test directional selection**:

- Use Clean Bark Moths
- Dark moths should become rare over 5-10 generations
- Dominant (light) allele frequency should increase to ~80%+

**Test multi-niche environments**:

- Use Mixed Garden
- Should maintain diversity (multiple color morphs)
- No single color should dominate completely

**Test genetics**:

- Cross Aa × Aa should produce ~25% aa offspring
- Cross AA × aa should produce 100% Aa offspring
- Verify with genotype frequencies in UI

## Performance Considerations

**Current Performance**:

- Handles 50-60 organisms smoothly
- Background rendering is one-time per habitat
- Fitness calculation is O(n * m) where n=population, m=niches

**Optimization Tips**:

- Don't recreate textures every frame
- Cache phenotype colors in organisms
- Use `queue_free()` instead of `free()` for node removal
- Limit background patch count if adding complex patterns

## Educational Design Philosophy

### Accuracy vs. Simplicity Trade-offs

**Accurate**:

- Mendelian inheritance (exactly right)
- Dominance relationships (correct)
- Allele frequency changes (proper population genetics)
- Natural selection mechanism (conceptually perfect)

**Simplified**:

- Single gene (most traits are polygenic)
- Discrete generations (real populations overlap)
- Perfect reproduction (no mating failure)
- No sex determination (focuses on allele inheritance)

**Reason**: Simplifications focus students on core concepts without overwhelming complexity.

### Pedagogical Progression

**Day 1**: Simple habitats (moths/spiders)

- Learn basic natural selection
- See directional selection
- Understand fitness

**Day 2**: Two-niche habitats (flower + stem beetles)

- Understand multiple "good" colors
- See disruptive selection
- Grasp niche concept

**Day 3**: Complex habitats (mixed garden)

- Observe polymorphism
- Understand diversity maintenance
- Connect to biodiversity

This progression matches cognitive load to student readiness.

## Code Quality Standards

### Style Guide

- Tabs for indentation (user preference)
- Clear variable names (no single letters except loop indices)
- Comments explain WHY, not WHAT
- Type hints where possible
- Organize functions logically

### Documentation

- Use `##` for GDScript documentation comments
- Explain non-obvious algorithms
- Note any educational simplifications
- Reference real biology where relevant

### Error Handling

- Check for edge cases (empty populations, invalid indices)
- Use `is_instance_valid()` before accessing nodes
- Provide helpful error messages for debugging

## Extension Ideas

If users want to extend the simulation, here are well-scoped additions:

### Easy Extensions

- New habitat configurations (just add to habitat_config.gd)
- Adjust round timing or survival thresholds
- Change mutation rates
- Add new species shapes in organism.gd
- Create new background patterns in main.gd

### Medium Extensions

- Multiple simultaneous traits (color + size + pattern)
- Sexual selection (mate choice preferences)
- Carrying capacity (population limits)
- Environmental gradients (background changes over time)
- Data export to CSV
- Save/load simulation state

### Advanced Extensions

- Migration between populations
- Predator-prey co-evolution
- Population structure (subdivided populations)
- Quantitative genetics (many genes, small effects)
- Epistasis (gene interactions)
- Age structure (overlapping generations)

## Testing Checklist

When modifying the code, verify:

- [ ] Project loads without errors in Godot
- [ ] Can select all habitats from menu
- [ ] Organisms appear in correct colors
- [ ] Clicking organisms catches them
- [ ] Round timer counts down
- [ ] Round ends when timer expires or 80% caught
- [ ] Next generation button appears after round
- [ ] New population appears when starting next generation
- [ ] Allele frequencies update correctly
- [ ] Genotype frequencies sum to 100%
- [ ] Graph displays (after gen 2+)
- [ ] Can run 10+ generations without crashes
- [ ] Simple habitats show directional selection
- [ ] Complex habitats maintain diversity
- [ ] Export to Windows works
- [ ] Export to HTML5 works

## Quick Reference: File Purposes

|File|Primary Responsibility|
|---|---|
|main.gd|Game loop, UI, round management|
|organism.gd|Individual organism behavior, visuals, fitness|
|genetic_system.gd|Reproduction, mutations, population genetics|
|genotype.gd|Phenotype from alleles, dominance logic|
|allele.gd|Gene variant data structure|
|habitat_config.gd|Environment definitions|
|main.tscn|UI layout, node structure|
|organism.tscn|Organism node template|

## Quick Reference: Key Functions

|Function|Location|Purpose|
|---|---|---|
|`spawn_organism()`|main.gd|Create and place organism in world|
|`calculate_fitness()`|organism.gd|Determine camouflage quality|
|`reproduce()`|genetic_system.gd|Create offspring from parents|
|`get_phenotype_color()`|genotype.gd|Determine visible color from alleles|
|`update_ui()`|main.gd|Refresh UI labels and displays|
|`create_next_generation()`|main.gd|Population reproduction|

## Contact Points for Modifications

**Want to change evolution speed?** → main.gd: ROUND_DURATION, SURVIVAL_THRESHOLD

**Want to change genetic behavior?** → genetic_system.gd: MUTATION_RATE, reproduce()

**Want to add habitats?** → habitat_config.gd: Add new factory function

**Want to change visuals?** → organism.gd: update_appearance() → main.gd: render_*_background() functions

**Want to modify UI?** → main.tscn: Edit scene in Godot editor → main.gd: update_ui() function

## Final Notes

### What Works Well

- Genetics system is solid and extensible
- Multi-niche fitness calculation is elegant
- UI provides good data for students
- Code is well-organized and commented
- Exports cleanly to multiple platforms

### Known Limitations

- Single gene (not polygenic)
- No sex determination
- Discrete generations only
- Simplified mutation model
- No population structure

### Design Philosophy

This is an **educational tool**, not a research simulator. Accuracy is prioritized for core concepts (Mendelian genetics, natural selection mechanism), while complexity is reduced in areas that would distract from learning goals.

---

## Quick Start for AI Agents

1. **Read this entire document first**
2. **Understand the genetics system** (most important)
3. **Know the file structure** (what's where)
4. **Test changes incrementally** (don't modify multiple systems at once)
5. **Maintain tab indentation** (user preference)
6. **Keep educational focus** (simplicity over realism when in conflict)
7. **Document changes clearly** (future maintainers will thank you)

You now have everything needed to help with this project. Good luck! 🧬

---

**Project Version**: 2.0 (Enhanced with multi-color environments)  
**Last Updated**: October 2025  
**Godot Version**: 4.4+  
**License**: Free for educational use
