class_name Audace
extends RefCounted
## L'audace de la chauve-souris (issue #10) : elle monte avec la distance
## parcourue depuis le dernier écho, de plus en plus lentement. Un écho la
## divise par deux, une collision la remet à ×1.
##
## Comme dans le simulateur, on ne garde pas l'audace elle-même mais la
## distance qui la donne : après un écho, elle remonte ainsi en suivant la
## même courbe A(d).
##
## `extends RefCounted` : un petit objet sans nœud, libéré tout seul quand
## plus personne ne s'en sert.

## Distance « équivalente » en mètres : celle qui donne l'audace actuelle.
var distance_m := 0.0


## L'audace actuelle, ×1 au départ.
func valeur() -> float:
	return Formules.audace(distance_m)


## La chauve-souris a parcouru `metres` sans écho.
func voler(metres: float) -> void:
	distance_m += metres


## Un écho divise l'audace par deux.
func echo() -> void:
	distance_m = Formules.distance_pour_audace(Formules.audace_apres_echo(valeur()))


## Une collision remet l'audace à ×1.
func collision() -> void:
	distance_m = 0.0
