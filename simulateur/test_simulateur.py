"""
Tests du simulateur (issues #1 et #4).

Ils vérifient chaque formule avec les exemples chiffrés du GDD, puis les
critères d'acceptation :
  - #1 : une saison de 30 min est simulée en moins d'une seconde ;
  - #4 : changer une valeur dans balance.json change le résultat du
    simulateur sans toucher au code.

Lancer, depuis la racine du dépôt :
    python3 -m unittest discover -s simulateur -v
ou simplement :
    python3 simulateur/test_simulateur.py

`unittest` fait partie de Python. Chaque classe `Test...` regroupe des tests ;
chaque fonction dont le nom commence par `test_` est un test. Les
`self.assert...` vérifient un résultat et font échouer le test sinon.
"""

import copy
import json
import tempfile
import time
import unittest
from pathlib import Path

import formules
import simulateur

BALANCE = simulateur.charger_balance()


class TestAudace(unittest.TestCase):
    def test_exemples_du_gdd(self):
        # GDD : ×1,7 à 50 m, ×2,1 à 100 m, ×3,2 à 400 m (arrondis à 0,1).
        # assertAlmostEqual(a, b, places=1) : a et b égaux à 0,1 près.
        self.assertEqual(formules.audace(0, BALANCE), 1)
        self.assertAlmostEqual(formules.audace(50, BALANCE), 1.7, places=1)
        self.assertAlmostEqual(formules.audace(100, BALANCE), 2.1, places=1)
        self.assertAlmostEqual(formules.audace(400, BALANCE), 3.2, places=1)

    def test_distance_pour_audace_est_l_inverse(self):
        for distance in (0, 10, 100, 1234):
            a = formules.audace(distance, BALANCE)
            self.assertAlmostEqual(formules.distance_pour_audace(a, BALANCE), distance, places=6)

    def test_un_echo_divise_par_deux_sans_descendre_sous_un(self):
        self.assertAlmostEqual(formules.audace_apres_echo(3.2, BALANCE), 1.6)
        self.assertEqual(formules.audace_apres_echo(1.5, BALANCE), 1)

    def test_variante_division_du_bonus_seul(self):
        balance = copy.deepcopy(BALANCE)  # copie complète : BALANCE reste intact
        balance["audace"]["division_bonus_seul"] = True
        self.assertAlmostEqual(formules.audace_apres_echo(3.2, balance), 2.1)
        self.assertAlmostEqual(formules.audace_apres_echo(1.5, balance), 1.25)


class TestInsectes(unittest.TestCase):
    def test_multiplicateur_de_marquage(self):
        self.assertEqual(formules.multiplicateur_marquage(False, False, BALANCE), 1)
        self.assertEqual(formules.multiplicateur_marquage(True, False, BALANCE), 3)
        self.assertEqual(formules.multiplicateur_marquage(True, True, BALANCE), 6)

    def test_valeur_d_un_insecte(self):
        # V = b · A · m
        self.assertAlmostEqual(formules.valeur_insecte(2, 1.5, 3), 9)

    def test_valeur_de_base_suit_la_colonie(self):
        balance = copy.deepcopy(BALANCE)
        grotte = balance["grottes"][0]
        balance["insectes"]["secondes_de_colonie"] = 0
        self.assertEqual(formules.valeur_de_base(grotte, 100, balance), grotte["valeur_insecte"])
        balance["insectes"]["secondes_de_colonie"] = 1.5
        self.assertAlmostEqual(formules.valeur_de_base(grotte, 100, balance), grotte["valeur_insecte"] + 150)

    def test_marquage_allonge_par_les_rhinolophes_avec_plafond(self):
        self.assertEqual(formules.duree_marquage(0, BALANCE), 4)
        self.assertAlmostEqual(formules.duree_marquage(10, BALANCE), 5)
        self.assertAlmostEqual(formules.duree_marquage(100, BALANCE), 7)  # plafond +3 s


class TestSens(unittest.TestCase):
    def test_instinct(self):
        # i(k) = min(0,85 ; 0,20 + 0,03 k)
        self.assertAlmostEqual(formules.instinct(0, BALANCE), 0.20)
        self.assertAlmostEqual(formules.instinct(10, BALANCE), 0.50)
        self.assertAlmostEqual(formules.instinct(22, BALANCE), 0.85)
        self.assertAlmostEqual(formules.instinct(100, BALANCE), 0.85)

    def test_portee_avec_oreilles_et_oreillards(self):
        base = BALANCE["echo"]["portee_m"]
        self.assertAlmostEqual(formules.portee_echo(0, 0, BALANCE), base)
        self.assertAlmostEqual(formules.portee_echo(2, 0, BALANCE), base * 1.2)
        self.assertAlmostEqual(formules.portee_echo(0, 200, BALANCE), base * 1.5)  # plafond +50 %
        self.assertAlmostEqual(formules.portee_echo(2, 30, BALANCE), base * 1.5)

    def test_revelation_allongee_par_la_memoire(self):
        self.assertAlmostEqual(formules.duree_revelation(0, BALANCE), 1.5)
        self.assertAlmostEqual(formules.duree_revelation(5, BALANCE), 2.5)


class TestColonie(unittest.TestCase):
    def test_cout_geometrique(self):
        pipistrelle = formules.fiche(BALANCE["especes"]["liste"], "pipistrelle")
        self.assertEqual(formules.cout_achat(pipistrelle, 0), pipistrelle["cout_initial"])
        attendu = pipistrelle["cout_initial"] * pipistrelle["raison_cout"] ** 3
        self.assertAlmostEqual(formules.cout_achat(pipistrelle, 3), attendu)

    def test_production_double_tous_les_25(self):
        espece = formules.fiche(BALANCE["especes"]["liste"], "pipistrelle")
        grotte = BALANCE["grottes"][0]
        p = espece["production_par_seconde"]
        self.assertAlmostEqual(formules.production_espece(espece, 24, 25, grotte), 24 * p)
        self.assertAlmostEqual(formules.production_espece(espece, 25, 25, grotte), 25 * p * 2)
        self.assertAlmostEqual(formules.production_espece(espece, 50, 25, grotte), 50 * p * 4)

    def test_daubenton_double_seulement_en_riviere(self):
        daubenton = formules.fiche(BALANCE["especes"]["liste"], "daubenton")
        p = daubenton["production_par_seconde"]
        self.assertAlmostEqual(formules.production_espece(daubenton, 1, 25, {"id": "calcaire"}), p)
        self.assertAlmostEqual(formules.production_espece(daubenton, 1, 25, {"riviere": True}), 2 * p)


class TestHibernation(unittest.TestCase):
    def test_harmoniques(self):
        # H = ⌊(I / 10^5)^0,45⌋
        self.assertEqual(formules.harmoniques(0, BALANCE), 0)
        self.assertEqual(formules.harmoniques(99_999, BALANCE), 0)
        self.assertEqual(formules.harmoniques(100_000, BALANCE), 1)
        self.assertEqual(formules.harmoniques(500_000, BALANCE), 2)
        self.assertEqual(formules.harmoniques(1_200_000, BALANCE), 3)

    def test_bonus_des_harmoniques_gardees(self):
        balance = copy.deepcopy(BALANCE)
        balance["harmoniques"]["bonus_production_pourcent"] = 2
        balance["harmoniques"]["bonus_premiere_harmonique_pourcent"] = 0
        self.assertEqual(formules.bonus_harmoniques(0, balance), 1)
        self.assertAlmostEqual(formules.bonus_harmoniques(5, balance), 1.10)
        balance["harmoniques"]["bonus_premiere_harmonique_pourcent"] = 60
        self.assertEqual(formules.bonus_harmoniques(0, balance), 1)
        self.assertAlmostEqual(formules.bonus_harmoniques(1, balance), 1.62)

    def test_gain_hors_ligne_plafonne_a_10_h(self):
        self.assertAlmostEqual(formules.gain_hors_ligne(2, 3600, BALANCE), 7200)
        self.assertAlmostEqual(formules.gain_hors_ligne(2, 20 * 3600, BALANCE), 2 * 10 * 3600)
        self.assertEqual(formules.gain_hors_ligne(2, -50, BALANCE), 0)  # horloge revenue en arrière


class TestSimulateur(unittest.TestCase):
    def test_critere_issue_1_saison_de_30_min_en_moins_d_une_seconde(self):
        for cle in simulateur.PROFILS:
            debut = time.perf_counter()
            simulateur.simuler_saison(BALANCE, simulateur.PROFILS[cle], 30 * 60, graine=1)
            self.assertLess(time.perf_counter() - debut, 1.0, f"profil {cle}")

    def test_meme_graine_meme_saison(self):
        profil = simulateur.PROFILS["moyen"]
        lignes_1, _ = simulateur.simuler_saison(BALANCE, profil, 120, graine=7)
        lignes_2, _ = simulateur.simuler_saison(BALANCE, profil, 120, graine=7)
        self.assertEqual(lignes_1, lignes_2)

    def test_meme_graine_meme_grotte_pour_tous_les_profils(self):
        positions = []
        for cle in simulateur.PROFILS:
            _, etat = simulateur.simuler_saison(BALANCE, simulateur.PROFILS[cle], 60, graine=3, achats=False)
            positions.append([objet.position for objet in etat.grotte.objets])
        self.assertEqual(positions[0], positions[1])
        self.assertEqual(positions[0], positions[2])

    def test_critere_issue_4_balance_json_change_le_resultat(self):
        profil = simulateur.PROFILS["moyen"]
        _, avant = simulateur.simuler_saison(BALANCE, profil, 300, graine=1)

        # On écrit une copie modifiée de balance.json dans un dossier
        # temporaire (effacé à la fin du bloc `with`), puis on la recharge
        # comme le ferait l'option --balance.
        modifiee = copy.deepcopy(BALANCE)
        modifiee["grottes"][0]["valeur_insecte"] *= 2
        with tempfile.TemporaryDirectory() as dossier:
            chemin = Path(dossier) / "balance.json"
            chemin.write_text(json.dumps(modifiee), encoding="utf-8")
            rechargee = simulateur.charger_balance(chemin)
        _, apres = simulateur.simuler_saison(rechargee, profil, 300, graine=1)

        self.assertNotEqual(avant.insectes_total, apres.insectes_total)

    def test_l_idle_ne_fait_jamais_d_echo(self):
        _, etat = simulateur.simuler_saison(BALANCE, simulateur.PROFILS["idle"], 300, graine=1)
        self.assertEqual(etat.stats.echos, 0)
        self.assertEqual(etat.stats.insectes_marques, 0)

    def test_l_audace_ne_descend_jamais_sous_un(self):
        lignes, _ = simulateur.simuler_saison(BALANCE, simulateur.profil_a_intervalle(0.5), 300, graine=1)
        self.assertTrue(all(ligne["audace"] >= 1 for ligne in lignes))

    def test_l_hibernation_arrete_la_saison(self):
        lignes, _ = simulateur.simuler_saison(
            BALANCE, simulateur.PROFILS["attentif"], 3600, graine=1, objectif_harmoniques=1
        )
        self.assertEqual(lignes[-1]["harmoniques"], 1)
        self.assertLess(lignes[-1]["seconde"], 3600)

    def test_csv_au_format_francais(self):
        lignes, _ = simulateur.simuler_saison(BALANCE, simulateur.PROFILS["moyen"], 30, graine=1)
        with tempfile.TemporaryDirectory() as dossier:
            chemin = Path(dossier) / "saison.csv"
            simulateur.ecrire_csv(lignes, chemin)
            texte = chemin.read_text(encoding="utf-8-sig").splitlines()
        self.assertEqual(len(texte), 32)  # les titres, puis une ligne par seconde de 0 à 30
        colonnes = texte[0].split(";")
        for attendu in ("seconde", "audace", "insectes_total", "Pipistrelle commune", "Mémoire", "harmoniques"):
            self.assertIn(attendu, colonnes)
        self.assertIn(",", texte[-1])  # virgule décimale


if __name__ == "__main__":
    unittest.main()
