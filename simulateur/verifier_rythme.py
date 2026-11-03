"""
Vérifie le rythme visé par le GDD pour le profil moyen (issue #3).

Trois cibles, tirées du tableau « Rythme visé » du GDD :
  - premier Chœur en 2 à 3 min ;
  - première Hibernation possible en 20 à 25 min ;
  - saisons suivantes de 10 à 15 min chacune, jusqu'à la saison 10.

Chaque mesure est la moyenne de plusieurs séries de saisons, une par graine
de hasard. Après un changement de data/balance.json, lancez aussi
rythme_echo.py : le calage ne doit pas casser les critères de l'issue #2.

Utilisation, depuis la racine du dépôt :
    python3 simulateur/verifier_rythme.py
    python3 simulateur/verifier_rythme.py --graines 10
    python3 simulateur/verifier_rythme.py --politique givre
"""

import argparse
from pathlib import Path

import simulateur

# Cibles du GDD, en secondes. Chaque cible est un couple (minimum, maximum).
CIBLE_PREMIER_CHOEUR = (2 * 60, 3 * 60)
CIBLE_PREMIERE_HIBERNATION = (20 * 60, 25 * 60)
CIBLE_SAISONS_SUIVANTES = (10 * 60, 15 * 60)
NOMBRE_SAISONS = 10

# Les cibles du GDD portent sur le profil moyen.
PROFIL = simulateur.PROFILS["moyen"]


def moyenne(valeurs):
    """Moyenne d'une liste de nombres."""
    return sum(valeurs) / len(valeurs)


def afficher_mesure(titre, valeurs, cible):
    """Affiche une mesure (moyenne, plage) et dit si elle tient sa cible.

    Renvoie True si la moyenne est dans la cible.
    """
    if None in valeurs:
        print(f"{titre} : jamais atteint sur au moins une série -> NON respecté")
        return False

    texte = simulateur.en_minutes(moyenne(valeurs))
    plage = f"{simulateur.en_minutes(min(valeurs))} à {simulateur.en_minutes(max(valeurs))}"
    texte_cible = f"{cible[0] // 60} à {cible[1] // 60} min"
    respecte = cible[0] <= moyenne(valeurs) <= cible[1]
    verdict = "respecté" if respecte else "NON respecté"
    print(f"{titre} : {texte} ({plage}), cible {texte_cible} -> {verdict}")
    return respecte


def lire_arguments():
    """Lit les options de la ligne de commande (toutes facultatives)."""
    parseur = argparse.ArgumentParser(description="Vérifie le rythme visé par le GDD (issue #3).")
    parseur.add_argument("--graines", type=int, default=5, help="nombre de séries de saisons (défaut : 5)")
    parseur.add_argument(
        "--duree", type=float, default=60, help="durée maximale d'une saison en minutes (défaut : 60)"
    )
    parseur.add_argument(
        "--politique",
        choices=["des_que_possible", "givre"],
        default="des_que_possible",
        help="quand le joueur hiberne : dès que H ≥ 1, ou quand le givre apparaît (défaut : des_que_possible)",
    )
    parseur.add_argument(
        "--balance", type=Path, default=simulateur.FICHIER_BALANCE, help="fichier de valeurs à utiliser"
    )
    return parseur.parse_args()


def main():
    arguments = lire_arguments()
    balance = simulateur.charger_balance(arguments.balance)
    graines = range(1, arguments.graines + 1)
    duree_s = arguments.duree * 60

    print(f"Profil moyen, {arguments.graines} séries de saisons")
    print()

    # Première saison, simulée jusqu'à la durée maximale pour repérer le
    # premier Chœur (il peut arriver après la première Hibernation possible).
    choeurs = []
    for graine in graines:
        _, etat = simulateur.simuler_saison(balance, PROFIL, duree_s, graine)
        choeurs.append(etat.stats.premier_choeur_s)

    # Séries de saisons : chaque élément de `series` est la liste des durées
    # des saisons d'une graine, par exemple [1240, 1105, 1010, ...].
    series = []
    for graine in graines:
        series.append(
            simulateur.simuler_saisons(balance, PROFIL, NOMBRE_SAISONS, graine, duree_s, arguments.politique)
        )

    # On regroupe par numéro de saison : `par_saison[0]` contient la durée de
    # la première saison de chaque série, `par_saison[1]` celle de la
    # deuxième, etc. Une série interrompue compte comme None.
    par_saison = []
    for numero in range(NOMBRE_SAISONS):
        durees = []
        for serie in series:
            if numero < len(serie):
                durees.append(serie[numero])
            else:
                durees.append(None)
        par_saison.append(durees)

    resultats = [
        afficher_mesure("Premier Chœur               ", choeurs, CIBLE_PREMIER_CHOEUR),
        afficher_mesure("Première Hibernation possible", par_saison[0], CIBLE_PREMIERE_HIBERNATION),
    ]

    print()
    if arguments.politique == "givre":
        print("Saisons suivantes : Hibernation quand le givre apparaît, harmoniques gardées")
    else:
        print("Saisons suivantes : Hibernation dès que possible, harmoniques gardées")
    for numero, durees in enumerate(par_saison[1:], start=2):
        resultats.append(afficher_mesure(f"  saison {numero:>2}", durees, CIBLE_SAISONS_SUIVANTES))

    print()
    print(f"{sum(resultats)} cibles respectées sur {len(resultats)}")


if __name__ == "__main__":
    main()
