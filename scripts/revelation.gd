class_name Revelation
## Ce que le joueur voit d'un objet touché par l'onde (issue #9) : il reste
## bien visible pendant la durée de révélation, puis s'efface en un fantôme
## très pâle qui ne disparaît plus.
##
## Chaque objet garde l'instant où l'onde l'a atteint et calcule lui-même son
## opacité à partir de là, comme le prévoit le GDD (« Architecture Godot 4 ») :
## pas de masque global sur l'écran.

## Temps de jeu en secondes. Le Vol l'avance à chaque image ; tous les objets
## lisent la même horloge.
static var maintenant := 0.0

## Durée pendant laquelle un objet reste bien visible, Mémoire comprise. Le
## Vol la règle au démarrage.
static var duree_s := 1.5


## Opacité, de 0 (invisible) à 1, d'un objet que l'onde a touché à `revele_a`.
## `-INF` (moins l'infini) veut dire : jamais touché, donc invisible.
static func opacite(revele_a: float) -> float:
	return opacite_a(revele_a, maintenant, duree_s)


## La même chose à un instant donné : c'est cette version que testent les
## tests, sans dépendre de l'horloge du jeu.
static func opacite_a(revele_a: float, instant: float, duree: float) -> float:
	if revele_a == -INF or instant < revele_a:
		return 0.0
	var age := instant - revele_a
	if age <= duree:
		return 1.0
	var echo: Dictionary = Balance.donnees()["echo"]
	var fantome: float = echo["opacite_fantome_pourcent"] / 100.0
	var fondu: float = echo["fondu_s"]
	if fondu <= 0.0 or age >= duree + fondu:
		return fantome
	# `lerpf(a, b, t)` va de a (t = 0) à b (t = 1) en ligne droite.
	return lerpf(1.0, fantome, (age - duree) / fondu)


## Vrai tant que l'objet est encore en train de s'effacer : il faut alors le
## redessiner à chaque image. Ensuite, son fantôme ne bouge plus.
static func en_fondu(revele_a: float) -> bool:
	if revele_a == -INF:
		return false
	var fondu: float = Balance.donnees()["echo"]["fondu_s"]
	return maintenant <= revele_a + duree_s + fondu
