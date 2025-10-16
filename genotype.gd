class_name Genotype
extends Resource

## Holds two alleles (diploid genetics) and determines phenotype through dominance

var allele1: Allele
var allele2: Allele

func _init(a1: Allele, a2: Allele) -> void:
	allele1 = a1
	allele2 = a2

## Get the expressed phenotype color based on dominance
func get_phenotype_color() -> Color:
	if allele1.dominance > allele2.dominance:
		return allele1.color
	elif allele2.dominance > allele1.dominance:
		return allele2.color
	else:
		# Co-dominance: blend the colors
		return allele1.color.lerp(allele2.color, 0.5)

## Get the expressed pattern
func get_phenotype_pattern() -> Dictionary:
	var dominant_allele = allele1 if allele1.dominance >= allele2.dominance else allele2
	return {
		"type": dominant_allele.pattern_type,
		"intensity": dominant_allele.pattern_intensity
	}

## Get genotype as string for display (e.g., "AA", "Aa", "aa")
func get_genotype_string() -> String:
	var a1_symbol = "A" if allele1.dominance > 0 else "a"
	var a2_symbol = "A" if allele2.dominance > 0 else "a"
	var symbols = [a1_symbol, a2_symbol]
	symbols.sort()
	return symbols[1] + symbols[0]  # Display dominant first

## Check if homozygous (both alleles same dominance)
func is_homozygous() -> bool:
	return allele1.dominance == allele2.dominance

## Check if heterozygous
func is_heterozygous() -> bool:
	return !is_homozygous()
