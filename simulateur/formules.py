"""
Formules du GDD de L'Écho (docs/gdd.md, « Formules et équilibrage »).

Chaque fonction de ce fichier traduit UNE formule ou UNE règle du document de
game design. Elles sont « pures » : elles reçoivent des nombres, renvoient un
résultat et ne modifient rien d'autre. C'est ce qui les rend faciles à
vérifier une par une (voir test_simulateur.py), et à recopier plus tard en
GDScript dans Godot.

Le paramètre `balance` qu'on retrouve partout est le contenu du fichier
data/balance.json, chargé sous forme de dictionnaire Python (voir
simulateur.py). On lit une valeur avec des crochets, par exemple :
    balance["audace"]["echelle_m"]   ->   50
"""

# `math` fait partie de Python (rien à installer) : log, exp, floor...
import math


def fiche(liste, identifiant):
    """Renvoie l'élément de `liste` dont l'`id` vaut `identifiant`.

    Exemple : fiche(balance["sens"], "memoire") renvoie la fiche du sens
    Mémoire, telle qu'écrite dans balance.json.
    """
    for element in liste:
        if element["id"] == identifiant:
            return element
    raise KeyError(f"Aucun élément « {identifiant} » dans balance.json")


# ---------------------------------------------------------------------------
# L'audace
# ---------------------------------------------------------------------------


def audace(distance_m, balance):
    """Renvoie l'audace A(d) après `distance_m` mètres de vol sans écho.

    Formule du GDD :  A(d) = 1 + ln(1 + d / 50)

    `math.log` est le logarithme népérien, noté ln. L'audace monte de plus en
    plus lentement : ×1,7 à 50 m, ×2,1 à 100 m, ×3,2 à 400 m.
    """
    echelle = balance["audace"]["echelle_m"]
    return 1 + math.log(1 + distance_m / echelle)


def distance_pour_audace(a, balance):
    """Renvoie la distance qui donne l'audace `a` : c'est A(d) à l'envers.

    d = 50 · (e^(a − 1) − 1), où `math.exp(x)` calcule e^x.

    Le simulateur en a besoin après un écho : l'audace est divisée par deux,
    puis elle remonte en suivant la même courbe, comme si la chauve-souris
    n'avait parcouru que cette distance-là depuis le dernier écho.
    """
    echelle = balance["audace"]["echelle_m"]
    return echelle * (math.exp(a - 1) - 1)


def audace_apres_echo(a, balance):
    """Renvoie l'audace juste après un écho.

    Règle du GDD : un écho divise l'audace par deux. Elle ne descend jamais
    sous ×1, la valeur à laquelle une collision la remet (sinon une collision
    ferait parfois remonter l'audace). Exemples : ×3,2 -> ×1,6 ;
    ×1,5 -> ×1, et non ×0,75.

    Variante à essayer (`division_bonus_seul` à true dans balance.json) :
    l'écho ne divise que le bonus au-dessus de ×1. ×3,2 -> ×2,1 ;
    ×1,5 -> ×1,25. L'audace se construit alors d'un écho à l'autre.
    """
    reglage = balance["audace"]
    if reglage["division_bonus_seul"]:
        return 1 + (a - 1) / reglage["division_par_echo"]
    return max(1.0, a / reglage["division_par_echo"])


# ---------------------------------------------------------------------------
# Les insectes : marquage et valeur
# ---------------------------------------------------------------------------


def multiplicateur_marquage(marque, choeur, balance):
    """Renvoie m, le multiplicateur d'un insecte attrapé.

    Règle du GDD : m vaut 3 si l'insecte a été touché par l'onde dans les
    4 dernières secondes (il est marqué), 6 si cet écho a déclenché un Chœur,
    1 sinon. `marque` et `choeur` valent True ou False.
    """
    if choeur:
        return balance["marquage"]["choeur_multiplicateur"]
    if marque:
        return balance["marquage"]["multiplicateur"]
    return 1


def valeur_de_base(grotte, production_colonie, balance):
    """Renvoie b, la valeur de base d'un insecte attrapé en vol.

    GDD : « b est la valeur de base de la grotte » (`valeur_insecte` dans la
    fiche de la grotte).

    Ajout du calage (issue #3, voir data/README.md) : b grandit avec la
    colonie. Chaque insecte attrapé vaut en plus `secondes_de_colonie`
    secondes de la production de la colonie (`production_colonie`, en
    insectes par seconde) :
        b = b_grotte + k · P
    Avec k = 0, on retrouve exactement la formule du GDD.
    """
    k = balance["insectes"]["secondes_de_colonie"]
    return grotte["valeur_insecte"] + k * production_colonie


def valeur_insecte(b, a, m):
    """Renvoie la valeur d'un insecte attrapé.

    Formule du GDD :  V = b · A(d) · m
    """
    return b * a * m


def duree_marquage(nombre_rhinolophes, balance):
    """Renvoie pendant combien de secondes un insecte reste marqué.

    GDD : 4 s, plus 0,1 s par Grand rhinolophe de la colonie (plafond +3 s).
    `min(a, b)` renvoie le plus petit des deux : c'est ce qui plafonne.
    """
    rhinolophe = fiche(balance["especes"]["liste"], "rhinolophe")
    bonus = min(
        rhinolophe["marquage_plafond_s"],
        rhinolophe["marquage_s_par_individu"] * nombre_rhinolophes,
    )
    return balance["marquage"]["duree_s"] + bonus


# ---------------------------------------------------------------------------
# L'écho et les sens
# ---------------------------------------------------------------------------


def portee_echo(niveau_oreilles, nombre_oreillards, balance):
    """Renvoie la portée de l'écho, en mètres.

    GDD : +10 % par niveau d'Oreilles ; +1 % par Oreillard de la colonie,
    plafonné à +50 %. Les pourcentages s'additionnent : avec Oreilles 2 et
    30 oreillards, la portée gagne 20 + 30 = 50 %.
    """
    oreilles = fiche(balance["sens"], "oreilles")
    oreillard = fiche(balance["especes"]["liste"], "oreillard")
    pourcent = oreilles["valeur_par_niveau"] * niveau_oreilles
    pourcent += min(
        oreillard["portee_echo_plafond_pourcent"],
        oreillard["portee_echo_pourcent_par_individu"] * nombre_oreillards,
    )
    return balance["echo"]["portee_m"] * (1 + pourcent / 100)


def duree_revelation(niveau_memoire, balance):
    """Renvoie combien de secondes un objet touché par l'onde reste visible
    avant de n'être plus qu'un fantôme très pâle.

    GDD : 1,5 s, plus 0,2 s par niveau de Mémoire.
    """
    memoire = fiche(balance["sens"], "memoire")
    return balance["echo"]["revelation_s"] + memoire["valeur_par_niveau"] * niveau_memoire


def instinct(niveau, balance):
    """Renvoie i(k), la probabilité que la chauve-souris esquive seule un
    obstacle qu'elle ne voit pas, au niveau d'Instinct k (0,2 = 20 %).

    Formule du GDD :  i(k) = min(0,85 ; 0,20 + 0,03 k)

    Le plafond de 85 % garantit que le joueur attentif garde l'avantage.
    """
    sens = fiche(balance["sens"], "instinct")
    pourcent = sens["base_pourcent"] + sens["valeur_par_niveau"] * niveau
    return min(sens["plafond_pourcent"], pourcent) / 100


# ---------------------------------------------------------------------------
# La colonie
# ---------------------------------------------------------------------------


def cout_achat(fiche_achat, deja_possedes):
    """Renvoie le prix du prochain exemplaire d'une espèce, ou du prochain
    niveau d'un sens, quand on en possède déjà `deja_possedes`.

    Formule du GDD :  C_n = C0 · r^n

    Le premier coûte donc C0 (car r^0 = 1), puis chaque achat multiplie le
    prix par r. En Python, `**` est l'opérateur « puissance ».
    """
    return fiche_achat["cout_initial"] * fiche_achat["raison_cout"] ** deja_possedes


def production_espece(espece, nombre, doublement_tous_les, grotte):
    """Renvoie les insectes produits par seconde par `nombre` individus
    d'une même espèce.

    Règle du GDD : la production d'une espèce double tous les 25 individus.
    `//` est la division entière : 24 // 25 vaut 0, 60 // 25 vaut 2. Le
    bonus vaut donc 2^0 = 1 jusqu'à 24 individus, 2 de 25 à 49, 4 de 50 à 74.

    Trait du Murin de Daubenton : production ×2 dans une grotte à rivière.
    La grotte calcaire n'en a pas : le trait ne joue pas encore.
    `.get(cle)` lit une valeur facultative : None (rien) si elle est absente.
    """
    bonus = 2 ** (nombre // doublement_tous_les)
    production = espece["production_par_seconde"] * nombre * bonus
    if grotte.get("riviere") and espece.get("bonus_riviere"):
        production *= espece["bonus_riviere"]
    return production


# ---------------------------------------------------------------------------
# L'Hibernation et les gains hors-ligne
# ---------------------------------------------------------------------------


def harmoniques(insectes_saison, balance):
    """Renvoie le nombre d'harmoniques qu'une Hibernation rapporterait.

    Formule du GDD :  H = ⌊(I / 10^5)^0,45⌋

    I est le total d'insectes gagnés pendant la saison (pas ce qu'il reste en
    poche après les achats). ⌊ ⌋ veut dire « arrondi à l'entier inférieur » :
    c'est `math.floor`. Il faut 100 000 insectes pour H = 1, environ
    466 000 pour H = 2, 1,15 million pour H = 3.
    """
    h = balance["harmoniques"]
    return math.floor((max(insectes_saison, 0) / h["diviseur_insectes"]) ** h["exposant"])


def bonus_harmoniques(harmoniques_gardees, balance):
    """Renvoie le multiplicateur de production dû aux harmoniques gardées.

    Règle du GDD : chaque harmonique non dépensée donne +2 % de production
    globale. Avec 5 harmoniques : 1 + 5 × 2 / 100 = 1,10, soit +10 %.

    Exploration pour la Partition (issue #19) : dès la première harmonique,
    `bonus_premiere_harmonique_pourcent` s'ajoute une seule fois, comme le
    ferait une première note de Partition très forte. À 0, rien ne change.
    """
    h = balance["harmoniques"]
    bonus = harmoniques_gardees * h["bonus_production_pourcent"]
    if harmoniques_gardees >= 1:
        bonus += h["bonus_premiere_harmonique_pourcent"]
    return 1 + bonus / 100


def gain_hors_ligne(production_colonie, absence_s, balance):
    """Renvoie les insectes gagnés pendant que l'application est fermée.

    GDD : la production de la colonie, sans audace ni marquage, plafonnée à
    10 heures. `production_colonie` est en insectes par seconde, bonus des
    harmoniques compris.
    """
    plafond_s = balance["hors_ligne"]["plafond_h"] * 3600
    return production_colonie * min(max(absence_s, 0), plafond_s)
