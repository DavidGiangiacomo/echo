class_name LecteurGestes
extends RefCounted
## Reconnaît les gestes du joueur (issue #8) :
## - toucher l'écran : envoyer un écho ;
## - glisser vers le haut ou le bas : changer de couloir.
##
## Un doigt qui a bougé de plus de TOLERANCE_TOUCHER ne fait jamais un
## toucher. S'il n'atteint pas SEUIL_GLISSER, le geste est simplement ignoré :
## mieux vaut un geste perdu qu'un glissement pris pour un écho, qui coûterait
## la moitié de l'audace.
##
## Les distances sont en pixels de l'écran de référence, qui fait 1080 pixels
## dans sa plus petite dimension : 30 et 100 pixels font environ 2 et 7 mm sur
## un téléphone courant. À vérifier sur plusieurs téléphones.

enum Geste { AUCUN, TOUCHER, GLISSER_HAUT, GLISSER_BAS }

## Un doigt qui bouge moins que ça entre l'appui et le relâcher fait un toucher.
const TOLERANCE_TOUCHER := 30.0
## Un doigt qui monte ou descend de plus que ça fait un glissement.
const SEUIL_GLISSER := 100.0

var _depart := Vector2.ZERO
var _appuye := false
var _a_bouge := false  # le doigt est sorti de la tolérance du toucher
var _glissement_reconnu := false  # ce doigt a déjà fait son glissement


## Le doigt se pose en `position`.
func appuyer(position: Vector2) -> void:
	_depart = position
	_appuye = true
	_a_bouge = false
	_glissement_reconnu = false


## Le doigt glisse jusqu'à `position`. Renvoie GLISSER_HAUT ou GLISSER_BAS une
## seule fois par appui, dès que le doigt a assez monté ou descendu ; AUCUN
## sinon. Un doigt qui part surtout de côté ne fait pas de glissement.
func glisser(position: Vector2) -> Geste:
	if not _appuye:
		return Geste.AUCUN
	var ecart := position - _depart
	if ecart.length() > TOLERANCE_TOUCHER:
		_a_bouge = true
	if _glissement_reconnu:
		return Geste.AUCUN
	if absf(ecart.y) >= SEUIL_GLISSER and absf(ecart.y) > absf(ecart.x):
		_glissement_reconnu = true
		# L'axe y descend : un y plus petit qu'au départ, c'est vers le haut.
		return Geste.GLISSER_HAUT if ecart.y < 0.0 else Geste.GLISSER_BAS
	return Geste.AUCUN


## Le doigt se lève en `position`. Renvoie TOUCHER si le doigt n'a presque pas
## bougé pendant tout le geste ; AUCUN sinon.
func relacher(position: Vector2) -> Geste:
	if not _appuye:
		return Geste.AUCUN
	_appuye = false
	if _glissement_reconnu or _a_bouge or position.distance_to(_depart) > TOLERANCE_TOUCHER:
		return Geste.AUCUN
	return Geste.TOUCHER


## Vrai si le doigt posé a déjà bougé : en vol libre, il guide alors la
## chauve-souris.
func doigt_en_mouvement() -> bool:
	return _appuye and _a_bouge
