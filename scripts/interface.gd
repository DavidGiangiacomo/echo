extends CanvasLayer
## L'affichage par-dessus le vol : les insectes de la partie, l'audace en
## petit (issue #10) et l'annonce des Chœurs (issue #11).
##
## Un CanvasLayer se dessine par-dessus la scène et ne suit pas la caméra.

## Le vol à afficher. Le lien se fait dans main.tscn.
@export var vol: Vol

# `%Nom` : le nœud marqué « nom unique » dans la scène, où qu'il soit rangé.
@onready var _insectes: Label = %Insectes
@onready var _audace: Label = %Audace
@onready var _choeur: Label = %Choeur


func _ready() -> void:
	# Les insectes sont ceux de la partie, sauvegardés d'une session à
	# l'autre : on les lit dans GameState, pas dans le vol.
	GameState.insectes_changes.connect(_sur_insectes)
	vol.audace_changee.connect(_sur_audace)
	vol.choeur.connect(_sur_choeur)
	_sur_insectes(GameState.insectes)
	_sur_audace(1.0)
	_choeur.modulate.a = 0.0


## Le total s'écrit en format court : « 1,2 k », « 3,4 M »…
func _sur_insectes(total: float) -> void:
	_insectes.text = "Insectes  " + Nombres.court(total)


func _sur_audace(valeur: float) -> void:
	_audace.text = "Audace  ×" + Texte.nombre(valeur, 2)


## « Chœur ! » apparaît en haut de l'écran puis s'efface.
func _sur_choeur() -> void:
	_choeur.modulate.a = 1.0
	var animation := create_tween()
	animation.tween_interval(0.7)
	animation.tween_property(_choeur, "modulate:a", 0.0, 0.6)
