extends GutTest
## Tests de GameState (issue #13). Chaque test travaille sur un exemplaire
## neuf, pas sur l'autoload : la vraie partie n'est jamais touchée.

const SCRIPT_GAME_STATE := preload("res://scripts/game_state.gd")

var _etat: Node


func before_each() -> void:
	_etat = SCRIPT_GAME_STATE.new()
	add_child_autofree(_etat)


func test_la_partie_commence_sans_insectes() -> void:
	assert_eq(_etat.insectes, 0.0)
	assert_eq(_etat.insectes_de_la_saison, 0.0)


func test_gagner_des_insectes_les_met_en_poche_et_au_total_de_la_saison() -> void:
	_etat.gagner_insectes(4.5)
	_etat.gagner_insectes(2.0)
	assert_eq(_etat.insectes, 6.5)
	assert_eq(_etat.insectes_de_la_saison, 6.5)


func test_chaque_changement_d_insectes_est_signale() -> void:
	# GUT écoute les signaux de l'objet pour pouvoir vérifier qu'ils sont partis.
	watch_signals(_etat)
	_etat.gagner_insectes(3.0)
	assert_signal_emitted_with_parameters(_etat, "insectes_changes", [3.0])


func test_la_sauvegarde_garde_les_insectes() -> void:
	_etat.gagner_insectes(120.0)
	_etat.insectes -= 20.0  # une dépense, comme le fera la colonie
	var donnees: Dictionary = _etat.vers_sauvegarde()

	var autre_partie: Node = SCRIPT_GAME_STATE.new()
	add_child_autofree(autre_partie)
	autre_partie.depuis_sauvegarde(donnees)
	assert_eq(autre_partie.insectes, 100.0)
	assert_eq(autre_partie.insectes_de_la_saison, 120.0)


func test_un_champ_absent_garde_sa_valeur_de_depart() -> void:
	_etat.depuis_sauvegarde({})
	assert_eq(_etat.insectes, 0.0)
	assert_eq(_etat.insectes_de_la_saison, 0.0)


func test_des_valeurs_impossibles_sont_corrigees() -> void:
	_etat.depuis_sauvegarde({"insectes": -5.0, "insectes_de_la_saison": -1.0})
	assert_eq(_etat.insectes, 0.0)
	assert_eq(_etat.insectes_de_la_saison, 0.0)
	# Le total de la saison ne peut pas être plus petit que ce qu'on a en poche.
	_etat.depuis_sauvegarde({"insectes": 50.0, "insectes_de_la_saison": 10.0})
	assert_eq(_etat.insectes_de_la_saison, 50.0)
