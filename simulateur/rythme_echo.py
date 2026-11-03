"""
Trouve le rythme d'écho optimal (issue #2).

Trois mesures :
  1. Début de partie. Des joueurs aussi adroits que le profil attentif
     envoient leurs échos à rythme fixe (toutes les 1, 2, 4, 8 s, et les
     rythmes intermédiaires) ; à côté, le joueur attentif qui cale ses échos
     sur les essaims (Chœur), le joueur moyen et l'idle pur. Ni colonie ni
     sens : on mesure ce que le vol seul rapporte par minute, en insectes de
     valeur de base b = 1.
  2. La même mesure avec des sens déjà améliorés, pour vérifier que le rythme
     optimal s'allonge avec les améliorations, comme le veut le GDD.
  3. Une vraie saison, achats compris : le temps qu'il faut pour atteindre la
     première Hibernation possible, joueur attentif contre idle pur.

Puis il vérifie les trois critères de l'issue #2 :
  - l'optimum (échos réguliers) se situe entre 2 et 4 s en début de partie ;
  - le spam d'écho (un par seconde) rapporte moins que le jeu réfléchi ;
  - rapport attentif / idle entre 2 et 4. Comme dans le Somnambule, on le
    mesure au temps qu'il faut pour atteindre la première Hibernation
    possible : un rapport de 3 veut dire que l'idle pur met 3 fois plus
    longtemps que l'attentif.

L'option --sens ajoute une quatrième mesure, plus longue : ce que chaque
niveau de sens ajoute au vol de chaque profil. Elle sert à régler les
estimations `sens` des profils (PROFILS dans simulateur.py).

Utilisation, depuis la racine du dépôt :
    python3 simulateur/rythme_echo.py
    python3 simulateur/rythme_echo.py --graines 16 --sens
"""

import argparse
from pathlib import Path

import simulateur
from simulateur import en_minutes, nombre

# Critères de l'issue #2.
OPTIMUM_MIN_S = 2
OPTIMUM_MAX_S = 4
INTERVALLE_SPAM_S = 1
RAPPORT_MIN = 2
RAPPORT_MAX = 4

# Rythmes réguliers essayés, en secondes. Ceux de l'issue (1, 2, 4, 8) et
# des rythmes intermédiaires pour situer l'optimum plus finement.
INTERVALLES_S = [0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 8]

# Sens déjà améliorés pour la deuxième mesure.
SENS_AMELIORES = {"oreilles": 5, "memoire": 5, "instinct": 10}


def moyenne(valeurs):
    """Moyenne d'une liste de nombres."""
    return sum(valeurs) / len(valeurs)


def mesurer_vol(balance, profil, graines, duree_s, sens_initiaux=None):
    """Fait voler un profil sans boutique, une fois par graine, et renvoie un
    dictionnaire de mesures moyennes (par minute de vol)."""
    total = {
        "gain": 0.0,
        "echos": 0,
        "collisions": 0,
        "choeurs": 0,
        "croises": 0,
        "attrapes": 0,
        "marques": 0,
        "audace": 0.0,
        "temps": 0.0,
    }
    for graine in graines:
        _, etat = simulateur.simuler_saison(
            balance, profil, duree_s, graine, achats=False, sens_initiaux=sens_initiaux
        )
        stats = etat.stats
        total["gain"] += stats.gains_vol
        total["echos"] += stats.echos
        total["collisions"] += stats.collisions
        total["choeurs"] += stats.choeurs
        total["croises"] += stats.insectes_croises
        total["attrapes"] += stats.insectes_attrapes
        total["marques"] += stats.insectes_marques
        total["audace"] += stats.somme_audace_temps
        total["temps"] += etat.t

    minutes = total["temps"] / 60
    return {
        "gain_par_minute": total["gain"] / minutes,
        "echos_par_minute": total["echos"] / minutes,
        "collisions_par_minute": total["collisions"] / minutes,
        "choeurs_par_minute": total["choeurs"] / minutes,
        "audace": total["audace"] / total["temps"],
        "attrapes": total["attrapes"] / max(1, total["croises"]),
        "marques": total["marques"] / max(1, total["attrapes"]),
    }


def comparer_rythmes(balance, graines, duree_s, sens_initiaux=None):
    """Mesure chaque rythme régulier, puis les profils. Renvoie deux listes de
    couples (nom, mesures) : les rythmes réguliers, et les profils."""
    reguliers = []
    for intervalle in INTERVALLES_S:
        profil = simulateur.profil_a_intervalle(intervalle)
        reguliers.append((intervalle, mesurer_vol(balance, profil, graines, duree_s, sens_initiaux)))
    profils = []
    for cle in ("attentif", "moyen", "idle"):
        profil = simulateur.PROFILS[cle]
        profils.append((cle, mesurer_vol(balance, profil, graines, duree_s, sens_initiaux)))
    return reguliers, profils


def afficher_tableau(reguliers, profils):
    """Affiche les mesures en colonnes alignées."""
    print(
        f"{'Rythme':<26} {'Gain/min':>9} {'Échos/min':>10} {'Audace':>7} "
        f"{'Collisions/min':>15} {'Attrapés':>9} {'Marqués':>8} {'Chœurs/min':>11}"
    )
    lignes = []
    for intervalle, mesures in reguliers:
        lignes.append((simulateur.profil_a_intervalle(intervalle)["nom"], mesures))
    noms = {"attentif": "attentif (calé sur Chœur)", "moyen": "moyen", "idle": "idle pur"}
    for cle, mesures in profils:
        lignes.append((noms[cle], mesures))
    for nom, m in lignes:
        print(
            f"{nom:<26} {nombre(m['gain_par_minute']):>9} {nombre(m['echos_par_minute']):>10} "
            f"{'×' + nombre(m['audace'], 2):>7} {nombre(m['collisions_par_minute']):>15} "
            f"{m['attrapes']:>8.0%} {m['marques']:>8.0%} {nombre(m['choeurs_par_minute'], 2):>11}".replace("%", " %")
        )


def meilleur_intervalle(reguliers):
    """Renvoie l'intervalle régulier qui rapporte le plus, et son gain."""
    intervalle, mesures = max(reguliers, key=lambda couple: couple[1]["gain_par_minute"])
    return intervalle, mesures["gain_par_minute"]


def verdict(respecte):
    """Transforme True / False en texte lisible."""
    return "respecté" if respecte else "NON respecté"


def premiere_hibernation(balance, profil, graines, duree_max_s):
    """Pour chaque graine, simule une saison jusqu'à ce que H ≥ 1 et renvoie
    la liste des secondes (None si jamais atteint en `duree_max_s`)."""
    secondes = []
    for graine in graines:
        lignes, _ = simulateur.simuler_saison(balance, profil, duree_max_s, graine, objectif_harmoniques=1)
        fin = lignes[-1]
        secondes.append(fin["seconde"] if fin["harmoniques"] >= 1 else None)
    return secondes


def decrire_durees(secondes):
    """Résume une liste de durées : "17 min 12 s (16 min 05 s à 18 min 30 s)"."""
    if None in secondes:
        return "jamais sur au moins une saison"
    return f"{en_minutes(moyenne(secondes))} ({en_minutes(min(secondes))} à {en_minutes(max(secondes))})"


def mesurer_sens(balance, graines, duree_s):
    """Pour chaque profil et chaque sens, ce qu'ajoutent 1, 3, 5 et 10 niveaux
    au gain du vol, sans colonie (en % du gain sans sens)."""
    niveaux = [1, 3, 5, 10]
    print(f"{'Profil':<10} {'Sens':<10} " + " ".join(f"{'niveau ' + str(n):>10}" for n in niveaux))
    for cle in ("attentif", "moyen", "idle"):
        profil = simulateur.PROFILS[cle]
        base = mesurer_vol(balance, profil, graines, duree_s)["gain_par_minute"]
        for sens in balance["sens"]:
            textes = []
            for niveau in niveaux:
                gain = mesurer_vol(balance, profil, graines, duree_s, {sens["id"]: niveau})["gain_par_minute"]
                textes.append(f"{100 * (gain / base - 1):+.1f} %".replace(".", ","))
            print(f"{profil['nom']:<10} {sens['nom']:<10} " + " ".join(f"{t:>10}" for t in textes))


def lire_arguments():
    """Lit les options de la ligne de commande (toutes facultatives)."""
    parseur = argparse.ArgumentParser(description="Trouve le rythme d'écho optimal (issue #2).")
    parseur.add_argument("--graines", type=int, default=8, help="nombre de vols par rythme (défaut : 8)")
    parseur.add_argument("--duree", type=float, default=10, help="durée de chaque vol en minutes (défaut : 10)")
    parseur.add_argument(
        "--duree-saison",
        type=float,
        default=180,
        help="durée maximale d'une saison pour le rapport attentif / idle, en minutes (défaut : 180)",
    )
    parseur.add_argument("--sens", action="store_true", help="mesurer aussi le gain de chaque niveau de sens")
    parseur.add_argument(
        "--balance", type=Path, default=simulateur.FICHIER_BALANCE, help="fichier de valeurs à utiliser"
    )
    return parseur.parse_args()


def main():
    arguments = lire_arguments()
    balance = simulateur.charger_balance(arguments.balance)
    graines = range(1, arguments.graines + 1)
    duree_s = arguments.duree * 60

    # 1. Début de partie.
    print(f"1. Début de partie : vol seul, {arguments.graines} vols de {nombre(arguments.duree, 0)} min par rythme")
    print("   (ni colonie ni sens ; gain en insectes de valeur de base b = 1)")
    print()
    reguliers, profils = comparer_rythmes(balance, graines, duree_s)
    afficher_tableau(reguliers, profils)
    optimum, gain_optimum = meilleur_intervalle(reguliers)
    print()
    print(f"Rythme régulier optimal : un écho toutes les {nombre(optimum)} s")

    # 2. Avec des sens améliorés.
    print()
    sens_texte = ", ".join(f"{cle} {niveau}" for cle, niveau in SENS_AMELIORES.items())
    print(f"2. Même mesure avec des sens améliorés ({sens_texte})")
    print()
    reguliers_ameliores, profils_ameliores = comparer_rythmes(balance, graines, duree_s, SENS_AMELIORES)
    afficher_tableau(reguliers_ameliores, profils_ameliores)
    optimum_ameliore, _ = meilleur_intervalle(reguliers_ameliores)
    print()
    print(f"Rythme régulier optimal : un écho toutes les {nombre(optimum_ameliore)} s")

    # 3. Une vraie saison : attentif contre idle pur.
    print()
    print(f"3. Saison complète, achats compris : première Hibernation possible ({arguments.graines} saisons)")
    duree_saison_s = arguments.duree_saison * 60
    attentif = premiere_hibernation(balance, simulateur.PROFILS["attentif"], graines, duree_saison_s)
    idle = premiere_hibernation(balance, simulateur.PROFILS["idle"], graines, duree_saison_s)
    print(f"   attentif : {decrire_durees(attentif)}")
    print(f"   idle pur : {decrire_durees(idle)}")

    # Les critères.
    print()
    print("Critères de l'issue #2 :")
    respecte = OPTIMUM_MIN_S <= optimum <= OPTIMUM_MAX_S
    print(f"  Optimum entre {OPTIMUM_MIN_S} et {OPTIMUM_MAX_S} s en début de partie : {nombre(optimum)} s -> {verdict(respecte)}")

    gain_spam = dict(reguliers)[INTERVALLE_SPAM_S]["gain_par_minute"]
    gain_reflechi = dict(profils)["attentif"]["gain_par_minute"]
    ecart = 100 * (gain_spam / gain_reflechi - 1)
    respecte = gain_spam < gain_reflechi
    print(
        f"  Le spam (un écho par seconde) rapporte moins que le jeu réfléchi : "
        f"{nombre(gain_spam)} contre {nombre(gain_reflechi)} par minute "
        f"({nombre(ecart, 0)} %) -> {verdict(respecte)}"
    )

    if None in attentif or None in idle:
        print("  Rapport attentif / idle : incalculable, une Hibernation n'est jamais arrivée.")
        print("    Allongez la saison avec --duree-saison.")
    else:
        rapport = moyenne(idle) / moyenne(attentif)
        respecte = RAPPORT_MIN <= rapport <= RAPPORT_MAX
        print(
            f"  Rapport attentif / idle entre {RAPPORT_MIN} et {RAPPORT_MAX} : "
            f"{nombre(rapport)} -> {verdict(respecte)}"
        )

    if arguments.sens:
        print()
        print(f"4. Gain du vol par niveau de sens, sans colonie ({arguments.graines} vols par mesure)")
        print()
        mesurer_sens(balance, graines, duree_s)


if __name__ == "__main__":
    main()
