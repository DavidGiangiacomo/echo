extends GutTest
## Tests des formules du vol (scripts/formules.gd). Ce sont les mêmes exemples
## que ceux du simulateur (simulateur/test_simulateur.py) : le jeu et le
## simulateur doivent donner les mêmes valeurs. Critère de l'issue #10 : à
## 5 % près. Les valeurs attendues sont recalculées à partir de balance.json
## quand c'est possible : régler l'équilibrage ne casse pas ces tests.

const TOLERANCE := 0.05  # 5 %


func _a_5_pourcent(valeur: float, attendu: float) -> void:
	assert_almost_eq(valeur, attendu, attendu * TOLERANCE)


func test_l_audace_suit_les_exemples_du_gdd() -> void:
	# GDD : ×1,7 à 50 m, ×2,1 à 100 m, ×3,2 à 400 m.
	assert_almost_eq(Formules.audace(0.0), 1.0, 1e-9)
	_a_5_pourcent(Formules.audace(50.0), 1.7)
	_a_5_pourcent(Formules.audace(100.0), 2.1)
	_a_5_pourcent(Formules.audace(400.0), 3.2)


func test_distance_pour_audace_est_l_inverse_de_l_audace() -> void:
	for distance in [0.0, 10.0, 100.0, 1234.0]:
		assert_almost_eq(Formules.distance_pour_audace(Formules.audace(distance)), distance, 1e-6)


func test_un_echo_divise_l_audace_par_deux_sans_descendre_sous_un() -> void:
	assert_almost_eq(Formules.audace_apres_echo(3.2), 1.6, 1e-9)
	assert_almost_eq(Formules.audace_apres_echo(1.5), 1.0, 1e-9)


func test_multiplicateur_de_marquage() -> void:
	assert_eq(Formules.multiplicateur_marquage(false, false), 1.0)
	assert_eq(Formules.multiplicateur_marquage(true, false), 3.0)
	assert_eq(Formules.multiplicateur_marquage(true, true), 6.0)


func test_valeur_d_un_insecte() -> void:
	# V = b · A · m
	assert_almost_eq(Formules.valeur_insecte(2.0, 1.5, 3.0), 9.0, 1e-9)


func test_la_valeur_de_base_suit_la_colonie() -> void:
	var grotte: Dictionary = Balance.donnees()["grottes"][0]
	var k: float = Balance.donnees()["insectes"]["secondes_de_colonie"]
	assert_almost_eq(Formules.valeur_de_base(grotte, 0.0), grotte["valeur_insecte"], 1e-9)
	assert_almost_eq(Formules.valeur_de_base(grotte, 100.0), grotte["valeur_insecte"] + k * 100.0, 1e-9)


func test_le_marquage_s_allonge_avec_les_rhinolophes_jusqu_au_plafond() -> void:
	assert_almost_eq(Formules.duree_marquage(0), 4.0, 1e-9)
	assert_almost_eq(Formules.duree_marquage(10), 5.0, 1e-9)
	assert_almost_eq(Formules.duree_marquage(100), 7.0, 1e-9)


func test_la_portee_grandit_avec_oreilles_et_oreillards() -> void:
	var base: float = Balance.donnees()["echo"]["portee_m"]
	assert_almost_eq(Formules.portee_echo(0, 0), base, 1e-9)
	assert_almost_eq(Formules.portee_echo(2, 0), base * 1.2, 1e-9)
	assert_almost_eq(Formules.portee_echo(0, 200), base * 1.5, 1e-9)  # plafond +50 %
	assert_almost_eq(Formules.portee_echo(2, 30), base * 1.5, 1e-9)


func test_la_revelation_s_allonge_avec_la_memoire() -> void:
	assert_almost_eq(Formules.duree_revelation(0), 1.5, 1e-9)
	assert_almost_eq(Formules.duree_revelation(5), 2.5, 1e-9)


func test_instinct() -> void:
	# i(k) = min(0,85 ; 0,20 + 0,03 k)
	assert_almost_eq(Formules.instinct(0), 0.20, 1e-9)
	assert_almost_eq(Formules.instinct(10), 0.50, 1e-9)
	assert_almost_eq(Formules.instinct(22), 0.85, 1e-9)
	assert_almost_eq(Formules.instinct(100), 0.85, 1e-9)
