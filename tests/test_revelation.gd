extends GutTest
## Tests de la révélation (issue #9) : un objet touché par l'onde reste bien
## visible pendant 1,5 s, puis s'efface en un fantôme très pâle qui reste.

var _duree: float
var _fondu: float
var _fantome: float


func before_all() -> void:
	_duree = Formules.duree_revelation(0)
	_fondu = Balance.donnees()["echo"]["fondu_s"]
	_fantome = Balance.donnees()["echo"]["opacite_fantome_pourcent"] / 100.0


func test_un_objet_jamais_touche_est_invisible() -> void:
	assert_eq(Revelation.opacite_a(-INF, 10.0, _duree), 0.0)


func test_un_objet_touche_reste_bien_visible_pendant_la_revelation() -> void:
	assert_eq(Revelation.opacite_a(2.0, 2.0, _duree), 1.0)
	assert_eq(Revelation.opacite_a(2.0, 2.0 + _duree, _duree), 1.0)


func test_ensuite_il_s_efface_progressivement() -> void:
	var a_mi_fondu := Revelation.opacite_a(2.0, 2.0 + _duree + _fondu / 2.0, _duree)
	assert_lt(a_mi_fondu, 1.0)
	assert_gt(a_mi_fondu, _fantome)


func test_puis_il_reste_un_fantome_tres_pale() -> void:
	assert_almost_eq(Revelation.opacite_a(2.0, 2.0 + _duree + _fondu, _duree), _fantome, 1e-9)
	assert_almost_eq(Revelation.opacite_a(2.0, 600.0, _duree), _fantome, 1e-9)
	assert_lt(_fantome, 0.3, "un fantôme doit rester très pâle")


func test_la_memoire_allonge_la_revelation() -> void:
	var duree_avec_memoire := Formules.duree_revelation(5)
	var instant := 2.0 + _duree + 0.5  # trop tard sans Mémoire
	assert_lt(Revelation.opacite_a(2.0, instant, _duree), 1.0)
	assert_eq(Revelation.opacite_a(2.0, instant, duree_avec_memoire), 1.0)
