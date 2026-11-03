class_name Vol
extends Node2D
## Le vol : la chauve-souris, la grotte qui défile, les échos, l'audace et
## les insectes attrapés. C'est le cœur du prototype gris (étape 2).
##
## Le monde ne bouge pas : la chauve-souris avance vers la droite et la
## caméra la suit. Chaque objet garde sa place dans la grotte, ce qui rend
## l'onde simple à calculer : un cercle fixe, centré là où elle est partie.

signal insectes_changes(total: float)
signal audace_changee(valeur: float)
signal choeur

## Part de la largeur de l'écran laissée derrière la chauve-souris.
const PART_DERRIERE := 0.15
## La grotte existe un peu au-delà de ce qu'on voit, des deux côtés.
const MARGE_PX := 200.0

## Même graine, même grotte.
@export var graine := 1

@onready var grotte: Grotte = $Grotte
@onready var chauve_souris: ChauveSouris = $ChauveSouris
@onready var ondes: Node2D = $Ondes
@onready var camera: Camera2D = $Camera

var audace := Audace.new()
var insectes := 0.0
var echos := 0
var collisions := 0
var choeurs := 0

var _gestes := LecteurGestes.new()
var _portee_px := 0.0


func _ready() -> void:
	Revelation.maintenant = 0.0
	Revelation.duree_s = Formules.duree_revelation(0)  # pas encore de Mémoire
	_portee_px = Echelle.pixels(Formules.portee_echo(0, 0))  # ni d'Oreilles
	chauve_souris.heurte.connect(_sur_heurt)
	chauve_souris.attrape.connect(_sur_capture)
	grotte.preparer(graine)
	_suivre()
	# `godot --path . -- --demo` : un pilote automatique joue tout seul.
	if "--demo" in OS.get_cmdline_user_args():
		var pilote := PiloteAutomatique.new()
		pilote.vol = self
		add_child(pilote)


func _process(delta: float) -> void:
	Revelation.maintenant += delta
	var parcouru := chauve_souris.avancer(delta)
	# L'audace monte avec la distance, sauf pendant l'étourdissement.
	if not chauve_souris.est_etourdie():
		audace.voler(Echelle.metres(parcouru))
	_suivre()
	audace_changee.emit(audace.valeur())


## Les gestes du joueur, que l'interface n'a pas déjà pris. Un seul doigt
## compte : celui qui s'est posé en premier.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_gestes.appuyer(event.position)
		elif _gestes.relacher(event.position) == LecteurGestes.Geste.TOUCHER:
			lancer_echo()
	elif event is InputEventScreenDrag and event.index == 0:
		var geste := _gestes.glisser(event.position)
		if geste == LecteurGestes.Geste.GLISSER_HAUT:
			chauve_souris.changer_couloir(-1)
		elif geste == LecteurGestes.Geste.GLISSER_BAS:
			chauve_souris.changer_couloir(1)


## Envoie un écho : une onde part de la chauve-souris, et l'audace est divisée
## par deux. Impossible pendant l'étourdissement.
func lancer_echo() -> void:
	if chauve_souris.est_etourdie():
		return
	var onde := Onde.new()
	ondes.add_child(onde)
	onde.lancer(chauve_souris.position, grotte.cibles_a_portee(chauve_souris.position, _portee_px))
	onde.choeur.connect(_sur_choeur)
	audace.echo()
	echos += 1
	audace_changee.emit(audace.valeur())


## La caméra suit la chauve-souris ; la grotte se construit devant elle, au
## moins jusqu'à la portée de l'écho, et se recycle derrière.
func _suivre() -> void:
	var largeur := get_viewport_rect().size.x
	var derriere := maxf(160.0, largeur * PART_DERRIERE)
	var x := chauve_souris.position.x
	camera.position = Vector2(x - derriere + largeur / 2.0, 0.0)
	grotte.avancer(x - derriere - MARGE_PX, x - derriere + largeur + _portee_px + MARGE_PX)


func _sur_heurt(_obstacle: Obstacle) -> void:
	collisions += 1
	audace.collision()
	audace_changee.emit(audace.valeur())


## Un insecte attrapé vaut V = b · A · m (pas encore de colonie : b vaut la
## valeur de base de la grotte).
func _sur_capture(insecte: Insecte) -> void:
	var m := insecte.multiplicateur(Revelation.maintenant)
	var b := Formules.valeur_de_base(Balance.donnees()["grottes"][0], 0.0)
	var valeur := Formules.valeur_insecte(b, audace.valeur(), m)
	insectes += valeur
	_afficher_gain(insecte.position, valeur, m)
	grotte.retirer_insecte(insecte)
	insectes_changes.emit(insectes)


func _sur_choeur() -> void:
	choeurs += 1
	choeur.emit()


## Un petit « +4,2 » qui monte et s'efface là où l'insecte a été attrapé :
## blanc s'il n'était pas marqué, doré s'il l'était, plus gros en Chœur.
func _afficher_gain(ou: Vector2, valeur: float, m: float) -> void:
	var etiquette := Label.new()
	etiquette.text = "+" + Texte.nombre(valeur)
	var taille := 40
	var couleur := Color(1, 1, 1, 0.8)
	if m > 1.0:
		taille = 64 if m >= 6.0 else 52
		couleur = Insecte.COULEUR
	etiquette.add_theme_font_size_override("font_size", taille)
	etiquette.add_theme_color_override("font_color", couleur)
	etiquette.position = ou + Vector2(-30, -100)
	add_child(etiquette)
	var animation := etiquette.create_tween().set_parallel()
	animation.tween_property(etiquette, "position:y", etiquette.position.y - 90.0, 0.9)
	animation.tween_property(etiquette, "modulate:a", 0.0, 0.9)
	animation.chain().tween_callback(etiquette.queue_free)
