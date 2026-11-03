class_name Echelle
## Passage des mètres de balance.json aux pixels de l'écran, et géométrie de
## la grotte.
##
## L'écran de référence fait 1080 × 1080 et s'élargit selon la forme de
## l'écran (« expand » dans project.godot). Le jeu se joue en paysage, comme
## l'a tranché l'issue #6 : la grotte garde la même taille, et plus l'écran est
## allongé, plus on voit loin devant.

## À 30 pixels par mètre, la chauve-souris (20 m/s) parcourt 600 pixels par
## seconde, et l'onde (60 m) couvre 1 800 pixels : la largeur d'un écran
## paysage devant elle.
const PIXELS_PAR_METRE := 30.0

## Hauteur du plafond et du sol. En Godot, l'axe y descend : le plafond est
## en négatif, le sol en positif. La grotte (28 m de haut) laisse un peu de
## noir en haut de l'écran paysage, pour l'affichage du score.
const PLAFOND := -420.0
const SOL := 420.0

## Hauteur des trois couloirs de vol du GDD : plafond, milieu, sol (9 m entre
## deux couloirs).
const COULOIRS := [-270.0, 0.0, 270.0]


static func pixels(metres: float) -> float:
	return metres * PIXELS_PAR_METRE


static func metres(distance_px: float) -> float:
	return distance_px / PIXELS_PAR_METRE


## La hauteur d'un couloir : 0 plafond, 1 milieu, 2 sol.
static func hauteur_couloir(couloir: int) -> float:
	return COULOIRS[couloir]
