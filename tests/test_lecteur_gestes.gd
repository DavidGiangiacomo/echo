extends GutTest
## Tests du lecteur de gestes (issue #8) : toucher pour l'écho, glisser pour
## changer de couloir. Critère de l'issue : aucun glissement n'est pris pour
## un toucher en 50 essais. Ces tests le vérifient sur des gestes simulés ;
## l'essai sur un vrai téléphone reste à faire.

const Geste = LecteurGestes.Geste

var _lecteur: LecteurGestes


func before_each() -> void:
	_lecteur = LecteurGestes.new()


## Joue un geste : le doigt se pose sur le premier point, glisse par tous les
## suivants et se lève sur le dernier. Renvoie les gestes reconnus.
func _jouer(points: Array) -> Array:
	var reconnus := []
	_lecteur.appuyer(points[0])
	for i in range(1, points.size()):
		var geste := _lecteur.glisser(points[i])
		if geste != Geste.AUCUN:
			reconnus.append(geste)
	var fin := _lecteur.relacher(points.back())
	if fin != Geste.AUCUN:
		reconnus.append(fin)
	return reconnus


func test_un_toucher_sans_bouger_est_un_toucher() -> void:
	assert_eq(_jouer([Vector2(500, 500)]), [Geste.TOUCHER])


func test_un_toucher_qui_tremble_un_peu_reste_un_toucher() -> void:
	assert_eq(_jouer([Vector2(500, 500), Vector2(508, 494), Vector2(512, 503)]), [Geste.TOUCHER])


func test_glisser_vers_le_haut() -> void:
	var reconnus := _jouer([Vector2(500, 600), Vector2(502, 550), Vector2(505, 470), Vector2(506, 420)])
	assert_eq(reconnus, [Geste.GLISSER_HAUT])


func test_glisser_vers_le_bas() -> void:
	var reconnus := _jouer([Vector2(500, 400), Vector2(498, 460), Vector2(497, 540)])
	assert_eq(reconnus, [Geste.GLISSER_BAS])


func test_un_long_glissement_ne_change_de_couloir_qu_une_fois() -> void:
	var reconnus := _jouer([Vector2(500, 900), Vector2(500, 750), Vector2(500, 500), Vector2(500, 200)])
	assert_eq(reconnus, [Geste.GLISSER_HAUT])


func test_un_geste_entre_les_deux_seuils_est_ignore() -> void:
	# Le doigt a bougé de 60 pixels : trop pour un toucher, pas assez pour un
	# glissement. Mieux vaut l'ignorer que lancer un écho par erreur.
	assert_eq(_jouer([Vector2(500, 500), Vector2(500, 560)]), [])


func test_un_glissement_de_cote_ne_fait_rien() -> void:
	assert_eq(_jouer([Vector2(300, 500), Vector2(450, 520), Vector2(600, 540)]), [])


## Critère de l'issue #8 : 50 glissements variés (longueur, direction,
## dérive de côté, vitesse), aucun pris pour un toucher.
func test_cinquante_glissements_aucun_pris_pour_un_toucher() -> void:
	var hasard := RandomNumberGenerator.new()
	hasard.seed = 8
	for essai in 50:
		var depart := Vector2(hasard.randf_range(200, 900), hasard.randf_range(300, 800))
		var sens := -1.0 if essai % 2 == 0 else 1.0
		var longueur := hasard.randf_range(LecteurGestes.SEUIL_GLISSER, 400.0)
		var derive := hasard.randf_range(-0.4, 0.4) * longueur
		var etapes := hasard.randi_range(2, 8)
		var points := [depart]
		for i in range(1, etapes + 1):
			var t := float(i) / etapes
			points.append(depart + Vector2(derive * t, sens * longueur * t))
		var reconnus := _jouer(points)
		assert_false(Geste.TOUCHER in reconnus, "glissement n° %d pris pour un toucher" % (essai + 1))
		var attendu := Geste.GLISSER_HAUT if sens < 0.0 else Geste.GLISSER_BAS
		assert_eq(reconnus, [attendu], "glissement n° %d" % (essai + 1))
