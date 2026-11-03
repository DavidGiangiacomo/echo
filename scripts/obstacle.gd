class_name Obstacle
extends Area2D
## Un obstacle de la grotte calcaire : stalactite (couloir du plafond),
## stalagmite (couloir du sol) ou rocher (couloir du milieu). Il reste
## invisible tant que l'onde ne l'a pas touché (issue #9), puis on voit son
## contour, qui s'efface en fantôme.
##
## Sa position est en x l'endroit où il se trouve dans le segment, et en y le
## milieu de la grotte : sa forme dit jusqu'où il descend ou monte.

enum Forme { STALACTITE, STALAGMITE, ROCHER }

const COULEUR := Color(1, 1, 1)
const EPAISSEUR := 4.0

## `@export` : la valeur se règle dans l'inspecteur de l'éditeur, pour chaque
## obstacle posé dans un segment.
@export var forme := Forme.STALACTITE

## Dernier instant où l'onde l'a touché ; -INF : jamais.
var revele_a := -INF

var _contour := PackedVector2Array()
var _opacite := 0.0


func _ready() -> void:
	_contour = contour_de(forme)
	# La forme de collision suit le contour dessiné : on heurte ce qu'on voit.
	$Forme.polygon = _contour


func _process(_delta: float) -> void:
	var opacite := Revelation.opacite(revele_a)
	if opacite != _opacite:
		_opacite = opacite
		queue_redraw()  # demande à Godot de rappeler _draw()


func _draw() -> void:
	if _opacite <= 0.0:
		return
	var ligne := _contour.duplicate()
	# Un rocher flotte : on referme son contour. Stalactites et stalagmites
	# tiennent à la paroi, qui dessine déjà leur pied : on n'en trace que les
	# flancs.
	if forme == Forme.ROCHER:
		ligne.append(_contour[0])
	draw_polyline(ligne, Color(COULEUR, _opacite), EPAISSEUR, true)


## L'onde l'a touché à `instant`. `_indice` ne sert qu'aux parois.
func reveler(instant: float, _indice := -1) -> void:
	revele_a = instant


## Le couloir que l'obstacle bouche : 0 plafond, 1 milieu, 2 sol.
func couloir() -> int:
	match forme:
		Forme.STALACTITE:
			return 0
		Forme.STALAGMITE:
			return 2
	return 1


## Distance de l'onde au point du contour le plus proche de `centre`.
func distance_a(centre: Vector2) -> float:
	var plus_courte := INF
	for point in _contour:
		plus_courte = minf(plus_courte, (global_position + point).distance_to(centre))
	return plus_courte


## Remet l'obstacle dans le noir, avant que son segment ne resserve.
func reinitialiser() -> void:
	revele_a = -INF
	_opacite = 0.0
	queue_redraw()


## Le contour d'un obstacle, en pixels, autour de sa position.
## Une stalactite descend du plafond jusqu'à 140 pixels au-dessus du milieu :
## elle bouche le couloir du plafond (à −270) sans toucher celui du milieu.
## Le rocher tient dans le couloir du milieu (±135).
static func contour_de(une_forme: Forme) -> PackedVector2Array:
	match une_forme:
		Forme.STALACTITE:
			return PackedVector2Array([
				Vector2(-48, Echelle.PLAFOND), Vector2(-14, -180),
				Vector2(0, -140), Vector2(14, -180), Vector2(48, Echelle.PLAFOND),
			])
		Forme.STALAGMITE:
			return PackedVector2Array([
				Vector2(-48, Echelle.SOL), Vector2(-14, 180),
				Vector2(0, 140), Vector2(14, 180), Vector2(48, Echelle.SOL),
			])
	return PackedVector2Array([
		Vector2(-55, -20), Vector2(-25, -130), Vector2(20, -135),
		Vector2(55, -35), Vector2(45, 105), Vector2(0, 135), Vector2(-45, 95),
	])
