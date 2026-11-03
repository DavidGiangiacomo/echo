class_name Formules
## Les formules du vol, traduites de simulateur/formules.py : le jeu et le
## simulateur doivent donner les mêmes résultats (issue #10, vérifié par
## tests/test_formules.gd). Une fonction par formule du GDD, sans rien
## d'autre. Les formules de la colonie et de l'Hibernation arriveront avec
## les issues de l'étape 3 (MVP).


## Renvoie l'élément de `liste` dont l'`id` vaut `identifiant`, par exemple
## la fiche du sens Mémoire dans balance.json.
static func fiche(liste: Array, identifiant: String) -> Dictionary:
	for element in liste:
		if element["id"] == identifiant:
			return element
	assert(false, "Aucun élément « %s » dans balance.json" % identifiant)
	return {}


# ---------------------------------------------------------------------------
# L'audace
# ---------------------------------------------------------------------------


## Audace A(d) après `distance_m` mètres de vol sans écho.
## Formule du GDD : A(d) = 1 + ln(1 + d / 50). `log` est le logarithme
## népérien (ln) : ×1,7 à 50 m, ×2,1 à 100 m, ×3,2 à 400 m.
static func audace(distance_m: float) -> float:
	var echelle: float = Balance.donnees()["audace"]["echelle_m"]
	return 1.0 + log(1.0 + distance_m / echelle)


## La distance qui donne l'audace `a` : A(d) à l'envers.
## d = 50 · (e^(a − 1) − 1). Après un écho, l'audace est divisée par deux
## puis remonte en suivant la même courbe, depuis cette distance-là.
static func distance_pour_audace(a: float) -> float:
	var echelle: float = Balance.donnees()["audace"]["echelle_m"]
	return echelle * (exp(a - 1.0) - 1.0)


## L'audace juste après un écho : divisée par deux, sans descendre sous ×1
## (×3,2 devient ×1,6 ; ×1,5 devient ×1). Avec `division_bonus_seul`, seul
## le bonus au-dessus de ×1 est divisé (×3,2 devient ×2,1).
static func audace_apres_echo(a: float) -> float:
	var reglage: Dictionary = Balance.donnees()["audace"]
	if reglage["division_bonus_seul"]:
		return 1.0 + (a - 1.0) / reglage["division_par_echo"]
	return maxf(1.0, a / reglage["division_par_echo"])


# ---------------------------------------------------------------------------
# Les insectes
# ---------------------------------------------------------------------------


## m, le multiplicateur d'un insecte attrapé : 3 s'il est marqué, 6 s'il a
## été marqué par un Chœur, 1 sinon.
static func multiplicateur_marquage(marque: bool, choeur: bool) -> float:
	var marquage: Dictionary = Balance.donnees()["marquage"]
	if choeur:
		return marquage["choeur_multiplicateur"]
	if marque:
		return marquage["multiplicateur"]
	return 1.0


## b, la valeur de base d'un insecte : celle de la grotte, plus k secondes de
## production de la colonie (`secondes_de_colonie`, voir docs/calage.md).
static func valeur_de_base(grotte: Dictionary, production_colonie: float) -> float:
	var k: float = Balance.donnees()["insectes"]["secondes_de_colonie"]
	return grotte["valeur_insecte"] + k * production_colonie


## Valeur d'un insecte attrapé. Formule du GDD : V = b · A(d) · m
static func valeur_insecte(b: float, a: float, m: float) -> float:
	return b * a * m


## Durée du marquage : 4 s, plus 0,1 s par Grand rhinolophe (plafond +3 s).
static func duree_marquage(nombre_rhinolophes: int) -> float:
	var rhinolophe := fiche(Balance.donnees()["especes"]["liste"], "rhinolophe")
	var bonus := minf(
		rhinolophe["marquage_plafond_s"],
		rhinolophe["marquage_s_par_individu"] * nombre_rhinolophes
	)
	return Balance.donnees()["marquage"]["duree_s"] + bonus


# ---------------------------------------------------------------------------
# L'écho et les sens
# ---------------------------------------------------------------------------


## Portée de l'écho en mètres : +10 % par niveau d'Oreilles, +1 % par
## Oreillard (plafond +50 %). Les pourcentages s'additionnent.
static func portee_echo(niveau_oreilles: int, nombre_oreillards: int) -> float:
	var oreilles := fiche(Balance.donnees()["sens"], "oreilles")
	var oreillard := fiche(Balance.donnees()["especes"]["liste"], "oreillard")
	var pourcent: float = oreilles["valeur_par_niveau"] * niveau_oreilles
	pourcent += minf(
		oreillard["portee_echo_plafond_pourcent"],
		oreillard["portee_echo_pourcent_par_individu"] * nombre_oreillards
	)
	return Balance.donnees()["echo"]["portee_m"] * (1.0 + pourcent / 100.0)


## Combien de secondes un objet touché par l'onde reste bien visible, avant
## de n'être plus qu'un fantôme : 1,5 s, plus 0,2 s par niveau de Mémoire.
static func duree_revelation(niveau_memoire: int) -> float:
	var memoire := fiche(Balance.donnees()["sens"], "memoire")
	return Balance.donnees()["echo"]["revelation_s"] + memoire["valeur_par_niveau"] * niveau_memoire


## i(k), la probabilité d'esquiver seul un obstacle invisible au niveau
## d'Instinct k (0,2 = 20 %). Formule du GDD : i(k) = min(0,85 ; 0,20 + 0,03 k)
static func instinct(niveau: int) -> float:
	var sens := fiche(Balance.donnees()["sens"], "instinct")
	var pourcent: float = sens["base_pourcent"] + sens["valeur_par_niveau"] * niveau
	return minf(sens["plafond_pourcent"], pourcent) / 100.0
