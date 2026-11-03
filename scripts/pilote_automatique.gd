class_name PiloteAutomatique
extends Node
## Un joueur automatique, pour la démonstration et les essais en ligne de
## commande :
##     godot --path . -- --demo
## Il lance un écho toutes les 2,5 s (le rythme optimal trouvé par le
## simulateur) et change de couloir quand un obstacle déjà révélé approche
## dans le sien. Il ne cherche pas les insectes.

const INTERVALLE_ECHO_S := 2.5
## Il surveille son couloir sur cette distance devant lui.
const VIGILANCE_M := 10.0

var vol: Vol
var _prochain_echo := 0.3


func _process(_delta: float) -> void:
	if Revelation.maintenant >= _prochain_echo:
		vol.lancer_echo()
		_prochain_echo = Revelation.maintenant + INTERVALLE_ECHO_S
	var chauve_souris := vol.chauve_souris
	if not _menace(chauve_souris.couloir):
		return
	for decalage in [1, -1, 2, -2]:
		var couloir: int = chauve_souris.couloir + decalage
		if couloir >= 0 and couloir < Echelle.COULOIRS.size() and not _menace(couloir):
			chauve_souris.aller_au_couloir(couloir)
			return


## En fin de démonstration, un bilan dans la console : la CI le garde dans
## son journal, et l'on voit d'un coup d'œil que le vol a vraiment eu lieu.
func _exit_tree() -> void:
	print("Démonstration : %s s de vol, %d échos, %d collisions, %d Chœurs, %s insectes" % [
		Texte.nombre(Revelation.maintenant, 0),
		vol.echos,
		vol.collisions,
		vol.choeurs,
		Texte.nombre(vol.insectes, 0),
	])


## Vrai si un obstacle déjà révélé bouche ce couloir, juste devant.
func _menace(couloir: int) -> bool:
	var x := vol.chauve_souris.position.x
	for obstacle in vol.grotte.obstacles_entre(x, x + Echelle.pixels(VIGILANCE_M)):
		if obstacle.couloir() == couloir and obstacle.revele_a != -INF:
			return true
	return false
