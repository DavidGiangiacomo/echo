class_name Parois
extends Node2D
## Le plafond et le sol d'un segment. L'onde les révèle point par point : on
## voit le contour de la grotte s'allumer au passage de l'onde, puis
## s'effacer en fantôme.

## Un point de paroi tous les 2 m.
const PAS_M := 2.0
## Hauteur maximale des bosses du plafond et du sol, en pixels.
const RELIEF := 14.0
const COULEUR := Color(1, 1, 1)
const EPAISSEUR := 3.0

var _plafond := PackedVector2Array()
var _sol := PackedVector2Array()
## Un instant de révélation par point : ceux du plafond, puis ceux du sol.
var _revele_a := PackedFloat64Array()
var _derniere_revelation := -INF


## Trace les parois sur `longueur_px`. La même graine donne les mêmes bosses.
## Les deux bouts restent à la hauteur exacte du plafond et du sol, pour que
## les segments se raccordent.
func construire(longueur_px: float, graine: int) -> void:
	var hasard := RandomNumberGenerator.new()
	hasard.seed = graine
	var nombre := int(round(longueur_px / Echelle.pixels(PAS_M)))
	_plafond.clear()
	_sol.clear()
	for i in nombre + 1:
		var x := longueur_px * i / nombre
		var bout := i == 0 or i == nombre
		var bosse_haut := 0.0 if bout else hasard.randf_range(0.0, RELIEF)
		var bosse_bas := 0.0 if bout else hasard.randf_range(0.0, RELIEF)
		_plafond.append(Vector2(x, Echelle.PLAFOND + bosse_haut))
		_sol.append(Vector2(x, Echelle.SOL - bosse_bas))
	_revele_a.resize(_plafond.size() + _sol.size())
	reinitialiser()


func _process(_delta: float) -> void:
	if Revelation.en_fondu(_derniere_revelation):
		queue_redraw()


func _draw() -> void:
	if _derniere_revelation == -INF:
		return
	draw_polyline_colors(_plafond, _couleurs(0, _plafond.size()), EPAISSEUR, true)
	draw_polyline_colors(_sol, _couleurs(_plafond.size(), _sol.size()), EPAISSEUR, true)


## Ajoute à `liste` les points de paroi à moins de `portee` de `centre`.
func cibles(centre: Vector2, portee: float, liste: Array) -> void:
	for i in _plafond.size():
		_ajouter_cible(global_position + _plafond[i], i, centre, portee, liste)
	for i in _sol.size():
		_ajouter_cible(global_position + _sol[i], _plafond.size() + i, centre, portee, liste)


## L'onde a touché le point numéro `indice` à `instant`.
func reveler(instant: float, indice := -1) -> void:
	_revele_a[indice] = instant
	_derniere_revelation = maxf(_derniere_revelation, instant)
	queue_redraw()


func reinitialiser() -> void:
	_revele_a.fill(-INF)
	_derniere_revelation = -INF
	queue_redraw()


func _ajouter_cible(point: Vector2, indice: int, centre: Vector2, portee: float, liste: Array) -> void:
	var distance := point.distance_to(centre)
	if distance <= portee:
		liste.append({"distance": distance, "objet": self, "indice": indice})


## Une couleur par point, plus ou moins transparente selon sa révélation.
func _couleurs(debut: int, nombre: int) -> PackedColorArray:
	var couleurs := PackedColorArray()
	for i in nombre:
		couleurs.append(Color(COULEUR, Revelation.opacite(_revele_a[debut + i])))
	return couleurs
