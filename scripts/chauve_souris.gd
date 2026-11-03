class_name ChauveSouris
extends Area2D
## La chauve-souris (issue #8). Elle avance seule vers la droite ; le joueur
## la fait changer de couloir en glissant le doigt. Les couloirs ont été
## préférés au vol libre, où le doigt la guidait (issue #6).
##
## Une collision l'étourdit une seconde : elle continue de voler mais ne peut
## plus rien faire, et ne touche ni n'attrape plus rien pendant ce temps.

## `signal` : un message que d'autres nœuds peuvent écouter. Le Vol écoute
## ces deux-là pour l'audace et le score.
signal heurte(obstacle: Obstacle)
signal attrape(insecte: Insecte)

const COULEUR := Color(0.92, 0.94, 1.0)
const COULEUR_ETOURDIE := Color(0.5, 0.5, 0.56)

## Le couloir visé : 0 plafond, 1 milieu, 2 sol.
var couloir := 1
var vitesse_px_s := 600.0
var etourdie_jusqu_a := -INF

var _duree_changement_s := 0.15
var _duree_etourdissement_s := 1.0
var _transition: Tween


func _ready() -> void:
	var reglages: Dictionary = Balance.donnees()["vol"]
	vitesse_px_s = Echelle.pixels(reglages["vitesse_m_s"])
	_duree_changement_s = reglages["changement_couloir_s"]
	_duree_etourdissement_s = reglages["etourdissement_s"]
	position.y = Echelle.hauteur_couloir(couloir)
	# Godot appelle _sur_contact quand une autre zone touche la chauve-souris.
	area_entered.connect(_sur_contact)


func _process(_delta: float) -> void:
	# Étourdie, elle bascule d'un côté et de l'autre.
	rotation = sin(Revelation.maintenant * 22.0) * 0.45 if est_etourdie() else 0.0
	queue_redraw()  # pour le battement d'ailes


## Avance de `delta` secondes. Renvoie la distance parcourue, en pixels.
func avancer(delta: float) -> float:
	var distance := vitesse_px_s * delta
	position.x += distance
	return distance


func est_etourdie() -> bool:
	return Revelation.maintenant < etourdie_jusqu_a


## Monte (`sens` = -1) ou descend (`sens` = +1) d'un couloir.
func changer_couloir(sens: int) -> void:
	aller_au_couloir(couloir + sens)


## Rejoint le couloir demandé.
func aller_au_couloir(nouveau: int) -> void:
	if est_etourdie():
		return
	nouveau = clampi(nouveau, 0, Echelle.COULOIRS.size() - 1)
	if nouveau != couloir:
		_rejoindre(nouveau)


## Glisse jusqu'au couloir `nouveau`. Un Tween fait varier une propriété en
## douceur : ici la hauteur, en `changement_couloir_s` secondes.
func _rejoindre(nouveau: int) -> void:
	couloir = nouveau
	if _transition != null:
		_transition.kill()
	_transition = create_tween()
	_transition.tween_property(self, "position:y", Echelle.hauteur_couloir(couloir), _duree_changement_s)


func _sur_contact(zone: Area2D) -> void:
	if est_etourdie():
		return
	if zone is Obstacle:
		etourdie_jusqu_a = Revelation.maintenant + _duree_etourdissement_s
		heurte.emit(zone)
	elif zone is Insecte:
		attrape.emit(zone)


## Une petite silhouette toujours visible, légèrement lumineuse, au battement
## d'ailes lisible (GDD).
func _draw() -> void:
	var couleur := COULEUR_ETOURDIE if est_etourdie() else COULEUR
	draw_circle(Vector2.ZERO, 48.0, Color(couleur, 0.07))  # halo
	var battement := sin(Revelation.maintenant * 14.0) * 16.0
	var aile_gauche := PackedVector2Array([
		Vector2(-6, -4), Vector2(-30, -18 + battement), Vector2(-58, -10 + battement),
		Vector2(-44, 4 + battement * 0.5), Vector2(-24, 8), Vector2(-8, 6),
	])
	var aile_droite := PackedVector2Array()
	for i in range(aile_gauche.size() - 1, -1, -1):
		aile_droite.append(Vector2(-aile_gauche[i].x, aile_gauche[i].y))
	draw_colored_polygon(aile_gauche, couleur)
	draw_colored_polygon(aile_droite, couleur)
	draw_circle(Vector2(0, 2), 11.0, couleur)
	# Les oreilles.
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -4), Vector2(-6, -19), Vector2(-2, -7)]), couleur)
	draw_colored_polygon(PackedVector2Array([Vector2(2, -7), Vector2(6, -19), Vector2(9, -4)]), couleur)
