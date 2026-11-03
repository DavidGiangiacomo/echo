# Consignes pour Claude

L'Écho est un runner idle mobile en Godot 4 (voir `docs/gdd.md`). Les tâches
sont les issues GitHub du dépôt, rangées par jalon (M0 · Simulateur
d'économie, M1 · Prototype gris…) dans l'ordre de la feuille de route du GDD.
Le dépôt reprend l'organisation du Somnambule (`DavidGiangiacomo/somnambule`),
le jeu frère.

## Branches

- Pour chaque tâche, partir de `main` à jour et créer une branche dont le nom
  dit ce qu'elle fait : en français, en minuscules, mots séparés par des
  tirets, verbe puis objet, comme `masque-compteur` dans le Somnambule.
  Exemples : `initialise-projet-godot` (issue #5), `ajoute-onde-echo`.
- C'est valable même quand la session désigne une branche au nom automatique
  (`claude/...`) : prendre le nom explicite à la place.
- Une branche par tâche ; ne jamais repartir d'une branche déjà fusionnée.

## Langue

Tout est en français : identifiants et commentaires du code, documentation,
messages de commit, pull requests, commentaires d'issues.

## Commits et pull requests

- Messages de commit au présent, à la troisième personne : « Ajoute… »,
  « Lance… », « Corrige… ».
- Une pull request se termine par `Closes #N` pour chaque issue qu'elle
  termine.

## Valeurs d'équilibrage

- `data/balance.json` est la source unique des valeurs, lue par le simulateur
  et par le jeu. Chaque champ est décrit dans `data/README.md`,
  qui signale les valeurs inventées (absentes du GDD) et calées (modifiées
  par le calage).
- Après un changement de valeurs, lancer `simulateur/rythme_echo.py` et
  `simulateur/verifier_rythme.py`, puis consigner le changement et son effet
  mesuré dans `docs/calage.md`.
- Le GDD garde ses valeurs d'origine : les écarts se notent dans
  `data/README.md`, pas dans `docs/gdd.md`.

## Simulateur et tests

- Python 3.8 ou plus récent, sans bibliothèque à installer : pas de syntaxe
  plus récente que Python 3.8.
- Tests : `python3 -m unittest discover -s simulateur -v`. La CI
  (`.github/workflows/tests.yml`) les lance avec Python 3.8 et la version la
  plus récente, puis lance les trois scripts du simulateur en version courte.
- Le code est commenté pas à pas, comme dans le Somnambule : les commentaires
  expliquent aussi la syntaxe à qui la découvre.

## Jeu Godot

- Godot 4.7 (4.7.2 dans la CI), GDScript typé, rendu Mobile. Les formules
  du vol (`scripts/formules.gd`) sont traduites de `simulateur/formules.py` :
  toute formule changée l'est des deux côtés, avec ses tests.
- Tests GUT en ligne de commande : `godot --headless --path . --import`, puis
  `godot --headless --path . -s addons/gut/gut_cmdln.gd`. Godot ne s'arrête
  pas sur une erreur de script : la chercher dans ce qu'il affiche.
- `godot --path . -- --demo` fait jouer le pilote automatique.
- Versionner les fichiers `.uid` que Godot crée à côté des scripts.
- Les autoloads `GameState` et `Sauvegarde` viennent du Somnambule. Un test
  ne touche jamais la vraie partie : il crée un `GameState` neuf
  (`preload("res://scripts/game_state.gd").new()`) et le donne au nœud
  testé par sa variable `etat`.
- `trait` est un mot réservé de GDScript dans Godot 4.7 : ne pas l'utiliser
  comme nom de variable.
