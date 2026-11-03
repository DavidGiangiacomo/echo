extends GutTest
## Tests de la grotte (issue #7) : des segments enchaînés sans trou, recyclés
## sans rien créer de nouveau, une densité d'obstacles cohérente avec
## balance.json, et des insectes jamais cachés derrière un obstacle.

const SEGMENTS := [
	preload("res://scenes/segments/couloir_libre.tscn"),
	preload("res://scenes/segments/stalactites.tscn"),
	preload("res://scenes/segments/stalagmites.tscn"),
	preload("res://scenes/segments/chicane.tscn"),
	preload("res://scenes/segments/rocher.tscn"),
]

var _grotte: Grotte


func _nouvelle_grotte(graine: int) -> Grotte:
	var grotte := Grotte.new()
	grotte.scenes_segments.assign(SEGMENTS)
	grotte.scene_depart = SEGMENTS[0]
	grotte.scene_insecte = preload("res://scenes/insecte.tscn")
	add_child_autofree(grotte)
	grotte.preparer(graine)
	return grotte


func before_each() -> void:
	_grotte = _nouvelle_grotte(1)


func test_les_segments_s_enchainent_sans_trou() -> void:
	_grotte.avancer(0.0, 30000.0)
	var segments := _grotte.segments_actifs()
	assert_gt(segments.size(), 10)
	for i in range(1, segments.size()):
		assert_almost_eq(segments[i].position.x, segments[i - 1].fin_px(), 1e-3)


func test_chaque_vol_commence_par_des_couloirs_libres() -> void:
	_grotte.avancer(0.0, 5000.0)
	for i in _grotte.segments_de_depart:
		assert_eq(_grotte.segments_actifs()[i].obstacles().size(), 0)


func test_les_segments_passes_sont_recycles() -> void:
	# On fait défiler 200 écrans, soit environ 500 segments posés. La réserve
	# grandit un peu quand le hasard aligne plusieurs fois le même segment,
	# mais elle reste petite : les segments passés sont réutilisés.
	var largeur := 3000.0
	for ecran in 200:
		_grotte.avancer(ecran * largeur, (ecran + 1) * largeur)
	assert_lt(_grotte.segments_actifs().size(), 6)
	assert_lt(_grotte.nombre_de_segments(), SEGMENTS.size() * 6)


func test_la_densite_d_obstacles_reste_dans_les_espacements_de_balance() -> void:
	# Espacement moyen entre deux obstacles, tous couloirs confondus, compte
	# tenu du poids de chaque segment : il doit rester dans la fourchette que
	# le simulateur utilise.
	var obstacles := 0.0
	var longueur := 0.0
	for scene in SEGMENTS:
		var segment: Segment = scene.instantiate()
		obstacles += segment.poids * segment.obstacles().size()
		longueur += segment.poids * segment.longueur_m
		segment.free()
	var espacement := longueur / obstacles
	var reglage: Dictionary = Balance.donnees()["grottes"][0]["obstacles"]
	assert_between(espacement, reglage["espacement_min_m"], reglage["espacement_max_m"])


func test_aucun_insecte_n_est_cache_derriere_un_obstacle() -> void:
	_grotte.avancer(0.0, 60000.0)
	assert_gt(_grotte.insectes_actifs.size(), 20)
	var marge := Echelle.pixels(4.0)
	for insecte in _grotte.insectes_actifs:
		var x := insecte.position.x
		for obstacle in _grotte.obstacles_entre(x - marge, x + marge):
			assert_ne(Echelle.hauteur_couloir(obstacle.couloir()), insecte.position.y)


func test_le_premier_essaim_arrive_aux_espacements_de_balance() -> void:
	var reglage: Dictionary = Balance.donnees()["grottes"][0]["essaims"]
	_grotte.avancer(0.0, Echelle.pixels(reglage["espacement_max_m"] + 200.0))
	var premier := INF
	for insecte in _grotte.insectes_actifs:
		if insecte.essaim == 0:
			premier = minf(premier, insecte.position.x)
	assert_between(Echelle.metres(premier), reglage["espacement_min_m"], reglage["espacement_max_m"])


func test_meme_graine_meme_grotte() -> void:
	var autre := _nouvelle_grotte(1)
	_grotte.avancer(0.0, 20000.0)
	autre.avancer(0.0, 20000.0)
	var noms := func(grotte: Grotte) -> Array:
		return grotte.segments_actifs().map(func(s): return s.scene_file_path)
	assert_eq(noms.call(_grotte), noms.call(autre))
