class_name Texte
## Mise en forme des nombres pour l'affichage, à la française.


## `x` avec `decimales` chiffres après la virgule : nombre(1.234, 2) -> "1,23".
static func nombre(x: float, decimales := 1) -> String:
	var format := "%." + str(decimales) + "f"
	return (format % x).replace(".", ",")
