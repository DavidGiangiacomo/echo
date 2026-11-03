# Simulateur d'économie

Simule une saison de L'Écho au dixième de seconde, sans graphisme, pour
vérifier que les formules du GDD (`docs/gdd.md`) donnent un rythme agréable
avant d'écrire du code Godot (issue #1). Les valeurs viennent de
`data/balance.json` (issue #4). Deux scripts répondent aux issues #2 (rythme
d'écho optimal) et #3 (rythme visé par le GDD). Ce que le simulateur a appris
et le détail du calage sont dans `docs/calage.md`.

L'organisation reprend celle du simulateur du Somnambule : mêmes noms de
fichiers, même format de CSV, mêmes conventions dans `balance.json`.

## Lancer

Il faut Python 3.8 ou plus récent, sans aucune bibliothèque à installer.
Depuis la racine du dépôt :

```sh
python3 simulateur/simulateur.py
```

Sous Windows, remplacez `python3` par `py`.

Le script affiche un résumé (rythme d'écho, audace moyenne, collisions,
premier Chœur, première Hibernation possible, colonie et sens en fin de
saison) et écrit le détail dans `simulateur/sorties/saison_<profil>.csv`. Ce
dossier n'est pas versionné. Une saison de 30 min se calcule en 0,1 s
environ.

Options :

| Option | Effet | Défaut |
|---|---|---|
| `--profil idle` | profil de joueur : `attentif`, `moyen` ou `idle` | `moyen` |
| `--duree 60` | durée de la saison en minutes | 30 |
| `--graine 7` | graine du hasard : même graine = même grotte et même saison | 42 |
| `--harmoniques 3` | harmoniques gardées des saisons précédentes | 0 |
| `--balance chemin.json` | utiliser un autre fichier de valeurs | `data/balance.json` |
| `--sortie chemin.csv` | écrire le CSV ailleurs | `simulateur/sorties/saison_<profil>.csv` |

Pour tester un réglage, modifiez `data/balance.json` (ou une copie, avec
`--balance`) puis relancez avec la même graine : seule la valeur modifiée
change le résultat.

## Lire le CSV

Le fichier s'ouvre directement dans Excel ou LibreOffice réglés en français
(séparateur `;`, virgule décimale). Une ligne par seconde :

| Colonne | Contenu |
|---|---|
| `seconde`, `minute` | temps écoulé |
| `distance_m` | distance parcourue |
| `audace` | multiplicateur d'audace à cet instant |
| `echos`, `collisions`, `choeurs` | totaux depuis le début de la saison |
| `gain_vol`, `gain_colonie` | insectes gagnés pendant cette seconde, en vol et par la colonie |
| `insectes` | insectes en poche après les achats |
| `insectes_total` | insectes gagnés depuis le début de la saison (sert à calculer H) |
| `production_colonie` | production de la colonie par seconde, bonus des harmoniques compris |
| une colonne par espèce | nombre d'individus |
| une colonne par sens | niveau |
| `harmoniques` | H qu'une Hibernation rapporterait maintenant |

Pour la courbe des insectes, tracez `insectes_total` en fonction de `minute`,
de préférence avec une échelle logarithmique.

## Trouver le rythme d'écho optimal (issue #2)

```sh
python3 simulateur/rythme_echo.py
python3 simulateur/rythme_echo.py --graines 16 --sens
```

Trois mesures, puis les trois critères de l'issue #2 :

1. **Début de partie**, sans colonie ni sens : des joueurs aussi adroits que
   le profil attentif font un écho toutes les 0,5 à 8 s ; à côté, le joueur
   attentif qui cale ses échos sur les essaims (Chœur), le joueur moyen et
   l'idle pur. Pour chacun : ce que le vol rapporte par minute, le nombre
   d'échos, l'audace moyenne, les collisions, la part d'insectes attrapés et
   marqués, les Chœurs.
2. **La même mesure avec des sens améliorés** (Oreilles 5, Mémoire 5,
   Instinct 10) : le rythme optimal doit s'allonger.
3. **Une saison complète**, achats compris : temps jusqu'à la première
   Hibernation possible, attentif contre idle pur.

Critères vérifiés : optimum entre 2 et 4 s en début de partie ; le spam
(un écho par seconde) rapporte moins que le jeu réfléchi ; rapport
attentif / idle entre 2 et 4. Comme dans le Somnambule, ce rapport se mesure
au temps qu'il faut pour atteindre la première Hibernation possible : un
rapport de 3 veut dire que l'idle pur met 3 fois plus longtemps.

L'option `--sens` ajoute une mesure plus longue (une quinzaine de secondes) :
ce que 1, 3, 5 et 10 niveaux de chaque sens ajoutent au vol de chaque profil.
Elle sert à régler les estimations `sens` des profils (voir plus bas).

Autres options : `--graines` (8), `--duree` (10 min par vol),
`--duree-saison` (180 min au plus pour la mesure 3), `--balance`.

## Vérifier le rythme visé (issue #3)

```sh
python3 simulateur/verifier_rythme.py
python3 simulateur/verifier_rythme.py --politique givre
```

Vérifie, pour le profil moyen, les cibles du tableau « Rythme visé » du GDD :

- premier Chœur en 2 à 3 min ;
- première Hibernation possible en 20 à 25 min ;
- saisons 2 à 10 de 10 à 15 min chacune.

Pour les saisons suivantes, le script enchaîne 10 saisons. Par défaut, le
joueur simulé hiberne dès que les feuilles tombent (H ≥ 1), comme le
Somnambule se réveillait dès que possible. Avec `--politique givre`, il
attend le givre : une Hibernation qui rapporte au moins deux fois plus que la
précédente. Il garde toujours toutes ses harmoniques, sans rien dépenser dans
la Partition. Chaque mesure est la moyenne de 5 séries (option `--graines`).
Les options `--duree` (60 min au plus par saison) et `--balance` fonctionnent
comme ailleurs.

Après un changement de `data/balance.json`, lancez les deux scripts : le
calage du rythme ne doit pas casser les critères de l'issue #2.

## Tests

```sh
python3 -m unittest discover -s simulateur -v
```

Les tests vérifient chaque formule avec les exemples chiffrés du GDD, et les
critères d'acceptation des issues #1 (une saison de 30 min en moins d'une
seconde) et #4 (changer une valeur de `balance.json` change le résultat sans
toucher au code). Ils durent moins d'une seconde.

## Organisation du code

- `formules.py` : les formules du GDD, une fonction par formule, sans rien
  d'autre. C'est la partie à recopier en GDScript.
- `simulateur.py` : les profils de joueur, la grotte générée par segments,
  puis la boucle de la saison en cinq étapes (écho, vol, colonie, achats,
  enregistrement), l'enchaînement des saisons, le CSV et le résumé.
- `rythme_echo.py` : réutilise `simulateur.py` pour l'étude du rythme d'écho.
- `verifier_rythme.py` : réutilise `simulateur.py` pour vérifier le rythme
  visé, saisons suivantes comprises.
- `test_simulateur.py` : les tests.
- `.gdignore` : fichier vide qui demande à Godot d'ignorer ce dossier. Sans
  lui, Godot essaierait d'importer les CSV comme des fichiers de traduction.

## Comment le vol est simulé

Ce que le GDD ne précise pas et que le simulateur a dû trancher.

- **La grotte** est une suite d'objets posés le long du trajet : obstacles,
  insectes isolés et essaims, chacun avec son propre espacement (voir
  `data/README.md`). Elle est générée par segments de 100 m. Elle a son
  propre hasard : avec la même graine, tous les profils traversent la même
  grotte.
- **Les couloirs** ne sont pas suivis un par un. Un obstacle bouche le
  couloir de la chauve-souris une fois sur trois ; un insecte qu'elle ne voit
  pas passe dans son couloir une fois sur trois.
- **L'onde** part de la chauve-souris et touche tout ce qui est devant elle,
  jusqu'à la portée. Comme dans le jeu (issue #9), chaque objet garde
  l'instant où l'onde l'a atteint : il est **visible** pendant la durée de
  révélation, puis n'est plus qu'un **fantôme** pâle. Un objet qu'aucune onde
  n'a touché est **inconnu**.
- **Un obstacle** dans le couloir est esquivé avec l'adresse du joueur s'il
  est visible ou en fantôme, avec l'Instinct s'il est inconnu ; la meilleure
  des deux chances l'emporte. Une collision remet l'audace à ×1 et étourdit
  la chauve-souris 1 s : elle continue de voler mais ne touche ni n'attrape
  rien, et ne peut pas lancer d'écho.
- **Un insecte** visible ou en fantôme est attrapé avec l'adresse du joueur,
  un insecte inconnu une fois sur trois. Marqué, il vaut ×3 ; marqué par un
  écho qui a touché au moins 5 insectes (Chœur), ×6.
- **L'audace** est suivie comme une distance équivalente. Un écho la divise
  par deux (sans descendre sous ×1), puis elle remonte en suivant la même
  courbe A(d).
- **La valeur d'un insecte** est V = b · A · m, avec b = b_grotte + k · P :
  voir `secondes_de_colonie` dans `data/README.md`.

## Profils de joueur

`PROFILS` dans `simulateur.py`. Chaque profil associe une stratégie d'écho et
une adresse :

| Profil | Stratégie d'écho | Esquive (visible / fantôme) | Capture (visible / fantôme) | Sens améliorés |
|---|---|---|---|---|
| attentif | couverture complète, calée sur les essaims pour déclencher des Chœurs | 95 % / 85 % | 90 % / 75 % | Mémoire, Oreilles |
| moyen | un écho tous les 80 % de la portée utile | 85 % / 60 % | 75 % / 50 % | Mémoire |
| idle pur | jamais d'écho | Instinct seul | 1 chance sur 3 | Instinct |

- **Couverture** : le joueur relance un écho quand il a parcouru une part de
  la portée utile depuis le précédent. La portée utile est la portée de
  l'écho, sans dépasser la distance parcourue pendant le marquage (au-delà,
  les insectes arriveraient démarqués). Le rythme s'allonge donc tout seul
  avec les Oreilles, les Oreillards et les Rhinolophes.
- **Calée sur les essaims** : le joueur entend les essaims avant de les voir
  (GDD : « les insectes bourdonnent avant d'être visibles »). Il relance un
  écho dès qu'un essaim entier est à portée, et retarde d'au plus une seconde
  un écho de couverture pour ne pas couper un essaim en deux.
- Ces adresses sont **inventées**. Les playtests (#12, #21) diront si elles
  ressemblent à de vrais joueurs.

## Achats

Tous les profils, idle pur compris, passent par la boutique. Le joueur simulé
vise l'achat, espèce ou sens, qui serait remboursé le plus vite (temps
d'économiser compris), et économise pour lui s'il est trop cher.

- Une **espèce** rapporte sa production, qui compte aussi dans la valeur des
  insectes attrapés en vol.
- Un **sens** rapporte un pourcentage de ce que gagne le vol : c'est
  l'estimation `sens` du profil (par exemple +3 % par niveau de Mémoire pour
  le joueur moyen), mesurée avec `rythme_echo.py --sens`. Un sens qui
  n'apporterait plus rien n'est pas acheté : Instinct au plafond, Mémoire
  dont la révélation couvre déjà tout le trajet jusqu'aux objets touchés.
- Le **coût** du n-ième achat est C0·r^n : le premier coûte C0.

## Hibernation

H = ⌊(I / 10^5)^0,45⌋, où I est le total des insectes gagnés pendant la
saison (pas ce qu'il reste en poche). Le joueur simulé garde toutes ses
harmoniques : la Partition n'est pas simulée. Le bonus des harmoniques
s'applique à tous les gains, vol compris.

## Pas encore simulé

La Partition et ses accords (#19), les expéditions (#22), la faim et la
frénésie (#23), les cristaux et techniques d'écho (#24), les galeries
secrètes (#25), les autres grottes (#26, #30), les prédateurs et intrus (#31),
les hivers rudes (#32), les espèces 5 et 6 et les sens Ailes et Estomac (#29).
Les gains hors-ligne ont leur formule (`formules.gain_hors_ligne`) mais la
boucle de saison ne simule pas d'absence.
