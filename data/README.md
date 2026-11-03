# balance.json

Source unique des valeurs d'équilibrage de L'Écho (issue #4). Le simulateur
(`simulateur/`) et, plus tard, le jeu Godot lisent ce même fichier : un réglage
validé au simulateur arrive tel quel dans le jeu.

Le format JSON n'accepte pas les commentaires, d'où cette page. Les valeurs
reprennent le GDD (`docs/gdd.md`), sauf celles que le GDD ne donne pas,
signalées ci-dessous comme **inventées**, et celles que le calage de
l'issue #3 a modifiées, signalées comme **calées**. Le détail de chaque
changement, avec les mesures avant et après, est dans `docs/calage.md`.

Après une modification, vérifiez les cibles du GDD avec
`simulateur/verifier_rythme.py` et `simulateur/rythme_echo.py`.

Conventions (les mêmes que le Somnambule) :

- les pourcentages sont écrits en points : `3` veut dire 3 % ;
- les unités sont dans le nom : secondes (`_s`), mètres (`_m`), mètres par
  seconde (`_m_s`), heures (`_h`) ;
- `id` est l'identifiant utilisé par le code (sans accent ni espace), `nom`
  est le texte affiché au joueur.

Le fichier ne contient que ce que le MVP utilise : une grotte, quatre espèces
et trois sens. Les deux autres espèces (Noctule commune, Roussette d'Égypte) et
les deux autres sens (Ailes, Estomac) arriveront avec l'issue #29.

## vol

| Champ | Sens | Simulateur |
|---|---|---|
| `vitesse_m_s` | vitesse de la chauve-souris. **Inventée** puis **calée** à 20 (premier essai : 10). À 10 m/s, l'audace montait si lentement (×1,2 au bout d'une seconde) que spammer l'écho ne coûtait presque rien | oui |
| `couloirs` | nombre de couloirs de vol (GDD : 3). Un obstacle bouche un couloir, un insecte vole dans un couloir | oui |
| `etourdissement_s` | durée de l'étourdissement après une collision (GDD : 1 s). Pendant ce temps, la chauve-souris ne peut ni attraper, ni esquiver, ni lancer d'écho | oui |

## audace

A(d) = 1 + ln(1 + d / `echelle_m`), où d est la distance parcourue depuis le
dernier écho : ×1,7 à 50 m, ×2,1 à 100 m, ×3,2 à 400 m.

| Champ | Sens | Simulateur |
|---|---|---|
| `echelle_m` | les 50 m de la formule du GDD | oui |
| `division_par_echo` | un écho divise l'audace par ce nombre (GDD : 2). Elle ne descend jamais sous ×1, la valeur où une collision la remet | oui |
| `division_bonus_seul` | variante à essayer. `false` (GDD) : ×3,2 devient ×1,6. `true` : l'écho ne divise que le bonus au-dessus de ×1, donc ×3,2 devient ×2,1 et l'audace se construit d'un écho à l'autre. Mesures dans `docs/calage.md` | oui |

## echo

| Champ | Sens | Simulateur |
|---|---|---|
| `portee_m` | rayon de l'onde. **Inventée** : 60 m, soit 3 s de vol. C'est elle qui fixe le rythme d'écho optimal en début de partie (2,5 s) | oui |
| `vitesse_onde_m_s` | vitesse à laquelle l'onde s'étend (issue #9). **Inventée** : 120 m/s, l'onde atteint le bout de sa portée en une demi-seconde | oui |
| `revelation_s` | un objet touché par l'onde reste visible pendant cette durée, puis n'est plus qu'un fantôme pâle (GDD : 1,5 s) | oui |

## marquage

| Champ | Sens | Simulateur |
|---|---|---|
| `duree_s` | un insecte touché par l'onde est marqué pendant cette durée (GDD : 4 s) | oui |
| `multiplicateur` | m d'un insecte marqué (GDD : ×3) | oui |
| `choeur_minimum_insectes` | un écho qui marque au moins ce nombre d'insectes déclenche un Chœur (GDD : 5) | oui |
| `choeur_multiplicateur` | m d'un insecte marqué par un Chœur (GDD : ×6, le double) | oui |

## insectes

| Champ | Sens | Simulateur |
|---|---|---|
| `secondes_de_colonie` | **Ajout du calage, absent du GDD.** Chaque insecte attrapé en vol vaut en plus ce nombre de secondes de production de la colonie : b = b_grotte + k · P. À `0`, on retrouve exactement la formule du GDD. **Calé** à 1,5 | oui |

Pourquoi cet ajout : avec la formule du GDD, b reste fixe alors que la colonie
grandit sans cesse. Au bout de quelques minutes, le vol ne pèse plus que 2 %
des gains, et l'idle pur atteint la première Hibernation à peine plus
lentement que le joueur attentif (rapport 1,3 ; l'issue #2 demande 2 à 4).
L'écho ne compterait plus pour la progression. Avec k = 1,5, le vol fait les
trois quarts des gains du joueur moyen pendant toute la saison, et le rapport
monte à 3,3. Détails dans `docs/calage.md`.

## grottes

Une seule grotte dans le MVP : la grotte calcaire. Les suivantes arriveront
avec les issues #26 et #30.

| Champ | Sens | Simulateur |
|---|---|---|
| `deblocage_saison` | première saison où la grotte est jouable (GDD : départ) | non |
| `valeur_insecte` | b_grotte, valeur de base d'un insecte (GDD : « valeur de base de la grotte », sans chiffre). **Inventée** : 1 | oui |
| `riviere` | facultatif : `true` pour une grotte à rivière, où le Murin de Daubenton produit ×2. Absent pour la grotte calcaire | oui |
| `obstacles` | distance entre deux obstacles, tirée au hasard entre `espacement_min_m` et `espacement_max_m`. **Inventée** : 20 à 46 m, soit un obstacle toutes les 1,7 s, et un dans le couloir de la chauve-souris toutes les 5 s en moyenne | oui |
| `insectes` | distance entre deux insectes isolés, tirée de la même façon. **Inventée** : 20 à 60 m, un insecte toutes les 2 s | oui |
| `essaims` | groupes de `taille_min` à `taille_max` insectes, répartis sur `longueur_m`, espacés de `espacement_min_m` à `espacement_max_m`. **Inventés** et **calés** : 5 à 8 insectes sur 24 m, un essaim toutes les 2 min à 2 min 40 s. Le premier donne le premier Chœur (cible : 2 à 3 min) | oui |

## especes

| Champ | Sens | Simulateur |
|---|---|---|
| `doublement_tous_les` | la production d'une espèce double tous les N individus (GDD : 25) | oui |
| `liste[].cout_initial` | C0, prix du premier individu (GDD : 15 / 100 / 1 100 / 12 000) | oui |
| `liste[].raison_cout` | r : le n-ième individu coûte C0·r^n. Le GDD dit seulement « entre 1,07 et 1,15 selon l'espèce » : 1,15 / 1,13 / 1,11 / 1,09 sont **inventées**, comme dans le Somnambule, les espèces chères grossissant le moins vite | oui |
| `liste[].production_par_seconde` | insectes par seconde d'un individu. **Calées** à environ un quart du GDD : 0,025 / 0,25 / 2 / 12 au lieu de 0,1 / 1 / 8 / 47. Avec `secondes_de_colonie`, le vol rapporte environ trois fois la production de la colonie ; sans cette division, la première Hibernation arriverait vers 6 min au lieu de 23 | oui |

Traits des espèces (champs facultatifs, valeurs du GDD) :

| Champ | Espèce | Sens | Simulateur |
|---|---|---|---|
| `bonus_riviere` | Murin de Daubenton | production ×2 dans une grotte à rivière | oui, sans effet dans la grotte calcaire |
| `portee_echo_pourcent_par_individu`, `portee_echo_plafond_pourcent` | Oreillard | portée de l'écho +1 % par individu, plafond +50 % | oui |
| `marquage_s_par_individu`, `marquage_plafond_s` | Grand rhinolophe | marquage +0,1 s par individu, plafond +3 s | oui |

## sens

Oreilles, Mémoire et Instinct (issue #15). Même logique de prix que les
espèces (`cout_initial`, `raison_cout`). `effet` dit ce que le sens modifie,
`valeur_par_niveau` de combien par niveau :

- `portee_echo_pourcent` : Oreilles, +10 % de portée par niveau ; s'ajoute au
  bonus des Oreillards ;
- `revelation_s` : Mémoire, +0,2 s de révélation par niveau ;
- `esquive_automatique_pourcent` : Instinct, +3 points d'esquive automatique
  par niveau, à partir de `base_pourcent` (20) et jusqu'à `plafond_pourcent`
  (85). C'est i(k) = min(0,85 ; 0,20 + 0,03 k).

Les effets viennent du GDD ; les prix (50 × 1,6^n, Instinct 30 × 1,5^n) sont
**inventés**. Ce que chaque niveau rapporte vraiment se mesure avec
`python3 simulateur/rythme_echo.py --sens`.

## harmoniques

| Champ | Sens | Simulateur |
|---|---|---|
| `diviseur_insectes`, `exposant` | H = ⌊(I / `diviseur_insectes`)^`exposant`⌋, où I est le total d'insectes gagnés pendant la saison (GDD : 10^5 et 0,45) | oui |
| `bonus_production_pourcent` | bonus de production globale par harmonique gardée (non dépensée). **Calé** à 14 (GDD : 2) pour que les saisons suivantes raccourcissent | oui |
| `bonus_premiere_harmonique_pourcent` | exploration pour la Partition (issue #19) : bonus ajouté une seule fois dès la première harmonique, comme le ferait une première note très forte. `0` : sans effet | oui |

Avec `bonus_production_pourcent` à 2 (GDD) et
`bonus_premiere_harmonique_pourcent` à 60, les saisons 2 à 10 tiennent toutes
leur cible de 10 à 15 min. Avec le seul bonus linéaire, c'est impossible :
voir `docs/calage.md`.

## hors_ligne

`plafond_h` : durée maximale d'absence comptée pour les gains hors-ligne
(GDD : 10 h). La formule est dans `simulateur/formules.py`
(`gain_hors_ligne`) : production de la colonie, bonus des harmoniques compris,
sans audace ni marquage. La boucle de saison ne simule pas d'absence.
