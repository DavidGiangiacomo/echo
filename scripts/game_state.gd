extends Node
## État du jeu, chargé automatiquement au démarrage sous le nom GameState
## (voir Projet → Paramètres du projet → Chargement automatique). C'est le
## socle repris du Somnambule (issue #13).
##
## Il tient ce qui survit à un vol et à la fermeture de l'application : pour
## l'instant les insectes, la monnaie principale. La colonie (issue #14), les
## sens (issue #15) et l'Hibernation (issue #18) viendront s'y ajouter.
##
## Les scènes ne modifient jamais ces valeurs elles-mêmes : elles disent ce
## qui s'est passé (« un insecte vient d'être attrapé ») en appelant les
## fonctions ci-dessous, et l'affichage écoute les signaux.

## Le nombre d'insectes en poche a changé (gain, dépense ou chargement).
signal insectes_changes(insectes: float)

## Les insectes en poche, que le joueur dépensera dans la colonie.
##
## `set(valeur):` est un « setter » : Godot l'appelle à chaque affectation,
## `insectes = …` ou `insectes += …`. Le signal part ainsi à chaque
## changement, sans qu'on puisse l'oublier.
var insectes := 0.0:
	set(valeur):
		insectes = valeur
		insectes_changes.emit(insectes)

## Total des insectes gagnés pendant la saison, dépenses non déduites. C'est
## le I du GDD : il décidera des harmoniques à l'Hibernation (issue #18).
var insectes_de_la_saison := 0.0


## Ajoute des insectes gagnés : en poche et au total de la saison.
func gagner_insectes(montant: float) -> void:
	insectes += montant
	insectes_de_la_saison += montant


# --- La sauvegarde ---


## Ce qu'il faut écrire dans la sauvegarde pour retrouver la partie.
func vers_sauvegarde() -> Dictionary:
	return {
		"insectes": insectes,
		"insectes_de_la_saison": insectes_de_la_saison,
	}


## Reprend la partie décrite par une sauvegarde. Un champ absent garde sa
## valeur de départ ; un nombre impossible (négatif) est corrigé.
func depuis_sauvegarde(donnees: Dictionary) -> void:
	insectes = maxf(0.0, donnees.get("insectes", 0.0))
	# Les dépenses ne sont pas déduites du total de la saison : il ne peut pas
	# être plus petit que ce que le joueur a en poche.
	insectes_de_la_saison = maxf(insectes, donnees.get("insectes_de_la_saison", insectes))
