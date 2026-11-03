extends Node
## Sauvegarde automatique de la partie, chargée au démarrage sous le nom
## Sauvegarde (autoload, après GameState). Reprise du Somnambule (issue #13).
##
## La partie est écrite en JSON dans user://, le dossier que le système
## réserve au jeu : toutes les 30 secondes, quand l'application passe en
## arrière-plan, et quand on ferme la fenêtre sur ordinateur. Si le téléphone
## tue l'application, on perd donc au plus 30 secondes de partie.
##
## Chaque sauvegarde porte son heure : les gains hors-ligne (issue #20) en
## tireront le temps passé loin du jeu.
##
## Le fichier porte un numéro de version, `save_version`. Quand son format
## changera, _migrer() mettra les anciennes sauvegardes au format du jour.

const VERSION := 1
const INTERVALLE_S := 30.0

## Le fichier de sauvegarde. Les tests en choisissent un autre.
var chemin := "user://sauvegarde.json"
## L'état à sauvegarder. Les tests en fournissent un autre que la vraie partie.
var etat: Node = GameState


func _ready() -> void:
	charger()

	# Un Timer est un minuteur : il émet `timeout` toutes les `wait_time`
	# secondes, et l'on y branche la sauvegarde.
	var minuteur := Timer.new()
	minuteur.wait_time = INTERVALLE_S
	minuteur.timeout.connect(sauvegarder)
	add_child(minuteur)
	minuteur.start()


## Godot prévient chaque nœud des événements de l'application par une
## « notification », un simple numéro.
func _notification(what: int) -> void:
	# PAUSED : le joueur quitte l'application sur téléphone.
	# CLOSE_REQUEST : il ferme la fenêtre sur ordinateur.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		sauvegarder()


func sauvegarder() -> void:
	var donnees: Dictionary = etat.vers_sauvegarde()
	donnees["save_version"] = VERSION
	# Heure de la sauvegarde, en secondes depuis 1970.
	donnees["horodatage"] = Time.get_unix_time_from_system()

	# On écrit d'abord à côté, puis on remplace : si l'application est tuée
	# pendant l'écriture, l'ancienne sauvegarde reste intacte.
	var chemin_temporaire := chemin + ".tmp"
	var fichier := FileAccess.open(chemin_temporaire, FileAccess.WRITE)
	if fichier == null:
		push_warning("Sauvegarde impossible : %s" % error_string(FileAccess.get_open_error()))
		return
	fichier.store_string(JSON.stringify(donnees, "\t"))
	fichier.close()
	DirAccess.rename_absolute(chemin_temporaire, chemin)


func charger() -> void:
	if not FileAccess.file_exists(chemin):
		return  # première partie

	var json := JSON.new()
	var erreur := json.parse(FileAccess.get_file_as_string(chemin))
	if erreur != OK or not json.data is Dictionary:
		push_warning("Sauvegarde illisible : la partie repart de zéro.")
		return
	etat.depuis_sauvegarde(_migrer(json.data))


## Met une sauvegarde ancienne au format actuel, une version après l'autre.
## La version 1 est la première : il n'y a encore rien à migrer. Le jour où
## le format changera, on augmentera VERSION et l'on ajoutera ici, par
## exemple : « si save_version < 2, ajouter le champ qui manque ».
func _migrer(donnees: Dictionary) -> Dictionary:
	return donnees
