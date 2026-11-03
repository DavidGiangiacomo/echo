class_name Insecte
extends Area2D
## Un insecte (issue #11). Invisible tant que l'onde ne l'a pas touché. L'onde
## le marque aussi : attrapé pendant le marquage, il vaut ×3, et ×6 si cet
## écho a déclenché un Chœur. Un éclat doré signale le marquage, et un halo
## reste autour de lui tant qu'il est marqué.

const COULEUR := Color(1.0, 0.8, 0.3)  # les insectes sont dorés (GDD)
const RAYON := 10.0
const DUREE_ECLAT_S := 0.35

var revele_a := -INF
var marque_a := -INF
var marque_jusqu_a := -INF
var choeur_jusqu_a := -INF
## Numéro de son essaim, -1 pour un insecte isolé.
var essaim := -1


func _process(_delta: float) -> void:
	# Un insecte qu'aucune onde n'a touché reste noir : rien à dessiner.
	if revele_a != -INF:
		queue_redraw()


func _draw() -> void:
	var maintenant := Revelation.maintenant
	var opacite := Revelation.opacite(revele_a)
	if opacite <= 0.0:
		return
	draw_circle(Vector2.ZERO, RAYON, Color(COULEUR, opacite))

	# Le halo du marquage, plus large et plus vif pendant un Chœur.
	if maintenant <= marque_jusqu_a:
		if maintenant <= choeur_jusqu_a:
			draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, Color(COULEUR, 0.8), 4.0, true)
		else:
			draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color(COULEUR, 0.5), 2.0, true)

	# L'éclat doré au moment du marquage : un cercle qui grandit et s'efface.
	var age := maintenant - marque_a
	if age >= 0.0 and age < DUREE_ECLAT_S:
		var t := age / DUREE_ECLAT_S
		draw_arc(Vector2.ZERO, lerpf(RAYON, 60.0, t), 0.0, TAU, 32, Color(COULEUR, 1.0 - t), 3.0, true)


## L'onde l'a touché à `instant`.
func reveler(instant: float, _indice := -1) -> void:
	revele_a = instant


## L'onde le marque à `instant`, pour `duree` secondes.
func marquer(instant: float, duree: float, choeur: bool) -> void:
	marque_a = instant
	marque_jusqu_a = instant + duree
	if choeur:
		choeur_jusqu_a = marque_jusqu_a


## L'écho qui l'a marqué vient de déclencher un Chœur.
func passer_en_choeur() -> void:
	choeur_jusqu_a = marque_jusqu_a


## Son multiplicateur m s'il est attrapé à `instant` : 1, 3 ou 6.
func multiplicateur(instant: float) -> float:
	return Formules.multiplicateur_marquage(instant <= marque_jusqu_a, instant <= choeur_jusqu_a)


## Remet l'insecte dans le noir, avant qu'il ne resserve.
func reinitialiser() -> void:
	revele_a = -INF
	marque_a = -INF
	marque_jusqu_a = -INF
	choeur_jusqu_a = -INF
	essaim = -1
	queue_redraw()
