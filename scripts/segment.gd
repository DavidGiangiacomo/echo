class_name Segment
extends Node2D
## Un morceau de grotte préfabriqué (issue #7). Ses obstacles sont posés dans
## l'éditeur, comme enfants de ce nœud ; ses parois sont tracées au
## démarrage. La Grotte enchaîne les segments au hasard et les recycle quand
## ils sortent de l'écran.

@export var longueur_m := 40.0
## Chance relative d'être tiré au sort : 2 veut dire deux fois plus souvent.
@export var poids := 1.0

## `@onready` : la variable est remplie quand le nœud entre en jeu, une fois
## ses enfants prêts. `$Parois` désigne l'enfant nommé « Parois ».
@onready var parois: Parois = $Parois


func _ready() -> void:
	# Une graine tirée du nom du fichier : chaque sorte de segment garde
	# toujours les mêmes parois.
	parois.construire(longueur_px(), hash(scene_file_path))


func longueur_px() -> float:
	return Echelle.pixels(longueur_m)


## Abscisse de la fin du segment.
func fin_px() -> float:
	return position.x + longueur_px()


## Les obstacles du segment.
func obstacles() -> Array[Obstacle]:
	var liste: Array[Obstacle] = []
	for enfant in get_children():
		if enfant is Obstacle:
			liste.append(enfant)
	return liste


## Pose le segment à l'abscisse `x`, tout dans le noir.
func activer(x: float) -> void:
	position.x = x
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	parois.reinitialiser()
	for obstacle in obstacles():
		obstacle.reinitialiser()
		# `set_deferred` : on attend la fin de l'image pour changer la physique.
		obstacle.set_deferred("monitorable", true)


## Range le segment dans la réserve : caché, sans collision, sans calcul.
func ranger() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	for obstacle in obstacles():
		obstacle.set_deferred("monitorable", false)


## Ajoute à `liste` tout ce que l'onde partie de `centre` peut toucher dans
## ce segment, avec sa distance.
func cibles(centre: Vector2, portee: float, liste: Array) -> void:
	for obstacle in obstacles():
		var distance: float = obstacle.distance_a(centre)
		if distance <= portee:
			liste.append({"distance": distance, "objet": obstacle, "indice": -1})
	parois.cibles(centre, portee, liste)
