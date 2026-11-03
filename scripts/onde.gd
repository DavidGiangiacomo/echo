class_name Onde
extends Node2D
## L'onde d'écho (issue #9) : un cercle lumineux qui s'étend depuis l'endroit
## où la chauve-souris l'a lancée, à la vitesse et jusqu'à la portée de
## balance.json. Tout ce qu'il touche est révélé, à l'instant exact où son
## rayon atteint l'objet. Chaque insecte touché est marqué ; si l'onde en
## marque au moins 5, c'est un Chœur (issue #11).

signal choeur

const COULEUR := Color(1, 1, 1)
## Le cercle s'efface en ce temps, une fois sa portée atteinte.
const DUREE_FIN_S := 0.25

var debut := 0.0  # instant du lancer, en temps de jeu
var portee_px := 1800.0
var vitesse_px_s := 3600.0
var duree_marquage_s := 4.0
var insectes_marques := 0
var est_un_choeur := false

var _cibles: Array = []
var _prochaine := 0
var _marques: Array[Insecte] = []
var _minimum_choeur := 5


## Lance l'onde depuis `centre`. `cibles` vient de Grotte.cibles_a_portee :
## tout ce que l'onde peut toucher, du plus proche au plus lointain.
func lancer(centre: Vector2, cibles: Array) -> void:
	position = centre
	debut = Revelation.maintenant
	portee_px = Echelle.pixels(Formules.portee_echo(0, 0))
	vitesse_px_s = Echelle.pixels(Balance.donnees()["echo"]["vitesse_onde_m_s"])
	duree_marquage_s = Formules.duree_marquage(0)
	_minimum_choeur = int(Balance.donnees()["marquage"]["choeur_minimum_insectes"])
	_cibles = cibles
	# On note où se trouve chaque cible au lancer : si son segment est recyclé
	# pendant que l'onde s'étend, il aura bougé et ne sera pas révélé.
	for cible in _cibles:
		cible["origine"] = cible["objet"].global_position
	_prochaine = 0


## Rayon actuel du cercle, en pixels.
func rayon() -> float:
	return minf(vitesse_px_s * (Revelation.maintenant - debut), portee_px)


func _process(_delta: float) -> void:
	var rayon_actuel := vitesse_px_s * (Revelation.maintenant - debut)
	while _prochaine < _cibles.size() and _cibles[_prochaine]["distance"] <= rayon_actuel:
		_toucher(_cibles[_prochaine])
		_prochaine += 1
	queue_redraw()
	# Une fois sa portée atteinte, le cercle s'efface puis disparaît.
	if Revelation.maintenant - debut > portee_px / vitesse_px_s + DUREE_FIN_S:
		queue_free()


func _toucher(cible: Dictionary) -> void:
	var objet: Node2D = cible["objet"]
	if not is_instance_valid(objet) or objet.global_position != cible["origine"]:
		return
	# L'instant exact où le rayon a atteint l'objet, pendant cette image.
	var instant: float = debut + cible["distance"] / vitesse_px_s
	objet.reveler(instant, cible["indice"])
	if objet is Insecte and objet.visible:
		objet.marquer(instant, duree_marquage_s, est_un_choeur)
		_marques.append(objet)
		insectes_marques += 1
		if not est_un_choeur and insectes_marques >= _minimum_choeur:
			est_un_choeur = true
			for insecte in _marques:
				insecte.passer_en_choeur()
			choeur.emit()


func _draw() -> void:
	var age := Revelation.maintenant - debut
	var rayon_actuel := rayon()
	var effacement := clampf((age - portee_px / vitesse_px_s) / DUREE_FIN_S, 0.0, 1.0)
	var opacite := (0.85 - 0.6 * rayon_actuel / portee_px) * (1.0 - effacement)
	var couleur := Insecte.COULEUR if est_un_choeur else COULEUR
	var points := clampi(int(rayon_actuel / 8.0), 24, 512)
	draw_arc(Vector2.ZERO, rayon_actuel, 0.0, TAU, points, Color(couleur, opacite), 4.0 if est_un_choeur else 3.0, true)
