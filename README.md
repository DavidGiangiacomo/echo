# L'Écho

Runner idle mobile en Godot 4 : une chauve-souris vole dans des grottes
plongées dans le noir, et le joueur choisit quand envoyer un écho pour voir.
Voir le game design document (`docs/gdd.md`).

## Où en est le projet

- **Étape 1 (jalon M0) : le simulateur d'économie**, qui valide l'audace, le
  marquage et le rythme d'écho (issues #1 à #4). Ce qu'il a appris, les
  valeurs calées et les décisions prises sont dans `docs/calage.md`.
- **Étape 2 (jalon M1) : le prototype gris** (issues #5 à #12). Des formes
  blanches sur fond noir, l'onde, la collision : de quoi tester la sensation
  de « voir par éclairs ». Pas encore de colonie, de son ni de sauvegarde.

## Arborescence

| Dossier | Contenu |
|---|---|
| `scenes/` | scènes Godot (`.tscn`) ; `segments/` : les morceaux de grotte préfabriqués |
| `scripts/` | scripts GDScript |
| `assets/` | images, sons, polices (vide pour le prototype gris) |
| `data/` | `balance.json`, valeurs d'équilibrage lues par le jeu et le simulateur ; `README.md` décrit chaque champ |
| `tests/` | tests du jeu (voir plus bas) |
| `addons/gut/` | GUT, le framework de test (code tiers, licence MIT), le même que dans le Somnambule |
| `simulateur/` | simulateur d'économie en Python (ignoré par Godot) |
| `docs/` | game design document et journal du calage (ignorés par Godot) |
| `build/` | exports Android, non versionnés |
| `.github/workflows/` | intégration continue : les tests et les scripts tournent sur GitHub à chaque pull request |

## Lancer le jeu

Ouvrir `project.godot` avec Godot 4.7, puis F5. Le jeu se joue en paysage
(issue #6) : la fenêtre de bureau s'ouvre en 1280 × 720. Il est dessiné sur un
écran de référence de 1080 × 1080 qui s'élargit selon la forme de l'écran : la
grotte garde la même taille, et plus l'écran est allongé, plus on voit loin
devant.

Contrôles (sur ordinateur, la souris joue le rôle du doigt) :

| Geste | Effet |
|---|---|
| toucher l'écran | envoyer un écho |
| glisser vers le haut ou le bas | changer de couloir (plafond, milieu, sol) |

Sur téléphone, l'écran reste en paysage, dans un sens ou dans l'autre selon
la façon dont on tient l'appareil. Paysage et couloirs ont été choisis sur
téléphone (issue #6) : en portrait, on ne voit pas assez loin devant, et les
couloirs ont été préférés au vol libre, où le doigt guidait la chauve-souris.

Pour regarder le prototype jouer tout seul, avec un écho toutes les 2,5 s :

```sh
godot --path . -- --demo
```

Ce que montre le prototype :

- l'écran est noir, sauf la chauve-souris ;
- un écho lance une onde qui révèle les parois, les obstacles et les insectes
  qu'elle touche ; ils restent visibles 1,5 s puis s'effacent en fantôme ;
- l'audace monte avec la distance, se divise par deux à chaque écho et
  retombe à ×1 en cas de collision (qui étourdit 1 s) ;
- un insecte touché par l'onde est marqué (halo doré) et vaut ×3 pendant 4 s ;
  une onde qui marque 5 insectes déclenche un Chœur (×6) ;
- le compteur d'images par seconde, en bas à gauche, n'apparaît que dans
  l'éditeur et dans l'export de développement.

## Tests du jeu

Les tests utilisent [GUT](https://gut.readthedocs.io/en/v9.7.1/) 9.7.1, copié
dans `addons/gut/`. Chaque fichier `tests/test_*.gd` hérite de `GutTest` ;
chaque fonction dont le nom commence par `test_` est un test.

Dans l'éditeur : l'onglet GUT, en bas de la fenêtre, puis « Run All ».

En ligne de commande, depuis la racine du dépôt (la première commande prépare
le projet, une fois) :

```sh
godot --headless --path . --import
godot --headless --path . -s addons/gut/gut_cmdln.gd
```

La seconde se termine avec le code 1 si un test échoue. Pour ne lancer qu'un
fichier, ajouter `-gselect=test_grotte`. Ni `tests/` ni `addons/gut/` ne sont
exportés dans l'APK.

## Exporter sur Android

Comme pour le Somnambule : il faut les modèles d'export Godot 4.7.2, le SDK
Android et un JDK, réglés dans Éditeur → Paramètres de l'éditeur → Export →
Android. Brancher le téléphone en USB (débogage USB activé) puis utiliser le
bouton de déploiement en haut à droite de l'éditeur, ou Projet → Exporter →
Android.

| Préréglage | Fichier | Compteur d'images par seconde |
|---|---|---|
| Android | `build/echo.apk` | masqué : c'est la version à faire essayer |
| Android (développement) | `build/echo-dev.apk` | affiché, pour vérifier les 60 images par seconde (issue #7) |

Les deux portent le même identifiant : installer l'un remplace l'autre.

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

## Intégration continue

À chaque pull request et à chaque push sur `main`, GitHub Actions
(`.github/workflows/tests.yml`) lance :

- les tests du simulateur avec Python 3.8 et la version la plus récente, puis
  ses trois scripts en version courte ;
- les tests GUT du jeu avec Godot 4.7.2, puis 30 s de vol avec le pilote
  automatique. La moindre erreur de script fait échouer le job.
