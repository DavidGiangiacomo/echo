"""
Simulateur d'économie de L'Écho (issue #1).

Il fait voler la chauve-souris pendant une saison, sans aucun graphisme, pour
répondre à la question : « avec les valeurs de data/balance.json, à quel
rythme le joueur progresse-t-il ? »

La grotte est une suite d'objets posés le long du trajet : obstacles, insectes
isolés et essaims d'insectes. Elle est générée par segments de 100 m, au fur et
à mesure que la chauve-souris avance, comme le fera le jeu (issue #7).

À chaque pas de temps (un dixième de seconde), dans cet ordre :
  1. le joueur décide s'il envoie un écho, selon son profil. L'onde révèle les
     objets à portée et marque les insectes ; l'audace est divisée par deux ;
  2. la chauve-souris avance : elle croise des obstacles, qu'elle esquive ou
     non, et des insectes, qu'elle attrape ou non. L'audace monte ;
  3. la colonie produit.
Et une fois par seconde :
  4. le joueur achète des espèces et des sens ;
  5. on note l'état de la saison dans une ligne du fichier CSV.

Utilisation, depuis la racine du dépôt :
    python3 simulateur/simulateur.py
    python3 simulateur/simulateur.py --profil idle --duree 60
    python3 simulateur/simulateur.py --profil attentif --graine 7

Pour l'étude du rythme d'écho : rythme_echo.py. Pour le rythme visé par le
GDD : verifier_rythme.py.

Liste des options : python3 simulateur/simulateur.py --help
"""

# Modules fournis avec Python : rien à installer.
import argparse  # lit les options passées en ligne de commande (--duree...)
import csv  # écrit des fichiers CSV
import json  # lit des fichiers JSON
import math  # math.inf : l'infini, pour « jamais »
import random  # tire des nombres au hasard
import time  # mesure le temps de calcul
from collections import deque  # une file : on retire par le début, on ajoute à la fin
from dataclasses import dataclass, field  # décrit l'état d'une saison (voir plus bas)
from pathlib import Path  # manipule des chemins de fichiers

# Notre propre module : le fichier formules.py, rangé à côté de celui-ci.
import formules


# ---------------------------------------------------------------------------
# Réglages du simulateur
# ---------------------------------------------------------------------------

# Durée d'un pas de simulation. Le Somnambule avançait d'une seconde à la
# fois ; ici il faut plus fin, car on compare des échos espacés d'une seconde
# et la révélation ne dure que 1,5 s. Le CSV garde une ligne par seconde.
PAS_S = 0.1
PAS_PAR_SECONDE = 10

# La grotte est générée par morceaux de cette longueur (les segments du jeu).
LONGUEUR_SEGMENT_M = 100

DOSSIER_SIMULATEUR = Path(__file__).parent
FICHIER_BALANCE = DOSSIER_SIMULATEUR.parent / "data" / "balance.json"
DOSSIER_SORTIES = DOSSIER_SIMULATEUR / "sorties"

# Les profils de joueur. Chacun associe une stratégie d'écho et une adresse.
#
# Stratégies :
#   - "aucun" : ne fait jamais d'écho (idle pur, l'Instinct seul esquive) ;
#   - "intervalle" : un écho toutes les `intervalle_s` secondes, quoi qu'il
#     arrive (sert à l'étude du rythme d'écho, rythme_echo.py) ;
#   - "couverture" : un écho dès que la chauve-souris a parcouru
#     `couverture` × la portée utile depuis le dernier (0,8 = 80 %). La
#     portée utile est la portée de l'écho, sans dépasser ce que la
#     chauve-souris parcourt pendant le marquage : au-delà, les insectes
#     arriveraient démarqués. Le rythme s'allonge donc tout seul quand la
#     portée et le marquage grandissent ;
#   - "choeur" : comme "couverture", mais le joueur écoute le bourdonnement
#     des essaims et cale ses échos pour toucher un essaim entier d'un coup :
#     il attend jusqu'à `attente_essaim_max_s` qu'un essaim soit entièrement à
#     portée, et relance un écho dès qu'il l'est (au plus tôt
#     `intervalle_min_s` après le précédent).
#
# Adresse : probabilité d'esquiver un obstacle (ou d'attraper un insecte) qui
# est encore bien visible (`_vu`) ou n'est plus qu'un fantôme pâle
# (`_fantome`). Un objet que l'onde n'a jamais touché est inconnu : seul
# l'Instinct l'esquive, et on n'attrape un insecte inconnu que s'il passe
# par hasard dans le couloir de la chauve-souris (1 chance sur 3).
#
# `sens` : les sens que le joueur améliore, avec ce qu'il estime qu'un
# niveau de plus ajoute à ce que le vol rapporte (0.03 = +3 %). Il les achète
# comme les espèces, quand ils sont remboursés le plus vite (voir acheter).
# Ces estimations viennent de la mesure de rythme_echo.py (« Gain du vol par
# niveau de sens ») : à revoir quand on change balance.json. Un sens absent
# de la liste n'apporte presque rien à ce profil.
PROFILS = {
    "attentif": {
        "nom": "attentif",
        "strategie": "choeur",
        "couverture": 1.0,
        "attente_essaim_max_s": 1.0,
        "intervalle_min_s": 0.5,
        "esquive_vu": 0.95,
        "esquive_fantome": 0.85,
        "capture_vu": 0.90,
        "capture_fantome": 0.75,
        "sens": {"memoire": 0.025, "oreilles": 0.02},
    },
    "moyen": {
        "nom": "moyen",
        "strategie": "couverture",
        "couverture": 0.8,
        "esquive_vu": 0.85,
        "esquive_fantome": 0.60,
        "capture_vu": 0.75,
        "capture_fantome": 0.50,
        "sens": {"memoire": 0.03},
    },
    # Ne touche jamais l'écran pendant le vol : l'adresse ne sert pas.
    # Comme dans le Somnambule, il passe quand même par la boutique.
    "idle": {
        "nom": "idle pur",
        "strategie": "aucun",
        "esquive_vu": 0.0,
        "esquive_fantome": 0.0,
        "capture_vu": 0.0,
        "capture_fantome": 0.0,
        "sens": {"instinct": 0.035},
    },
}


def profil_a_intervalle(intervalle_s, adresse="attentif"):
    """Renvoie un profil qui fait un écho toutes les `intervalle_s` secondes,
    avec l'adresse d'un profil existant. Sert à comparer des rythmes d'écho
    à adresse égale (rythme_echo.py)."""
    # dict(...) fait une copie : modifier le nouveau profil ne touche pas
    # à celui de PROFILS.
    profil = dict(PROFILS[adresse])
    profil["nom"] = f"écho toutes les {intervalle_s:g} s".replace(".", ",")
    profil["strategie"] = "intervalle"
    profil["intervalle_s"] = intervalle_s
    return profil


# ---------------------------------------------------------------------------
# État d'une saison
# ---------------------------------------------------------------------------
# Une « dataclass » est une fiche avec des champs nommés. On en crée une au
# début de la saison, puis chaque étape lit et modifie ses champs. Ce qui
# suit les deux-points indique le type de valeur attendu : int (entier),
# float (nombre à virgule), str (texte), dict (dictionnaire), list (liste).
# `math.inf` est l'infini : un insecte « marqué jusqu'à −∞ » n'est pas marqué.


@dataclass
class Objet:
    """Un obstacle ou un insecte posé dans la grotte."""

    position: float  # distance depuis l'entrée de la grotte, en mètres
    nature: str  # "obstacle" ou "insecte"
    essaim: int = -1  # numéro de son essaim, -1 pour un insecte isolé
    revele_a: float = -math.inf  # dernier instant où l'onde l'a touché
    marque_jusqu_a: float = -math.inf  # insecte : marqué (×3) jusqu'à cet instant
    choeur_jusqu_a: float = -math.inf  # insecte : marqué par un Chœur (×6) jusqu'à cet instant


@dataclass
class Grotte:
    """La grotte devant la chauve-souris, générée segment par segment."""

    fiche: dict  # la grotte telle que décrite dans balance.json
    hasard: random.Random  # son propre hasard : même graine = même grotte
    # `field(default_factory=deque)` : chaque grotte reçoit sa propre file vide.
    objets: deque = field(default_factory=deque)  # objets pas encore atteints, du plus proche au plus loin
    essaims: dict = field(default_factory=dict)  # numéro -> {"debut", "fin", "choeur"}
    en_attente: list = field(default_factory=list)  # insectes d'essaim au-delà du dernier segment
    fin_generee: float = 0.0  # la grotte existe jusqu'à cette distance
    prochain_obstacle: float = 0.0
    prochain_insecte: float = 0.0
    prochain_essaim: float = 0.0
    nombre_essaims: int = 0


@dataclass
class Statistiques:
    """Ce qu'on compte pendant la saison, pour le résumé et les études."""

    echos: int = 0
    choeurs: int = 0
    premier_choeur_s: float = None  # None (« rien ») tant qu'aucun Chœur n'a sonné
    obstacles_croises: int = 0
    collisions: int = 0
    insectes_croises: int = 0
    insectes_attrapes: int = 0
    insectes_marques: int = 0  # attrapés pendant leur marquage (×3 ou ×6)
    somme_audace_marquage: float = 0.0  # somme des A·m des insectes attrapés
    somme_audace_temps: float = 0.0  # somme de l'audace × durée, pour l'audace moyenne
    gains_vol: float = 0.0  # insectes gagnés en vol, depuis le début de la saison


@dataclass
class EtatSaison:
    t: float  # temps écoulé depuis le début de la saison, en secondes
    position: float  # distance parcourue, en mètres
    distance_audace: float  # distance « équivalente » qui donne l'audace actuelle
    etourdi_jusqu_a: float  # la chauve-souris est étourdie jusqu'à cet instant
    dernier_echo_t: float  # instant du dernier écho
    dernier_echo_position: float  # position du dernier écho
    insectes: float  # insectes en poche, que l'on peut dépenser
    insectes_total: float  # insectes gagnés depuis le début de la saison (sert à calculer H)
    especes: dict  # nombre d'individus par espèce, ex. {"pipistrelle": 12, ...}
    sens: dict  # niveau de chaque sens, ex. {"oreilles": 2, ...}
    production_colonie: float  # insectes par seconde produits par la colonie, avant bonus
    bonus: float  # multiplicateur dû aux harmoniques gardées (1 = aucun bonus)
    grotte: Grotte
    stats: Statistiques
    gain_vol_seconde: float = 0.0  # insectes gagnés en vol pendant la seconde en cours
    gain_colonie_seconde: float = 0.0  # pareil pour la colonie


# ---------------------------------------------------------------------------
# La grotte
# ---------------------------------------------------------------------------


def tirer_espacement(hasard, reglage):
    """Distance jusqu'au prochain objet d'un type, tirée au hasard entre
    `espacement_min_m` et `espacement_max_m` (réglage de la grotte)."""
    return hasard.uniform(reglage["espacement_min_m"], reglage["espacement_max_m"])


def nouvelle_grotte(fiche, graine):
    """Crée une grotte vide ; ses premiers objets sont placés au hasard."""
    hasard = random.Random(graine)
    grotte = Grotte(fiche=fiche, hasard=hasard)
    grotte.prochain_obstacle = tirer_espacement(hasard, fiche["obstacles"])
    grotte.prochain_insecte = tirer_espacement(hasard, fiche["insectes"])
    grotte.prochain_essaim = tirer_espacement(hasard, fiche["essaims"])
    return grotte


def creer_essaim(grotte, debut):
    """Ajoute un essaim : 5 à 8 insectes répartis sur quelques mètres."""
    reglage = grotte.fiche["essaims"]
    numero = grotte.nombre_essaims
    grotte.nombre_essaims += 1
    taille = grotte.hasard.randint(reglage["taille_min"], reglage["taille_max"])
    # sorted(...) range les positions de la plus proche à la plus lointaine.
    positions = sorted(debut + grotte.hasard.uniform(0, reglage["longueur_m"]) for _ in range(taille))
    for position in positions:
        grotte.en_attente.append(Objet(position, "insecte", essaim=numero))
    grotte.essaims[numero] = {"debut": positions[0], "fin": positions[-1], "choeur": False}


def generer_segment(grotte):
    """Génère le segment de grotte suivant et ajoute ses objets à la file.

    Obstacles, insectes isolés et essaims suivent chacun leur propre
    espacement. Les insectes d'un essaim qui déborde sur le segment suivant
    attendent dans `en_attente` : la file reste ainsi rangée par position.
    """
    fin = grotte.fin_generee + LONGUEUR_SEGMENT_M
    fiche = grotte.fiche
    nouveaux = []
    while grotte.prochain_obstacle < fin:
        nouveaux.append(Objet(grotte.prochain_obstacle, "obstacle"))
        grotte.prochain_obstacle += tirer_espacement(grotte.hasard, fiche["obstacles"])
    while grotte.prochain_insecte < fin:
        nouveaux.append(Objet(grotte.prochain_insecte, "insecte"))
        grotte.prochain_insecte += tirer_espacement(grotte.hasard, fiche["insectes"])
    while grotte.prochain_essaim < fin:
        creer_essaim(grotte, grotte.prochain_essaim)
        grotte.prochain_essaim += tirer_espacement(grotte.hasard, fiche["essaims"])

    restants = []
    for objet in grotte.en_attente:
        if objet.position < fin:
            nouveaux.append(objet)
        else:
            restants.append(objet)
    grotte.en_attente = restants

    # `key=` dit sur quoi trier ; `lambda objet: objet.position` est une petite
    # fonction sans nom qui renvoie la position d'un objet.
    nouveaux.sort(key=lambda objet: objet.position)
    grotte.objets.extend(nouveaux)  # .extend ajoute toute une liste à la fin
    grotte.fin_generee = fin


def oublier_essaims_passes(grotte, position):
    """Retire les essaims que la chauve-souris a déjà dépassés."""
    # list(...) fait une copie des numéros : on ne peut pas retirer des
    # éléments d'un dictionnaire pendant qu'on le parcourt.
    for numero in list(grotte.essaims):
        if grotte.essaims[numero]["fin"] < position:
            del grotte.essaims[numero]


# ---------------------------------------------------------------------------
# Nouvelle saison
# ---------------------------------------------------------------------------


def calculer_production_colonie(especes, balance, grotte):
    """Insectes produits par seconde par toute la colonie, avant le bonus
    des harmoniques."""
    doublement = balance["especes"]["doublement_tous_les"]
    total = 0.0
    for espece in balance["especes"]["liste"]:
        total += formules.production_espece(espece, especes[espece["id"]], doublement, grotte)
    return total


def nouvelle_saison(balance, graine, harmoniques_gardees=0, sens_initiaux=None):
    """Crée l'état du tout début d'une saison : rien en poche, colonie vide.

    Seules les harmoniques gardées des saisons précédentes survivent à
    l'Hibernation : elles donnent un bonus de production pour toute la saison.
    `sens_initiaux` permet de partir avec des sens déjà améliorés (études).
    """
    fiche_grotte = balance["grottes"][0]  # le MVP n'a qu'une grotte : la grotte calcaire
    # Une compréhension de dictionnaire : {clé: valeur for ...} construit un
    # dictionnaire en une ligne. Ici, 0 pour chaque espèce et chaque sens.
    especes = {espece["id"]: 0 for espece in balance["especes"]["liste"]}
    sens = {s["id"]: 0 for s in balance["sens"]}
    if sens_initiaux:
        sens.update(sens_initiaux)  # .update remplace les valeurs données

    return EtatSaison(
        t=0.0,
        position=0.0,
        distance_audace=0.0,
        etourdi_jusqu_a=-math.inf,
        dernier_echo_t=-math.inf,
        dernier_echo_position=-math.inf,
        insectes=0.0,
        insectes_total=0.0,
        especes=especes,
        sens=sens,
        production_colonie=0.0,
        bonus=formules.bonus_harmoniques(harmoniques_gardees, balance),
        grotte=nouvelle_grotte(fiche_grotte, graine),
        stats=Statistiques(),
    )


# ---------------------------------------------------------------------------
# Étape 1 : l'écho
# ---------------------------------------------------------------------------


def portee_actuelle(etat, balance):
    """Portée de l'écho avec les Oreilles et les Oreillards actuels."""
    return formules.portee_echo(etat.sens["oreilles"], etat.especes["oreillard"], balance)


def portee_utile(etat, balance):
    """Portée de l'écho, sans dépasser la distance parcourue pendant le
    marquage : un insecte plus lointain arriverait démarqué."""
    duree = formules.duree_marquage(etat.especes["rhinolophe"], balance)
    return min(portee_actuelle(etat, balance), balance["vol"]["vitesse_m_s"] * duree)


def decision_choeur(etat, balance, profil, portee, couverture_epuisee):
    """Stratégie « choeur » : écho de couverture, calé sur les essaims.

    Le joueur entend les essaims avant de les voir. Si un essaim entier est
    à portée et n'a pas encore eu son Chœur, il envoie un écho tout de suite.
    Si un essaim est en train d'entrer dans la portée, il retarde un peu
    l'écho de couverture pour l'attraper en entier.
    """
    depuis_dernier = etat.t - etat.dernier_echo_t
    vitesse = balance["vol"]["vitesse_m_s"]
    attendre = False
    # .values() parcourt les valeurs d'un dictionnaire (ici, les essaims).
    for essaim in etat.grotte.essaims.values():
        if essaim["choeur"] or essaim["debut"] <= etat.position:
            continue  # déjà chanté, ou déjà entamé : on passe au suivant
        manque_m = essaim["fin"] - etat.position - portee  # mètres avant qu'il soit entier à portée
        if manque_m <= 0:
            if depuis_dernier >= profil["intervalle_min_s"]:
                return True  # tout l'essaim est à portée : Chœur assuré
        elif essaim["debut"] - etat.position <= portee:
            if manque_m <= vitesse * profil["attente_essaim_max_s"]:
                attendre = True  # il entre dans la portée : on l'attend
    return couverture_epuisee and not attendre


def veut_un_echo(etat, balance, profil):
    """Renvoie True si le joueur envoie un écho maintenant."""
    if etat.t < etat.etourdi_jusqu_a:
        return False  # étourdie, la chauve-souris ne peut rien faire
    strategie = profil["strategie"]
    if strategie == "aucun":
        return False
    if strategie == "intervalle":
        # Le petit 1e-9 évite qu'une erreur d'arrondi (1,9999999 au lieu de 2)
        # fasse rater un écho d'un pas de temps.
        return etat.t - etat.dernier_echo_t >= profil["intervalle_s"] - 1e-9
    parcouru = etat.position - etat.dernier_echo_position
    couverture_epuisee = parcouru >= profil["couverture"] * portee_utile(etat, balance) - 1e-9
    if strategie == "couverture":
        return couverture_epuisee
    if strategie == "choeur":
        portee = portee_actuelle(etat, balance)
        return decision_choeur(etat, balance, profil, portee, couverture_epuisee)
    raise ValueError(f"Stratégie inconnue : {strategie}")


def lancer_echo(etat, balance):
    """L'onde part de la chauve-souris et touche tout ce qui est à portée.

    Chaque objet touché garde l'instant où l'onde l'a atteint (comme dans le
    jeu, issue #9) : il est visible pendant la durée de révélation, puis
    reste comme un fantôme pâle. Chaque insecte touché est marqué ; si l'onde
    en marque au moins 5, c'est un Chœur. L'audace est divisée par deux.
    """
    portee = portee_actuelle(etat, balance)
    vitesse_onde = balance["echo"]["vitesse_onde_m_s"]
    duree_marque = formules.duree_marquage(etat.especes["rhinolophe"], balance)

    touches = []
    # La file est rangée du plus proche au plus lointain : on s'arrête au
    # premier objet hors de portée (`break` sort de la boucle).
    for objet in etat.grotte.objets:
        distance = objet.position - etat.position
        if distance > portee:
            break
        objet.revele_a = etat.t + distance / vitesse_onde  # l'onde met du temps à arriver
        if objet.nature == "insecte":
            objet.marque_jusqu_a = objet.revele_a + duree_marque
            touches.append(objet)

    if len(touches) >= balance["marquage"]["choeur_minimum_insectes"]:
        for objet in touches:
            objet.choeur_jusqu_a = objet.marque_jusqu_a
        etat.stats.choeurs += 1
        if etat.stats.premier_choeur_s is None:
            etat.stats.premier_choeur_s = etat.t
        for essaim in etat.grotte.essaims.values():
            if essaim["debut"] > etat.position and essaim["fin"] - etat.position <= portee:
                essaim["choeur"] = True

    audace = formules.audace(etat.distance_audace, balance)
    audace = formules.audace_apres_echo(audace, balance)
    etat.distance_audace = formules.distance_pour_audace(audace, balance)
    etat.dernier_echo_t = etat.t
    etat.dernier_echo_position = etat.position
    etat.stats.echos += 1


# ---------------------------------------------------------------------------
# Étape 2 : le vol
# ---------------------------------------------------------------------------


def faire_monter_audace(etat, t_debut, t_fin, balance):
    """La chauve-souris a volé de t_debut à t_fin : son audace monte avec la
    distance parcourue, sauf pendant qu'elle est étourdie."""
    temps_libre = max(0.0, t_fin - max(t_debut, etat.etourdi_jusqu_a))
    etat.distance_audace += balance["vol"]["vitesse_m_s"] * temps_libre
    audace = formules.audace(etat.distance_audace, balance)
    etat.stats.somme_audace_temps += audace * (t_fin - t_debut)


def ce_que_voit_le_joueur(objet, t, etat, balance):
    """Renvoie "visible", "fantome" ou "inconnu" pour un objet atteint à t."""
    if objet.revele_a == -math.inf:
        return "inconnu"  # aucune onde ne l'a jamais touché
    if t - objet.revele_a <= formules.duree_revelation(etat.sens["memoire"], balance):
        return "visible"
    return "fantome"


def croiser_obstacle(etat, objet, t, balance, profil, hasard):
    """La chauve-souris arrive sur un obstacle à l'instant t.

    L'obstacle bouche un des 3 couloirs. S'il est dans celui de la
    chauve-souris, il faut l'esquiver : le joueur le fait avec son adresse
    s'il le voit, l'Instinct le fait seul sinon (on garde la meilleure des
    deux chances). Une collision remet l'audace à ×1 et étourdit 1 s.
    """
    etat.stats.obstacles_croises += 1
    if hasard.random() >= 1 / balance["vol"]["couloirs"]:
        return  # il bouche un autre couloir

    vue = ce_que_voit_le_joueur(objet, t, etat, balance)
    if vue == "visible":
        adresse = profil["esquive_vu"]
    elif vue == "fantome":
        adresse = profil["esquive_fantome"]
    else:
        adresse = 0.0
    chance_esquive = max(adresse, formules.instinct(etat.sens["instinct"], balance))
    if hasard.random() < chance_esquive:
        return  # esquivé

    etat.stats.collisions += 1
    etat.distance_audace = 0.0
    etat.etourdi_jusqu_a = t + balance["vol"]["etourdissement_s"]


def croiser_insecte(etat, objet, t, balance, profil, hasard):
    """La chauve-souris arrive sur un insecte à l'instant t.

    Si le joueur le voit, il va le chercher avec son adresse ; sinon, elle ne
    l'attrape que s'il vole dans son couloir. Valeur : V = b · A · m.
    """
    etat.stats.insectes_croises += 1
    vue = ce_que_voit_le_joueur(objet, t, etat, balance)
    if vue == "visible":
        adresse = profil["capture_vu"]
    elif vue == "fantome":
        adresse = profil["capture_fantome"]
    else:
        adresse = 0.0
    chance_capture = max(adresse, 1 / balance["vol"]["couloirs"])
    if hasard.random() >= chance_capture:
        return  # raté

    audace = formules.audace(etat.distance_audace, balance)
    marque = t <= objet.marque_jusqu_a
    choeur = t <= objet.choeur_jusqu_a
    m = formules.multiplicateur_marquage(marque, choeur, balance)
    b = formules.valeur_de_base(etat.grotte.fiche, etat.production_colonie, balance)
    gain = formules.valeur_insecte(b, audace, m) * etat.bonus

    etat.insectes += gain
    etat.insectes_total += gain
    etat.gain_vol_seconde += gain
    etat.stats.gains_vol += gain
    etat.stats.insectes_attrapes += 1
    etat.stats.somme_audace_marquage += audace * m
    if marque:
        etat.stats.insectes_marques += 1


def voler(etat, balance, profil, hasard):
    """La chauve-souris avance pendant un pas de temps et traite, dans
    l'ordre, chaque objet qu'elle atteint."""
    vitesse = balance["vol"]["vitesse_m_s"]
    debut_t = etat.t
    debut_x = etat.position
    fin_t = debut_t + PAS_S
    fin_x = debut_x + vitesse * PAS_S

    # La grotte doit exister bien au-delà de ce que l'écho peut toucher.
    horizon = fin_x + 2 * portee_actuelle(etat, balance) + LONGUEUR_SEGMENT_M
    while etat.grotte.fin_generee < horizon:
        generer_segment(etat.grotte)

    objets = etat.grotte.objets
    t = debut_t
    # objets[0] est l'objet le plus proche ; .popleft() le retire de la file.
    while objets and objets[0].position <= fin_x:
        objet = objets.popleft()
        t_objet = debut_t + (objet.position - debut_x) / vitesse  # instant exact d'arrivée
        faire_monter_audace(etat, t, t_objet, balance)
        t = t_objet
        if t_objet < etat.etourdi_jusqu_a:
            continue  # étourdie : elle passe sans rien toucher ni attraper
        if objet.nature == "obstacle":
            croiser_obstacle(etat, objet, t_objet, balance, profil, hasard)
        else:
            croiser_insecte(etat, objet, t_objet, balance, profil, hasard)

    faire_monter_audace(etat, t, fin_t, balance)
    etat.position = fin_x
    etat.t = fin_t


# ---------------------------------------------------------------------------
# Étape 3 : la colonie
# ---------------------------------------------------------------------------


def produire(etat):
    """La colonie chasse pendant un pas de temps."""
    gain = etat.production_colonie * etat.bonus * PAS_S
    etat.insectes += gain
    etat.insectes_total += gain
    etat.gain_colonie_seconde += gain


# ---------------------------------------------------------------------------
# Étape 4 : les achats
# ---------------------------------------------------------------------------


def rendement_vol(etat):
    """Rendement moyen du vol depuis le début de la saison : la somme des
    A·m des insectes attrapés, par seconde. Multiplié par b, c'est ce que le
    vol rapporte par seconde."""
    if etat.t <= 0:
        return 0.0
    return etat.stats.somme_audace_marquage / etat.t


def revenu_vol_par_seconde(etat, balance, rendement):
    """Ce que le vol rapporte par seconde : b × rendement, bonus compris."""
    b = formules.valeur_de_base(etat.grotte.fiche, etat.production_colonie, balance)
    return etat.bonus * b * rendement


def revenu_par_seconde(etat, balance, rendement):
    """Ce que le joueur gagne par seconde, vol et colonie compris."""
    return etat.bonus * etat.production_colonie + revenu_vol_par_seconde(etat, balance, rendement)


def delai_rentabilisation(prix, gain_par_seconde, etat, revenu):
    """Renvoie dans combien de secondes un achat serait remboursé : le temps
    d'économiser son prix (0 si on a déjà de quoi le payer), plus le temps
    que ce qu'il rapporte en plus rembourse ce prix. Plus c'est court,
    meilleur est l'achat. `math.inf` (l'infini) : jamais remboursé."""
    if gain_par_seconde <= 0:
        return math.inf
    attente = max(0.0, prix - etat.insectes) / max(revenu, 1e-9)
    return attente + prix / gain_par_seconde


def sens_encore_utile(identifiant, etat, balance):
    """Renvoie False quand un niveau de plus de ce sens ne changerait rien.

    - Instinct : au plafond de 85 %.
    - Mémoire : quand la révélation dure déjà plus longtemps que le temps qui
      sépare le passage de l'onde de l'arrivée de la chauve-souris, au bout
      de la portée utile. Tout ce que l'écho touche est alors encore visible
      quand on l'atteint (au niveau 5 avec les valeurs actuelles).
    """
    if identifiant == "instinct":
        plafond = formules.fiche(balance["sens"], "instinct")["plafond_pourcent"] / 100
        return formules.instinct(etat.sens["instinct"], balance) < plafond
    if identifiant == "memoire":
        portee = portee_utile(etat, balance)
        temps_a_voir = portee / balance["vol"]["vitesse_m_s"] - portee / balance["echo"]["vitesse_onde_m_s"]
        return formules.duree_revelation(etat.sens["memoire"], balance) < temps_a_voir
    return True


def achats_possibles(etat, balance, profil, rendement):
    """Renvoie la liste des achats possibles, chacun sous la forme
    (délai de rentabilisation, prix, "espece" ou "sens", fiche).

    Espèce : sa production en plus compte deux fois, pour la colonie et pour
    la valeur des insectes attrapés en vol (si `secondes_de_colonie` n'est
    pas nul).
    Sens : on suppose qu'un niveau de plus augmente ce que rapporte le vol
    du pourcentage estimé dans le profil, tant qu'il est encore utile.
    """
    revenu = revenu_par_seconde(etat, balance, rendement)
    k = balance["insectes"]["secondes_de_colonie"]
    doublement = balance["especes"]["doublement_tous_les"]
    options = []

    for espece in balance["especes"]["liste"]:
        n = etat.especes[espece["id"]]
        prix = formules.cout_achat(espece, n)
        avant = formules.production_espece(espece, n, doublement, etat.grotte.fiche)
        apres = formules.production_espece(espece, n + 1, doublement, etat.grotte.fiche)
        gain = (apres - avant) * etat.bonus * (1 + k * rendement)
        options.append((delai_rentabilisation(prix, gain, etat, revenu), prix, "espece", espece))

    revenu_vol = revenu_vol_par_seconde(etat, balance, rendement)
    # .items() parcourt un dictionnaire en donnant la clé et la valeur.
    for identifiant, gain_relatif in profil["sens"].items():
        if not sens_encore_utile(identifiant, etat, balance):
            continue  # un niveau de plus ne servirait à rien
        sens = formules.fiche(balance["sens"], identifiant)
        prix = formules.cout_achat(sens, etat.sens[identifiant])
        gain = gain_relatif * revenu_vol
        options.append((delai_rentabilisation(prix, gain, etat, revenu), prix, "sens", sens))

    return options


def acheter(etat, balance, profil):
    """Le joueur achète tant que c'est intéressant.

    Il vise l'achat (espèce ou sens) qui serait remboursé le plus vite, et
    économise pour lui s'il est trop cher. Il sait ainsi attendre un
    Rhinolophe plutôt que d'acheter une énième Pipistrelle.
    """
    rendement = rendement_vol(etat)
    while True:
        options = achats_possibles(etat, balance, profil, rendement)
        # min() garde l'option au plus petit délai : `key=` dit quoi comparer,
        # ici le premier élément de chaque option.
        delai, prix, genre, fiche_achat = min(options, key=lambda option: option[0])
        if delai == math.inf or prix > etat.insectes:
            break  # rien de rentable, ou trop cher pour l'instant : on économise
        etat.insectes -= prix
        if genre == "espece":
            etat.especes[fiche_achat["id"]] += 1
            etat.production_colonie = calculer_production_colonie(etat.especes, balance, etat.grotte.fiche)
        else:
            etat.sens[fiche_achat["id"]] += 1


# ---------------------------------------------------------------------------
# La saison complète
# ---------------------------------------------------------------------------


def ligne_csv(etat, balance):
    """Résume l'état de la saison à cet instant : une ligne du futur CSV."""
    ligne = {
        "seconde": round(etat.t),
        "minute": etat.t / 60,
        "distance_m": etat.position,
        "audace": formules.audace(etat.distance_audace, balance),
        "echos": etat.stats.echos,
        "collisions": etat.stats.collisions,
        "choeurs": etat.stats.choeurs,
        "gain_vol": etat.gain_vol_seconde,
        "gain_colonie": etat.gain_colonie_seconde,
        "insectes": etat.insectes,
        "insectes_total": etat.insectes_total,
        "production_colonie": etat.production_colonie * etat.bonus,
    }
    # Une colonne par espèce et par sens : si on en ajoute un dans
    # balance.json, il apparaît tout seul dans le CSV.
    for espece in balance["especes"]["liste"]:
        ligne[espece["nom"]] = etat.especes[espece["id"]]
    for sens in balance["sens"]:
        ligne[sens["nom"]] = etat.sens[sens["id"]]
    ligne["harmoniques"] = formules.harmoniques(etat.insectes_total, balance)
    return ligne


def simuler_saison(
    balance,
    profil,
    duree_s,
    graine,
    harmoniques_gardees=0,
    objectif_harmoniques=None,
    achats=True,
    sens_initiaux=None,
):
    """Simule une saison et renvoie deux valeurs : la liste des lignes du CSV
    (une par seconde) et l'état final de la saison.

    - `harmoniques_gardees` : harmoniques des saisons précédentes (bonus) ;
    - `objectif_harmoniques` : si donné, la saison s'arrête dès qu'une
      Hibernation rapporterait au moins ce nombre d'harmoniques ;
    - `achats` : False pour un vol sans boutique (étude du rythme d'écho) ;
    - `sens_initiaux` : niveaux de sens au départ, ex. {"oreilles": 5}.
    """
    etat = nouvelle_saison(balance, graine, harmoniques_gardees, sens_initiaux)
    # Deux hasards séparés : la grotte ne dépend que de la graine, donc deux
    # profils simulés avec la même graine traversent exactement la même
    # grotte. Le second décide des esquives et des captures.
    hasard_joueur = random.Random(f"joueur {graine}")

    lignes = [ligne_csv(etat, balance)]
    nombre_pas = round(duree_s / PAS_S)
    for pas in range(1, nombre_pas + 1):
        if veut_un_echo(etat, balance, profil):  # 1. écho
            lancer_echo(etat, balance)
        voler(etat, balance, profil, hasard_joueur)  # 2. vol
        produire(etat)  # 3. colonie

        # `%` donne le reste de la division : vrai une fois toutes les 10 pas.
        if pas % PAS_PAR_SECONDE == 0:
            if achats:
                acheter(etat, balance, profil)  # 4. achats
            oublier_essaims_passes(etat.grotte, etat.position)
            lignes.append(ligne_csv(etat, balance))  # 5. on note
            etat.gain_vol_seconde = 0.0
            etat.gain_colonie_seconde = 0.0
            if objectif_harmoniques is not None and lignes[-1]["harmoniques"] >= objectif_harmoniques:
                break  # le joueur entre en Hibernation

    return lignes, etat


def objectif_hibernation(politique, harmoniques_derniere_saison):
    """Nombre d'harmoniques à partir duquel le joueur simulé hiberne.

    - "des_que_possible" : dès que les feuilles tombent (H ≥ 1) ;
    - "givre" : dès que le givre apparaît, quand le gain double depuis la
      saison précédente (H ≥ 2 × celui de la dernière saison). La première
      saison n'a pas de précédente : H ≥ 1.
    """
    if politique == "des_que_possible":
        return 1
    if politique == "givre":
        return max(1, 2 * harmoniques_derniere_saison)
    raise ValueError(f"Politique d'Hibernation inconnue : {politique}")


def simuler_saisons(balance, profil, nombre_saisons, graine, duree_max_s, politique="des_que_possible"):
    """Enchaîne plusieurs saisons et renvoie la durée de chacune, en secondes.

    Le joueur simulé hiberne selon la `politique` et garde toutes ses
    harmoniques, sans rien dépenser dans la Partition (qui n'est pas encore
    simulée) : chacune ajoute +2 % de production aux saisons suivantes.
    L'Hibernation remet tout le reste à zéro.

    Si une saison n'atteint pas son objectif en `duree_max_s`, la série
    s'arrête et la liste se termine par None.
    """
    durees = []
    harmoniques_gardees = 0
    derniere = 0
    for numero in range(nombre_saisons):
        objectif = objectif_hibernation(politique, derniere)
        # Une graine différente par saison pour ne pas rejouer la même grotte.
        # La première garde la graine d'origine.
        lignes, _ = simuler_saison(
            balance, profil, duree_max_s, graine + 1000 * numero, harmoniques_gardees, objectif
        )
        fin = lignes[-1]
        if fin["harmoniques"] < objectif:
            durees.append(None)
            break  # pas d'Hibernation : impossible d'enchaîner
        durees.append(fin["seconde"])
        harmoniques_gardees += fin["harmoniques"]
        derniere = fin["harmoniques"]
    return durees


# ---------------------------------------------------------------------------
# Sorties : fichier CSV et résumé à l'écran
# ---------------------------------------------------------------------------


def valeur_csv(valeur):
    """Écrit les nombres à virgule au format français : 3.14159 -> "3,14"."""
    if isinstance(valeur, float):
        return f"{valeur:.2f}".replace(".", ",")
    return valeur


def ecrire_csv(lignes, chemin):
    """Écrit les lignes dans un fichier CSV prêt pour un tableur en français :
    séparateur « ; », virgule décimale, et encodage « utf-8-sig » pour
    qu'Excel affiche bien les accents."""
    chemin.parent.mkdir(parents=True, exist_ok=True)  # crée le dossier s'il manque
    colonnes = list(lignes[0].keys())
    with open(chemin, "w", newline="", encoding="utf-8-sig") as fichier:
        ecrivain = csv.writer(fichier, delimiter=";")
        ecrivain.writerow(colonnes)
        for ligne in lignes:
            ecrivain.writerow([valeur_csv(ligne[colonne]) for colonne in colonnes])


def premiere_seconde(lignes, colonne, seuil):
    """Renvoie la première seconde où `colonne` atteint `seuil`, ou None si
    cela n'arrive jamais pendant la saison."""
    for ligne in lignes:
        if ligne[colonne] >= seuil:
            return ligne["seconde"]
    return None


def en_minutes(secondes):
    """Met une durée en forme : 1052 -> "17 min 32 s", None -> "jamais"."""
    if secondes is None:
        return "jamais"
    secondes = round(secondes)
    return f"{secondes // 60} min {secondes % 60:02d} s"


def grand_nombre(x):
    """Met un grand nombre en forme : 1234567.8 -> "1 234 568"."""
    return f"{x:,.0f}".replace(",", " ")


def nombre(x, decimales=1):
    """Écrit un nombre à virgule à la française : 2.345 -> "2,3"."""
    return f"{x:.{decimales}f}".replace(".", ",")


def pourcent(partie, total):
    """Écrit partie / total en pourcentage : (1, 4) -> "25 %"."""
    if total == 0:
        return "0 %"
    return f"{100 * partie / total:.0f} %"


def afficher_resume(lignes, etat, balance, profil, graine, duree_calcul_s, chemin_csv):
    """Affiche à l'écran les chiffres clés de la saison simulée."""
    fin = lignes[-1]
    stats = etat.stats
    minutes = etat.t / 60

    print(f"Saison de {en_minutes(fin['seconde'])}, profil {profil['nom']}, graine {graine}")
    print(f"Calcul : {nombre(duree_calcul_s, 3)} s")
    print()
    print("Vol :")
    if stats.echos:
        print(f"  échos : {nombre(stats.echos / minutes)} par minute, un toutes les {nombre(etat.t / stats.echos)} s")
    else:
        print("  échos : aucun")
    print(f"  audace moyenne : ×{nombre(stats.somme_audace_temps / etat.t, 2)}")
    print(f"  collisions : {nombre(stats.collisions / minutes)} par minute")
    attrapes = pourcent(stats.insectes_attrapes, stats.insectes_croises)
    marques = pourcent(stats.insectes_marques, stats.insectes_attrapes)
    print(f"  insectes attrapés : {attrapes} de ceux croisés, dont {marques} marqués")
    print(f"  Chœurs : {stats.choeurs}, le premier à {en_minutes(stats.premier_choeur_s)}")
    print()
    print(f"Première Hibernation possible (H ≥ 1) : {en_minutes(premiere_seconde(lignes, 'harmoniques', 1))}")
    part_vol = pourcent(stats.gains_vol, fin["insectes_total"])
    print(f"Insectes gagnés dans la saison : {grand_nombre(fin['insectes_total'])}, dont {part_vol} en vol")
    print(f"Harmoniques en fin de saison : {fin['harmoniques']}")
    print("Colonie en fin de saison :")
    for espece in balance["especes"]["liste"]:
        print(f"  {espece['nom']:<20} {fin[espece['nom']]}")
    # ", ".join(liste) colle les textes d'une liste en les séparant par ", ".
    print("Sens : " + ", ".join(f"{sens['nom']} {fin[sens['nom']]}" for sens in balance["sens"]))
    print()
    print(f"CSV écrit dans {chemin_csv}")


# ---------------------------------------------------------------------------
# Point d'entrée
# ---------------------------------------------------------------------------


def charger_balance(chemin=FICHIER_BALANCE):
    """Lit un fichier de valeurs comme data/balance.json."""
    with open(chemin, encoding="utf-8") as fichier:
        return json.load(fichier)


def lire_arguments():
    """Lit les options de la ligne de commande (toutes facultatives)."""
    parseur = argparse.ArgumentParser(description="Simule une saison de L'Écho et écrit un CSV.")
    parseur.add_argument("--profil", choices=list(PROFILS), default="moyen", help="profil de joueur (défaut : moyen)")
    parseur.add_argument("--duree", type=float, default=30, help="durée de la saison en minutes (défaut : 30)")
    parseur.add_argument("--graine", type=int, default=42, help="graine du hasard (défaut : 42)")
    parseur.add_argument(
        "--harmoniques", type=int, default=0, help="harmoniques gardées des saisons précédentes (défaut : 0)"
    )
    parseur.add_argument("--balance", type=Path, default=FICHIER_BALANCE, help="fichier de valeurs à utiliser")
    parseur.add_argument("--sortie", type=Path, help="fichier CSV à écrire (défaut : sorties/saison_<profil>.csv)")
    return parseur.parse_args()


def main():
    arguments = lire_arguments()
    profil = PROFILS[arguments.profil]
    balance = charger_balance(arguments.balance)

    sortie = arguments.sortie
    if sortie is None:
        sortie = DOSSIER_SORTIES / f"saison_{arguments.profil}.csv"

    # time.perf_counter() donne l'heure précise : la différence entre deux
    # appels mesure le temps de calcul (l'issue #1 demande moins d'une seconde
    # pour une saison de 30 minutes).
    debut = time.perf_counter()
    lignes, etat = simuler_saison(balance, profil, arguments.duree * 60, arguments.graine, arguments.harmoniques)
    duree_calcul_s = time.perf_counter() - debut

    ecrire_csv(lignes, sortie)
    afficher_resume(lignes, etat, balance, profil, arguments.graine, duree_calcul_s, sortie)


# Ce bloc ne s'exécute que si l'on lance ce fichier directement, pas si un
# autre fichier l'importe (rythme_echo.py, verifier_rythme.py...).
if __name__ == "__main__":
    main()
