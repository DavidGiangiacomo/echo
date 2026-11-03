extends GutTest
## Tests de l'audace (issue #10). Le dernier test rejoue une suite de vols,
## d'échos et d'une collision, et la compare aux valeurs que donne le
## simulateur (simulateur/formules.py) pour la même suite.

var _audace: Audace


func before_each() -> void:
	_audace = Audace.new()


func test_au_depart_l_audace_vaut_un() -> void:
	assert_eq(_audace.valeur(), 1.0)


func test_l_audace_monte_avec_la_distance() -> void:
	_audace.voler(100.0)
	assert_almost_eq(_audace.valeur(), Formules.audace(100.0), 1e-9)


func test_un_echo_divise_l_audace_par_deux() -> void:
	_audace.voler(400.0)
	var avant := _audace.valeur()
	_audace.echo()
	assert_almost_eq(_audace.valeur(), avant / 2.0, 1e-9)


func test_apres_un_echo_l_audace_remonte_sur_la_meme_courbe() -> void:
	_audace.voler(400.0)
	_audace.echo()
	var distance := _audace.distance_m
	_audace.voler(50.0)
	assert_almost_eq(_audace.valeur(), Formules.audace(distance + 50.0), 1e-9)


func test_une_collision_remet_l_audace_a_un() -> void:
	_audace.voler(200.0)
	_audace.collision()
	assert_eq(_audace.valeur(), 1.0)


## Critère de l'issue #10 : les valeurs correspondent au simulateur à ±5 %.
## Les valeurs attendues ont été calculées avec simulateur/formules.py et les
## réglages actuels de balance.json (échelle 50 m, division par 2).
func test_meme_suite_meme_audace_que_le_simulateur() -> void:
	var suite := [
		["voler", 100.0, 2.098612],
		["echo", 0.0, 1.049306],
		["voler", 30.0, 1.501104],
		["echo", 0.0, 1.0],
		["voler", 400.0, 3.197225],
		["echo", 0.0, 1.598612],
		["voler", 25.0, 1.841391],
		["collision", 0.0, 1.0],
		["voler", 60.0, 1.788457],
	]
	for etape in suite:
		match etape[0]:
			"voler":
				_audace.voler(etape[1])
			"echo":
				_audace.echo()
			"collision":
				_audace.collision()
		assert_almost_eq(_audace.valeur(), etape[2], etape[2] * 0.05, "après « %s »" % etape[0])
