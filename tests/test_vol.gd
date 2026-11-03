extends GutTest
## Tests du vol complet (issues #8, #10 et #11) : gestes, écho, collision,
## capture d'un insecte. Le vol crédite un GameState neuf : la vraie partie
## n'est jamais touchée.

const SCENE_VOL := preload("res://scenes/vol.tscn")
const SCENE_INSECTE := preload("res://scenes/insecte.tscn")
const SCENE_OBSTACLE := preload("res://scenes/obstacle.tscn")
const SCRIPT_GAME_STATE := preload("res://scripts/game_state.gd")

var _vol: Vol
var _etat: Node


func before_each() -> void:
	_etat = SCRIPT_GAME_STATE.new()
	add_child_autofree(_etat)
	_vol = SCENE_VOL.instantiate()
	_vol.etat = _etat
	add_child_autofree(_vol)


func _toucher(position: Vector2, presse: bool) -> void:
	var evenement := InputEventScreenTouch.new()
	evenement.position = position
	evenement.pressed = presse
	_vol._unhandled_input(evenement)


func _glisser(position: Vector2, relatif: Vector2) -> void:
	var evenement := InputEventScreenDrag.new()
	evenement.position = position
	evenement.relative = relatif
	_vol._unhandled_input(evenement)


func test_un_toucher_lance_un_echo_qui_divise_l_audace() -> void:
	_vol.audace.voler(400.0)
	var avant := _vol.audace.valeur()
	_toucher(Vector2(500, 500), true)
	_toucher(Vector2(500, 500), false)
	assert_eq(_vol.echos, 1)
	assert_eq(_vol.ondes.get_child_count(), 1)
	assert_almost_eq(_vol.audace.valeur(), avant / 2.0, 1e-9)


func test_glisser_vers_le_haut_change_de_couloir_sans_echo() -> void:
	_toucher(Vector2(500, 600), true)
	_glisser(Vector2(500, 450), Vector2(0, -150))
	_toucher(Vector2(500, 450), false)
	assert_eq(_vol.chauve_souris.couloir, 0)
	assert_eq(_vol.echos, 0)


func test_une_collision_etourdit_et_remet_l_audace_a_un() -> void:
	_vol.audace.voler(300.0)
	var obstacle: Obstacle = SCENE_OBSTACLE.instantiate()
	add_child_autofree(obstacle)
	_vol.chauve_souris._sur_contact(obstacle)
	assert_true(_vol.chauve_souris.est_etourdie())
	assert_eq(_vol.audace.valeur(), 1.0)
	assert_eq(_vol.collisions, 1)
	# Étourdie, elle ne peut ni lancer d'écho ni heurter un autre obstacle.
	_vol.lancer_echo()
	assert_eq(_vol.echos, 0)
	_vol.chauve_souris._sur_contact(obstacle)
	assert_eq(_vol.collisions, 1)


func test_l_etourdissement_dure_une_seconde() -> void:
	var obstacle: Obstacle = SCENE_OBSTACLE.instantiate()
	add_child_autofree(obstacle)
	_vol.chauve_souris._sur_contact(obstacle)
	Revelation.maintenant += Balance.donnees()["vol"]["etourdissement_s"] + 0.01
	assert_false(_vol.chauve_souris.est_etourdie())


func test_un_insecte_marque_vaut_b_fois_a_fois_trois() -> void:
	_vol.audace.voler(100.0)
	var insecte: Insecte = SCENE_INSECTE.instantiate()
	add_child_autofree(insecte)
	insecte.marquer(Revelation.maintenant, 4.0, false)
	var b: float = Balance.donnees()["grottes"][0]["valeur_insecte"]
	var attendu := b * Formules.audace(100.0) * 3.0
	_vol.chauve_souris._sur_contact(insecte)
	assert_almost_eq(_vol.insectes, attendu, 1e-9)


func test_un_insecte_attrape_s_ajoute_aux_insectes_de_la_partie() -> void:
	var insecte: Insecte = SCENE_INSECTE.instantiate()
	add_child_autofree(insecte)
	_vol.chauve_souris._sur_contact(insecte)
	assert_gt(_vol.insectes, 0.0)
	assert_eq(_etat.insectes, _vol.insectes)
	assert_eq(_etat.insectes_de_la_saison, _vol.insectes)


func test_la_grotte_avance_avec_la_chauve_souris() -> void:
	await wait_seconds(0.5)
	assert_gt(_vol.chauve_souris.position.x, 0.0)
	assert_gt(_vol.grotte.segments_actifs().size(), 0)


## Place la chauve-souris dans le couloir de `cible`, un peu avant elle.
func _placer_avant(cible: Node2D, couloir: int) -> void:
	var chauve_souris := _vol.chauve_souris
	chauve_souris.couloir = couloir
	chauve_souris.position = Vector2(cible.global_position.x - 150.0, Echelle.hauteur_couloir(couloir))


## Ces deux tests passent par la vraie détection de Godot (couches et
## masques de collision), pas par un appel direct.
func test_la_chauve_souris_heurte_l_obstacle_de_son_couloir() -> void:
	_vol.grotte.avancer(0.0, 20000.0)
	var obstacle: Obstacle = _vol.grotte.obstacles_entre(3000.0, 20000.0)[0]
	_placer_avant(obstacle, obstacle.couloir())
	await wait_physics_frames(40)
	assert_eq(_vol.collisions, 1)
	assert_eq(_vol.audace.valeur(), 1.0)


func test_la_chauve_souris_attrape_l_insecte_de_son_couloir() -> void:
	_vol.grotte.avancer(0.0, 20000.0)
	var insecte: Insecte = _vol.grotte.insectes_actifs[0]
	var couloir := Echelle.COULOIRS.find(insecte.position.y)
	_placer_avant(insecte, couloir)
	await wait_physics_frames(40)
	assert_gt(_vol.insectes, 0.0)
	assert_false(insecte in _vol.grotte.insectes_actifs, "l'insecte attrapé quitte le jeu")
