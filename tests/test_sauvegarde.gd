extends GutTest
## Tests de la sauvegarde (issue #13), repris du Somnambule. Ils écrivent dans
## un fichier à part et sur un GameState neuf : la vraie sauvegarde du joueur
## n'est jamais touchée.

const SCRIPT_GAME_STATE := preload("res://scripts/game_state.gd")
const SCRIPT_SAUVEGARDE := preload("res://scripts/sauvegarde.gd")
const CHEMIN := "user://sauvegarde_de_test.json"


func before_each() -> void:
	_effacer_fichiers()


func after_all() -> void:
	_effacer_fichiers()


func _effacer_fichiers() -> void:
	for chemin: String in [CHEMIN, CHEMIN + ".tmp"]:
		if FileAccess.file_exists(chemin):
			DirAccess.remove_absolute(chemin)


func _nouvel_etat() -> Node:
	var etat: Node = SCRIPT_GAME_STATE.new()
	add_child_autofree(etat)
	return etat


## Crée une sauvegarde branchée sur `etat`. Comme au lancement du jeu, elle
## charge le fichier dès son arrivée dans la scène.
func _nouvelle_sauvegarde(etat: Node) -> Node:
	var sauvegarde: Node = SCRIPT_SAUVEGARDE.new()
	sauvegarde.chemin = CHEMIN
	sauvegarde.etat = etat
	add_child_autofree(sauvegarde)
	return sauvegarde


func _lire_fichier() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CHEMIN))


func test_sans_fichier_la_partie_commence_a_zero() -> void:
	var etat := _nouvel_etat()
	_nouvelle_sauvegarde(etat)
	assert_eq(etat.insectes, 0.0)


func test_sauvegarder_ecrit_la_partie_dans_le_fichier() -> void:
	var etat := _nouvel_etat()
	etat.gagner_insectes(123.5)
	_nouvelle_sauvegarde(etat).sauvegarder()

	var donnees := _lire_fichier()
	assert_eq(donnees["insectes"], 123.5)
	assert_eq(donnees["insectes_de_la_saison"], 123.5)


func test_le_fichier_porte_un_numero_de_version() -> void:
	_nouvelle_sauvegarde(_nouvel_etat()).sauvegarder()
	assert_eq(_lire_fichier()["save_version"], float(SCRIPT_SAUVEGARDE.VERSION))


func test_le_fichier_porte_l_heure_de_la_sauvegarde() -> void:
	var avant := Time.get_unix_time_from_system()
	_nouvelle_sauvegarde(_nouvel_etat()).sauvegarder()
	assert_between(_lire_fichier()["horodatage"], avant - 1.0, avant + 5.0)


func test_le_fichier_temporaire_ne_reste_pas() -> void:
	_nouvelle_sauvegarde(_nouvel_etat()).sauvegarder()
	assert_true(FileAccess.file_exists(CHEMIN))
	assert_false(FileAccess.file_exists(CHEMIN + ".tmp"))


func test_au_lancement_suivant_on_retrouve_sa_partie() -> void:
	var premiere_partie := _nouvel_etat()
	premiere_partie.gagner_insectes(123.5)
	_nouvelle_sauvegarde(premiere_partie).sauvegarder()

	var partie_relancee := _nouvel_etat()
	_nouvelle_sauvegarde(partie_relancee)

	assert_eq(partie_relancee.insectes, 123.5)
	assert_eq(partie_relancee.insectes_de_la_saison, 123.5)


func test_une_nouvelle_sauvegarde_remplace_l_ancienne() -> void:
	var etat := _nouvel_etat()
	var sauvegarde := _nouvelle_sauvegarde(etat)
	etat.gagner_insectes(10.0)
	sauvegarde.sauvegarder()
	etat.gagner_insectes(10.0)
	sauvegarde.sauvegarder()
	assert_eq(_lire_fichier()["insectes"], 20.0)


## Critère de l'issue #13 : tuer l'application ne perd pas plus de 30 s.
## Le minuteur de la sauvegarde sonne toutes les 30 s, et chaque sonnerie
## écrit la partie.
func test_la_partie_est_sauvegardee_toutes_les_trente_secondes() -> void:
	var etat := _nouvel_etat()
	var sauvegarde := _nouvelle_sauvegarde(etat)
	var minuteurs := sauvegarde.get_children().filter(func(enfant: Node) -> bool: return enfant is Timer)
	assert_eq(minuteurs.size(), 1)
	var minuteur: Timer = minuteurs[0]
	assert_eq(minuteur.wait_time, 30.0)
	assert_false(minuteur.one_shot, "le minuteur doit sonner encore et encore")
	assert_false(minuteur.is_stopped(), "le minuteur doit tourner dès le lancement")

	etat.gagner_insectes(42.0)
	minuteur.timeout.emit()  # comme si les 30 s venaient de passer
	assert_eq(_lire_fichier()["insectes"], 42.0)


func test_la_mise_en_pause_sauvegarde_tout_de_suite() -> void:
	var etat := _nouvel_etat()
	var sauvegarde := _nouvelle_sauvegarde(etat)
	etat.gagner_insectes(77.0)
	sauvegarde.notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(_lire_fichier()["insectes"], 77.0)


func test_un_fichier_illisible_fait_repartir_de_zero_sans_planter() -> void:
	var fichier := FileAccess.open(CHEMIN, FileAccess.WRITE)
	fichier.store_string("{pas du json")
	fichier.close()

	var etat := _nouvel_etat()
	_nouvelle_sauvegarde(etat)

	assert_eq(etat.insectes, 0.0)


func test_une_sauvegarde_a_la_version_actuelle_n_est_pas_modifiee_par_la_migration() -> void:
	var sauvegarde := _nouvelle_sauvegarde(_nouvel_etat())
	var donnees := {"save_version": SCRIPT_SAUVEGARDE.VERSION, "insectes": 5.0}
	assert_eq(sauvegarde._migrer(donnees.duplicate()), donnees)
