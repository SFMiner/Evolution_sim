# Evolution Simulator - Natural Selection Educational Tool

An interactive simulation demonstrating natural selection and genetic inheritance through camouflage adaptation.

## Overview

This simulation allows students to observe how populations adapt to their environment over multiple generations through the process of natural selection. Organisms with better camouflage are harder to catch, giving them a survival advantage that gets passed to offspring.

## Features

### Multiple Habitats & Species
- **Pepper Moths**: Light and dark variants on clean or sooty tree bark
- **Crab Spiders**: Color variants hiding on yellow or pink flowers
- **Beetles**: Pattern variants on checkered or spotted surfaces

### Genetics System
- **Diploid genetics**: Each organism has two alleles for color
- **Dominance**: Dominant alleles mask recessive ones in the phenotype
- **Mendelian inheritance**: Sexual reproduction with random allele assortment
- **Mutations**: Small random changes in offspring (5% rate)
- **Recessive trait hiding**: Heterozygous organisms (Aa) show dominant phenotype but carry recessive alleles

### Gameplay Loop
1. **Selection Phase** (15 seconds): Click to catch visible organisms
2. **Survival**: Organisms not caught become parents
3. **Reproduction**: Next generation created from survivors
4. **Repeat**: Observe changes in allele frequencies over generations

### Data Tracking
- **Allele Frequencies**: Proportion of dominant (A) vs recessive (a) alleles
- **Genotype Frequencies**: AA (homozygous dominant), Aa (heterozygous), aa (homozygous recessive)
- **Population Graph**: Visual representation of allele frequency changes
- **Generation Counter**: Track evolutionary progress

## How to Use

### Getting Started
1. Launch the simulation
2. Select a habitat from the menu
3. Click "Start Round" to begin

### During a Round
- Click organisms to "catch" them
- Better-camouflaged organisms are harder to spot
- Round ends after 15 seconds or when 80% are caught

### Between Rounds
- Review allele and genotype frequencies
- Observe how selection pressure changes the population
- Click "Next Generation" to produce offspring from survivors

## Educational Concepts Demonstrated

### Natural Selection
- **Variation**: Initial population has diverse colors
- **Selection**: Poorly camouflaged organisms caught more often
- **Inheritance**: Survivors pass genes to offspring
- **Adaptation**: Population becomes better camouflaged over time

### Mendelian Genetics
- **Dominant/Recessive**: See how recessive traits hide in heterozygotes
- **Allele Frequencies**: Track how selection changes gene pools
- **Hardy-Weinberg**: Observe deviation from equilibrium under selection
- **Genetic Drift**: Small populations show random changes

### Key Observations for Students
1. **Initial diversity**: Mixed colors in generation 1
2. **Selection pressure**: Catching removes maladapted individuals
3. **Directional selection**: Allele frequencies shift toward advantageous traits
4. **Recessive hiding**: Aa genotypes maintain recessive alleles while appearing dominant
5. **Speed of evolution**: Strong selection can cause rapid change

## Technical Details

### Genetic Model
- Each organism has 2 alleles (diploid)
- Alleles have:
  - Color value (RGB)
  - Dominance level (0 or 1)
  - Pattern type (solid, spotted, striped)
  - Pattern intensity

### Fitness Calculation
Fitness = Color difference from background
- Lower difference = better camouflage = harder to spot

### Reproduction
- Random parent selection from survivors
- One allele from each parent (meiosis simulation)
- 5% mutation rate per allele
- Population size maintained at starting value

### Round End Conditions
- Timer expires (15 seconds), OR
- Population drops below 20% of initial size

## Export Options

The simulation can be exported as:
- **Windows Executable**: Standalone .exe file
- **HTML5**: Browser-based version for web deployment

## Tips for Teachers

### Demonstration Ideas
1. **Compare environments**: Run moths on light vs dark bark
2. **Predict outcomes**: Have students hypothesize before each generation
3. **Graph analysis**: Discuss why curves change shape
4. **Incomplete dominance**: Explain AA vs Aa vs aa ratios

### Discussion Questions
- Why don't all organisms get caught immediately?
- What happens to recessive alleles in early generations?
- How many generations until population is well-adapted?
- What would happen if the environment changed suddenly?
- Why does genetic diversity matter for adaptation?

### Modifications
- Adjust `ROUND_DURATION` in main.gd for longer/shorter selection
- Modify `MUTATION_RATE` in genetic_system.gd to see mutation effects
- Change `SURVIVAL_THRESHOLD` to vary selection intensity

## System Requirements

- Godot 4.4+ (for development)
- Exported builds run on Windows 10+, modern web browsers
- No special hardware requirements

## Credits

Created for educational demonstration of:
- Darwin's finches and adaptation
- Peppered moth evolution during Industrial Revolution
- Mendelian genetics and inheritance patterns
- Natural selection mechanisms

## License

Free for educational use.
