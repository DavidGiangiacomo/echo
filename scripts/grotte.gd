class_name Grotte
extends Node2D
## La grotte (issue #7) : des segments préfabriqués tirés au sort et enchaînés
## de gauche à droite, puis recyclés quand ils sortent de l'écran par la
## gauche. Rien n'est détruit en cours de jeu : on déplace ce qui existe déjà.
## La réserve grandit au besoin, quand le hasard aligne plusieurs fois le même
## segment, puis se stabilise vite.
##
## Les obstacles viennent des segments. Les insectes isolés et les essaims
## sont posés par-dessus, aux espacements de balance.json, comme dans le
## simulateur : le premier essaim arrive après 2 400 à 3 200 m de vol.

## Les segments que la grotte tire au sort, chacun selon son poids.
@export var scenes_segments: Array[PackedScene] = []
## Le segment sans obstacle par lequel commence chaque vol.
@export var scene_depart: PackedScene
@export var segments_de_depart := 2
@export var scene_insecte: PackedScene

## Les insectes en jeu, du plus ancien au plus récent.
var insectes_actifs: Array[Insecte] = []

var _hasard := RandomNumberGenerator.new()
var _reglages: Dictionary  # la grotte calcaire dans balance.json
var _poids_des_scenes := {}  # chemin de la scène -> poids

var _reserve: Array[Segment] = []
var _actifs: Array[Segment] = []  # de gauche à droite
var _fin_px := 0.0  # là où commencera le prochain segment
var _segments_poses := 0

var _insectes_reserve: Array[Insecte] = []
var _prochain_insecte_px := 0.0
var _prochain_essaim_px := 0.0
var _numero_essaim := 0


func _ready() -> void:
	_reglages = Balance.donnees()["grottes"][0]
	# Un exemplaire de chaque segment dès le départ : on y lit son poids, et il
	# attend dans la réserve.
	for scene in scenes_segments:
		var segment := _creer_segment(scene)
		_poids_des_scenes[scene.resource_path] = segment.poids
	if scene_depart != null:
		_creer_segment(scene_depart)
	preparer(0)


## Vide la grotte pour un nouveau vol. Même graine, même grotte.
func preparer(graine: int) -> void:
	_hasard.seed = graine
	# `.duplicate()` : on parcourt une copie, car _ranger retire de la liste.
	for segment in _actifs.duplicate():
		_ranger(segment)
	for insecte in insectes_actifs.duplicate():
		retirer_insecte(insecte)
	_fin_px = 0.0
	_segments_poses = 0
	_numero_essaim = 0
	_prochain_insecte_px = _tirer_espacement(_reglages["insectes"])
	_prochain_essaim_px = _tirer_espacement(_reglages["essaims"])


## Fait exister la grotte entre `gauche_px` et `droite_px` : pose des segments
## à droite, recycle ceux qui sont passés à gauche.
func avancer(gauche_px: float, droite_px: float) -> void:
	while _fin_px < droite_px:
		_poser_segment()
	while not _actifs.is_empty() and _actifs[0].fin_px() < gauche_px:
		_ranger(_actifs[0])
	_poser_insectes()
	for insecte in insectes_actifs.duplicate():
		if insecte.position.x < gauche_px:
			retirer_insecte(insecte)


## Les segments posés, de gauche à droite.
func segments_actifs() -> Array[Segment]:
	return _actifs


## Nombre de segments créés en tout, réserve comprise.
func nombre_de_segments() -> int:
	return _reserve.size() + _actifs.size()


## Tout ce que l'onde partie de `centre` peut toucher à moins de `portee_px`,
## du plus proche au plus lointain. Chaque cible est un dictionnaire
## {distance, objet, indice}.
func cibles_a_portee(centre: Vector2, portee_px: float) -> Array:
	var liste := []
	for segment in _actifs:
		segment.cibles(centre, portee_px, liste)
	for insecte in insectes_actifs:
		var distance := insecte.global_position.distance_to(centre)
		if distance <= portee_px:
			liste.append({"distance": distance, "objet": insecte, "indice": -1})
	# `sort_custom` trie avec une petite fonction qui compare deux cibles.
	liste.sort_custom(func(a, b): return a["distance"] < b["distance"])
	return liste


## Les obstacles dont l'abscisse est entre `x_min` et `x_max`.
func obstacles_entre(x_min: float, x_max: float) -> Array[Obstacle]:
	var liste: Array[Obstacle] = []
	for segment in _actifs:
		if segment.fin_px() < x_min or segment.position.x > x_max:
			continue
		for obstacle in segment.obstacles():
			if obstacle.global_position.x >= x_min and obstacle.global_position.x <= x_max:
				liste.append(obstacle)
	return liste


## Retire un insecte du jeu (attrapé ou passé) et le remet dans la réserve.
func retirer_insecte(insecte: Insecte) -> void:
	insecte.visible = false
	insecte.process_mode = Node.PROCESS_MODE_DISABLED
	insecte.set_deferred("monitorable", false)
	insectes_actifs.erase(insecte)
	_insectes_reserve.append(insecte)


# ---------------------------------------------------------------------------
# Segments
# ---------------------------------------------------------------------------


func _poser_segment() -> void:
	var scene := scene_depart if _segments_poses < segments_de_depart else _tirer_scene()
	var segment := _sortir_de_la_reserve(scene)
	segment.activer(_fin_px)
	_actifs.append(segment)
	_fin_px = segment.fin_px()
	_segments_poses += 1


## Tire une scène au sort, chacune selon son poids.
func _tirer_scene() -> PackedScene:
	var total := 0.0
	for scene in scenes_segments:
		total += _poids_des_scenes[scene.resource_path]
	var tirage := _hasard.randf() * total
	for scene in scenes_segments:
		tirage -= _poids_des_scenes[scene.resource_path]
		if tirage < 0.0:
			return scene
	return scenes_segments.back()


## Prend dans la réserve un segment de cette scène, ou en crée un s'il n'y en
## a plus.
func _sortir_de_la_reserve(scene: PackedScene) -> Segment:
	for i in _reserve.size():
		if _reserve[i].scene_file_path == scene.resource_path:
			return _reserve.pop_at(i)
	var segment := _creer_segment(scene)
	_reserve.erase(segment)
	return segment


func _creer_segment(scene: PackedScene) -> Segment:
	var segment: Segment = scene.instantiate()
	add_child(segment)
	segment.ranger()
	_reserve.append(segment)
	return segment


func _ranger(segment: Segment) -> void:
	segment.ranger()
	_actifs.erase(segment)
	_reserve.append(segment)


# ---------------------------------------------------------------------------
# Insectes
# ---------------------------------------------------------------------------


func _poser_insectes() -> void:
	# Les insectes isolés, un à un.
	while _prochain_insecte_px < _fin_px:
		_poser_insecte(_prochain_insecte_px, -1)
		_prochain_insecte_px += _tirer_espacement(_reglages["insectes"])

	# Les essaims : un groupe d'insectes sur quelques mètres. On attend que
	# toute sa longueur soit posée, pour qu'il évite les obstacles.
	var essaims: Dictionary = _reglages["essaims"]
	var longueur := Echelle.pixels(essaims["longueur_m"])
	while _prochain_essaim_px + longueur < _fin_px:
		var taille := _hasard.randi_range(int(essaims["taille_min"]), int(essaims["taille_max"]))
		for i in taille:
			_poser_insecte(_prochain_essaim_px + _hasard.randf() * longueur, _numero_essaim)
		_numero_essaim += 1
		_prochain_essaim_px += _tirer_espacement(essaims)


## Pose un insecte à l'abscisse `x`, dans un couloir tiré au sort où aucun
## obstacle ne le cache. S'il n'y en a aucun, l'insecte n'est pas posé.
func _poser_insecte(x: float, essaim: int) -> void:
	var couloirs := [0, 1, 2]
	# Mélange de Fisher-Yates avec notre propre hasard : même graine, même
	# grotte (`shuffle()` utiliserait le hasard global).
	for i in range(couloirs.size() - 1, 0, -1):
		var j := _hasard.randi_range(0, i)
		var temporaire: int = couloirs[i]
		couloirs[i] = couloirs[j]
		couloirs[j] = temporaire
	for couloir in couloirs:
		if not _obstacle_pres(x, couloir):
			var insecte: Insecte = _insectes_reserve.pop_back() if not _insectes_reserve.is_empty() else _creer_insecte()
			insecte.reinitialiser()
			insecte.essaim = essaim
			insecte.position = Vector2(x, Echelle.hauteur_couloir(couloir))
			insecte.visible = true
			insecte.process_mode = Node.PROCESS_MODE_INHERIT
			insecte.set_deferred("monitorable", true)
			insectes_actifs.append(insecte)
			return


## Vrai si un obstacle bouche ce couloir à moins de 4 m de `x`.
func _obstacle_pres(x: float, couloir: int) -> bool:
	var marge := Echelle.pixels(4.0)
	for obstacle in obstacles_entre(x - marge, x + marge):
		if obstacle.couloir() == couloir:
			return true
	return false


func _creer_insecte() -> Insecte:
	var insecte: Insecte = scene_insecte.instantiate()
	add_child(insecte)
	return insecte


## Distance jusqu'au prochain objet, tirée au hasard entre les espacements
## minimum et maximum de balance.json, en pixels.
func _tirer_espacement(reglage: Dictionary) -> float:
	return Echelle.pixels(_hasard.randf_range(reglage["espacement_min_m"], reglage["espacement_max_m"]))
