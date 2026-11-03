extends CanvasLayer
## L'affichage par-dessus le vol : les insectes gagnés, l'audace en petit
## (issue #10), l'annonce des Chœurs (issue #11), et un bouton qui bascule
## entre couloirs et vol libre, pour comparer les deux (issue #6).
##
## Un CanvasLayer se dessine par-dessus la scène et ne suit pas la caméra.

## Le vol à afficher. Le lien se fait dans main.tscn.
@export var vol: Vol

# `%Nom` : le nœud marqué « nom unique » dans la scène, où qu'il soit rangé.
@onready var _insectes: Label = %Insectes
@onready var _audace: Label = %Audace
@onready var _mode: Button = %Mode
@onready var _choeur: Label = %Choeur


func _ready() -> void:
	vol.insectes_changes.connect(_sur_insectes)
	vol.audace_changee.connect(_sur_audace)
	vol.choeur.connect(_sur_choeur)
	vol.mode_change.connect(_sur_mode)
	_mode.pressed.connect(vol.basculer_mode)
	_sur_insectes(0.0)
	_sur_audace(1.0)
	_sur_mode(ChauveSouris.Mode.COULOIRS)
	_choeur.modulate.a = 0.0


func _sur_insectes(total: float) -> void:
	_insectes.text = "Insectes  " + Texte.nombre(total, 0)


func _sur_audace(valeur: float) -> void:
	_audace.text = "Audace  ×" + Texte.nombre(valeur, 2)


func _sur_mode(mode: ChauveSouris.Mode) -> void:
	_mode.text = "Couloirs" if mode == ChauveSouris.Mode.COULOIRS else "Vol libre"


## « Chœur ! » apparaît en haut de l'écran puis s'efface.
func _sur_choeur() -> void:
	_choeur.modulate.a = 1.0
	var animation := create_tween()
	animation.tween_interval(0.7)
	animation.tween_property(_choeur, "modulate:a", 0.0, 0.6)
