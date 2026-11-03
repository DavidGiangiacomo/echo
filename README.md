# L'Écho

Runner idle mobile en Godot 4 : une chauve-souris vole dans des grottes
plongées dans le noir, et le joueur choisit quand envoyer un écho pour voir.
Voir le game design document (`docs/gdd.md`).

## Où en est le projet

Étape 1 de la feuille de route du GDD (jalon M0) : le **simulateur
d'économie**, qui valide l'audace, le marquage et le rythme d'écho avant
d'écrire le jeu (issues #1 à #4). Ce qu'il a appris, les valeurs calées et les
décisions prises sont dans `docs/calage.md`.

## Arborescence

| Dossier | Contenu |
|---|---|
| `data/` | `balance.json`, valeurs d'équilibrage lues par le simulateur et, plus tard, par le jeu ; `README.md` décrit chaque champ |
| `simulateur/` | simulateur d'économie en Python (ignoré par Godot) |
| `docs/` | game design document et journal du calage (ignorés par Godot) |
| `.github/workflows/` | intégration continue : les tests et les scripts tournent sur GitHub à chaque pull request |

Le projet Godot (scènes, scripts, ressources) arrivera avec l'étape 2, le
prototype gris (issue #5).

## Lancer le simulateur

Python 3.8 ou plus récent, sans bibliothèque à installer. Depuis la racine du
dépôt :

```sh
python3 simulateur/simulateur.py
python3 simulateur/rythme_echo.py
python3 simulateur/verifier_rythme.py
```

Le premier simule une saison et écrit un CSV, le deuxième cherche le rythme
d'écho optimal (issue #2), le troisième vérifie le rythme visé par le GDD
(issue #3). Mode d'emploi complet : `simulateur/README.md`.

Tests :

```sh
python3 -m unittest discover -s simulateur -v
```

Les mêmes tests tournent sur GitHub Actions à chaque pull request et à chaque
push sur `main`, avec Python 3.8 et la version la plus récente
(`.github/workflows/tests.yml`). Le même workflow lance aussi les trois
scripts en version courte, pour vérifier qu'ils tournent sans erreur.
