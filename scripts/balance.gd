class_name Balance
## Lit data/balance.json, la source unique des valeurs d'équilibrage, que le
## simulateur lit aussi. Chaque champ est décrit dans data/README.md.
##
## Usage : Balance.donnees()["vol"]["vitesse_m_s"]
##
## `class_name` donne un nom global au script : on peut écrire
## `Balance.donnees()` partout, sans charger le fichier à la main. Les
## fonctions `static` s'appellent sur la classe elle-même, sans créer d'objet.

const CHEMIN := "res://data/balance.json"

# `static var` : une seule variable partagée par tout le jeu. On garde le
# fichier en mémoire après la première lecture.
static var _donnees: Dictionary = {}


## Renvoie le contenu de balance.json. Le fichier n'est lu qu'une fois.
## Attention : JSON ne distingue pas les entiers des décimaux, Godot lit
## donc tous les nombres comme des `float` (3 devient 3.0).
static func donnees() -> Dictionary:
	if _donnees.is_empty():
		var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(CHEMIN))
		assert(json is Dictionary, "%s est illisible ou mal formé" % CHEMIN)
		_donnees = json
	return _donnees
