extends GutTest
## Tests de l'onde (issues #9 et #11) : elle révèle chaque objet à l'instant
## exact où son rayon l'atteint, marque les insectes touchés, et déclenche
## un Chœur à partir de 5 insectes.

const SCENE_INSECTE := preload("res://scenes/insecte.tscn")

var _onde: Onde
var _vitesse_px_s: float


func before_each() -> void:
	Revelation.maintenant = 10.0
	_onde = Onde.new()
	add_child_autofree(_onde)
	_vitesse_px_s = Echelle.pixels(Balance.donnees()["echo"]["vitesse_onde_m_s"])


## Pose `nombre` insectes à droite du centre, espacés de `pas` pixels, et
## renvoie la liste des cibles telle que la grotte la fournirait.
func _insectes(nombre: int, pas: float) -> Array:
	var cibles := []
	for i in nombre:
		var insecte: Insecte = SCENE_INSECTE.instantiate()
		add_child_autofree(insecte)
		insecte.position = Vector2((i + 1) * pas, 0.0)
		cibles.append({"distance": insecte.position.x, "objet": insecte, "indice": -1})
	return cibles


## Avance l'horloge du jeu et fait travailler l'onde.
func _attendre(secondes: float) -> void:
	Revelation.maintenant += secondes
	_onde._process(secondes)


func test_un_objet_est_revele_quand_le_rayon_l_atteint() -> void:
	var cibles := _insectes(1, 900.0)
	var insecte: Insecte = cibles[0]["objet"]
	_onde.lancer(Vector2.ZERO, cibles)
	_attendre(0.2)  # rayon : 720 pixels
	assert_eq(insecte.revele_a, -INF, "pas encore atteint")
	_attendre(0.1)  # rayon : 1 080 pixels
	assert_almost_eq(insecte.revele_a, 10.0 + 900.0 / _vitesse_px_s, 1e-6)


func test_chaque_insecte_touche_est_marque() -> void:
	var cibles := _insectes(3, 200.0)
	_onde.lancer(Vector2.ZERO, cibles)
	_attendre(1.0)
	assert_eq(_onde.insectes_marques, 3)
	assert_false(_onde.est_un_choeur)
	var insecte: Insecte = cibles[0]["objet"]
	assert_eq(insecte.multiplicateur(Revelation.maintenant), 3.0)


func test_cinq_insectes_marques_font_un_choeur() -> void:
	var cibles := _insectes(5, 200.0)
	watch_signals(_onde)
	_onde.lancer(Vector2.ZERO, cibles)
	_attendre(1.0)
	assert_true(_onde.est_un_choeur)
	assert_signal_emit_count(_onde, "choeur", 1)
	# Tous les insectes de ce Chœur valent ×6, y compris les premiers marqués.
	for cible in cibles:
		assert_eq(cible["objet"].multiplicateur(Revelation.maintenant), 6.0)


func test_le_marquage_s_arrete_apres_sa_duree() -> void:
	var cibles := _insectes(1, 100.0)
	var insecte: Insecte = cibles[0]["objet"]
	_onde.lancer(Vector2.ZERO, cibles)
	_attendre(0.1)
	assert_eq(insecte.multiplicateur(Revelation.maintenant + Formules.duree_marquage(0) - 0.1), 3.0)
	assert_eq(insecte.multiplicateur(Revelation.maintenant + Formules.duree_marquage(0) + 0.1), 1.0)


func test_un_objet_qui_a_bouge_depuis_le_lancer_n_est_pas_revele() -> void:
	# Son segment a été recyclé plus loin pendant que l'onde s'étendait.
	var cibles := _insectes(1, 600.0)
	var insecte: Insecte = cibles[0]["objet"]
	_onde.lancer(Vector2.ZERO, cibles)
	insecte.position.x += 5000.0
	_attendre(0.5)
	assert_eq(insecte.revele_a, -INF)
