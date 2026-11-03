# Calage de l'économie

Ce que le simulateur d'économie (étape 1 de la feuille de route, jalon M0) a
appris sur le GDD, et le journal de chaque valeur changée (issue #3).

Les chiffres viennent de `data/balance.json` dans l'état de ce dépôt, mesurés
avec les commandes de `simulateur/README.md` et leurs réglages par défaut
(graines 1 à 5 ou 1 à 8). Une autre graine donne des chiffres un peu
différents, pas des conclusions différentes.

## En bref

| Issue | Critère | Mesure | Verdict |
|---|---|---|---|
| #1 | une saison de 30 min simulée en moins d'une seconde | 0,06 à 0,11 s | respecté |
| #2 | rythme d'écho optimal entre 2 et 4 s en début de partie | 2,5 s (4 s avec Oreilles 5, Mémoire 5, Instinct 10) | respecté |
| #2 | le spam d'écho rapporte moins que le jeu réfléchi | 111,9 contre 124,0 insectes par minute (−10 %) | respecté |
| #2 | rapport attentif / idle entre 2 et 4 | 3,3 (19 min contre 62 min jusqu'à la première Hibernation) | respecté |
| #3 | premier Chœur en 2 à 3 min | 2 min 18 s | respecté |
| #3 | première Hibernation possible en 20 à 25 min | 22 min 55 s | respecté |
| #3 | saisons 2 à 10 de 10 à 15 min | saisons 5 à 10 : de 14 min 51 s à 10 min 10 s ; saisons 2 à 4 : 20 min 17 s, 17 min 57 s, 16 min 34 s | 6 sur 9 |
| #4 | changer une valeur de `balance.json` change le résultat sans toucher au code | test automatique | respecté |

Pour en arriver là, le calage a dû **ajouter une règle au GDD** :
la valeur des insectes attrapés suit la colonie (`secondes_de_colonie`). Sans
elle, le vol ne compte presque pas pour la progression (point 1). Il a aussi
**changé deux valeurs du GDD** : les productions des espèces, divisées par
quatre environ, et le bonus par harmonique, passé de 2 à 14 %. Ces choix ont
été validés le 3 novembre 2026 (voir « Décisions »). Chaque changement peut
être annulé dans `balance.json`.

Les saisons 2 à 4 restent trop longues : avec un bonus qui grandit d'autant à
chaque harmonique, aucune valeur ne peut tenir toutes les cibles (point 6).
Une Partition dont la première note accélère fortement le jeu les tiendrait
toutes.

## Ce que le simulateur a appris

### 1. Avec le GDD tel quel, le vol ne compte presque pas

| Mesure | GDD tel quel | Calage retenu |
|---|---|---|
| première Hibernation, joueur moyen | 21,0 min | 22,9 min |
| première Hibernation, joueur attentif | 20,2 min | 19,0 min |
| première Hibernation, idle pur | 26,6 min | 61,8 min |
| rapport idle / attentif (cible : 2 à 4) | **1,3** | 3,3 |
| part du vol dans les gains, joueur moyen | **2 %** | 74 % |
| part du vol dans les gains, idle pur | 0 % | 36 % |

Dans le GDD, un insecte vaut V = b · A · m, où b est la valeur de base de la
grotte, fixe. Le vol rapporte donc à peu près la même chose de la première à
la dernière minute, alors que la colonie grandit sans cesse : chaque achat
d'espèce est remboursé en 2 à 4 minutes. Au bout de quelques minutes, la
colonie fait tout. Écho, audace et marquage ne changent alors presque plus la
progression : l'idle pur atteint la première Hibernation à peine plus tard
que le joueur attentif. Le pilier « Voir est un choix » ne pèse plus rien.

**Ajout retenu** (`insectes.secondes_de_colonie`, validé) : chaque insecte attrapé
vaut en plus k secondes de production de la colonie,
b = b_grotte + k · P. C'est le principe d'Idle Slayer ou des cookies dorés de
Cookie Clicker : les récompenses actives se comptent en secondes de
production passive, et gardent ainsi leur poids toute la partie. Avec
k = 1,5, le joueur moyen tire les trois quarts de ses gains du vol, et le
rapport idle / attentif monte à 3,3. Comme le vol devient trois fois plus
rentable, les productions des espèces sont divisées par quatre environ pour
garder la première Hibernation vers 23 minutes.

Autre piste écartée : faire multiplier tous les gains par l'audace, comme le
multiplicateur de profondeur du Somnambule. Chaque écho divise l'audace :
celui qui fait des échos garde une audace moyenne plus basse (×1,44 au rythme
optimal) que l'idle pur, qui ne la perd qu'aux collisions (×1,80). Cette
règle récompenserait le fait de ne jamais regarder.

Pour revenir au GDD : `secondes_de_colonie` à 0 et productions à
0,1 / 1 / 8 / 47.

### 2. Le rythme d'écho optimal est fixé par la portée et la vitesse

Début de partie, vol seul (`rythme_echo.py`, sans colonie ni sens, en
insectes de valeur b = 1 par minute) :

| Rythme | Gain par minute | Audace moyenne | Collisions par minute |
|---|---|---|---|
| un écho toutes les 0,5 s | 104,0 | ×1,11 | 0,6 |
| toutes les 1 s | 111,9 | ×1,19 | 0,6 |
| toutes les 2 s | 121,3 | ×1,33 | 0,8 |
| toutes les 2,5 s | **122,7** | ×1,39 | 1,0 |
| toutes les 3 s | 122,5 | ×1,44 | 1,2 |
| toutes les 4 s | 93,7 | ×1,52 | 3,3 |
| toutes les 8 s | 58,5 | ×1,68 | 6,5 |
| attentif, calé sur les essaims | **124,0** | ×1,44 | 1,2 |
| moyen | 94,3 | ×1,36 | 2,5 |
| idle pur | 18,4 | ×1,80 | 9,8 |

Le gain monte doucement tant que l'écho couvre tout le trajet, puis
s'effondre : au-delà de 3 s (60 m de portée à 20 m/s), on vole à l'aveugle,
on heurte des obstacles et les insectes arrivent démarqués. L'optimum est
juste avant, vers 2,5 à 3 s. **C'est le rapport portée / vitesse qui fixe le
rythme** : pour le déplacer, on change `echo.portee_m` ou `vol.vitesse_m_s`.
Avec des sens améliorés (Oreilles 5, Mémoire 5, Instinct 10), l'optimum passe
à 4 s, comme le veut le GDD.

Le spam n'est puni que par l'audace : −10 % à un écho par seconde, −16 % à
deux. C'est modeste. Au premier essai, à 10 m/s, il ne coûtait que 4 % :
l'audace monte avec la distance, et une chauve-souris lente n'en gagne presque
pas entre deux échos. D'où les 20 m/s retenus : ×2,1 après 5 s d'aveugle,
×3,2 après 20 s.

### 3. L'audace reste basse au rythme optimal

Au rythme optimal, l'audace oscille entre ×1 et ×1,8 (×1,4 en moyenne). Les
×2,1 et ×3,2 du GDD demandent 5 et 20 s de vol à l'aveugle. La raison : la
division par deux ramène toute audace inférieure à ×2 à ×1. Tant qu'on n'a
pas volé 86 m sans écho, un écho coûte autant d'audace qu'une collision.

Variante mesurée (`audace.division_bonus_seul` à true : l'écho ne divise que
le bonus, ×3,2 devient ×2,1) : audace moyenne ×1,8 au rythme optimal, spam
puni de 13 % au lieu de 10 %, optimum toujours à 2,5 s. Mais tout le jeu actif
rapporte plus : l'attentif atteint la première Hibernation en 16 min et le
rapport idle / attentif monte à 3,9. Si on l'adopte, il faut refaire le calage.

### 4. Les sens n'ont pas tous la même valeur

Ce que des niveaux de sens ajoutent au vol (`rythme_echo.py --sens`) :

| Profil | Sens | niveau 1 | niveau 3 | niveau 5 | niveau 10 |
|---|---|---|---|---|---|
| attentif | Oreilles | +2,4 % | +5,9 % | +4,2 % | +8,5 % |
| attentif | Mémoire | +1,9 % | +6,3 % | +11,4 % | +11,4 % |
| moyen | Oreilles | −2,5 % | −2,3 % | −1,6 % | +1,5 % |
| moyen | Mémoire | +5,7 % | +12,3 % | +12,3 % | +12,3 % |
| idle pur | Instinct | −0,4 % | +3,5 % | +9,1 % | +30,8 % |

L'Instinct n'apporte presque rien aux joueurs qui font des échos, ni les
Oreilles et la Mémoire à l'idle pur.

- **Mémoire** plafonne au niveau 5 : la révélation dure alors aussi longtemps
  que le trajet jusqu'au bout de la portée. Les niveaux suivants ne servent
  qu'avec plus de portée.
- **Oreilles** seule rapporte peu, et fait même perdre le joueur moyen : avec
  plus de portée, il espace ses échos et les objets lointains arrivent en
  fantôme. Elle ne vaut qu'accompagnée de Mémoire et de Rhinolophes (le
  marquage plus long).
- **Instinct** ne sert qu'à l'idle pur, mais beaucoup.

Piste pour l'issue #15 : lier Oreilles et Mémoire, ou donner aux Oreilles un
autre bénéfice que la portée seule.

### 5. Le Chœur devient automatique avec une grande portée

Le seuil de 5 insectes est fixe, mais le nombre d'insectes qu'une onde touche
grandit avec sa portée (un insecte isolé tous les 40 m en moyenne). Joueur
moyen, vol seul :

| Oreilles | Portée | Échos qui déclenchent un Chœur | Chœurs par minute |
|---|---|---|---|
| 0 | 60 m | 2 % | 0,5 |
| 5 | 90 m | 3 % | 0,6 |
| 10 | 120 m | 6 % | 1,1 |
| 20 | 180 m | **50 %** | **9,3** |

Au-delà d'une dizaine de niveaux d'Oreilles, le Chœur cesse d'être une
récompense de l'écoute pour devenir la norme. Pistes pour les issues #11 et
#15 : ne compter que les insectes à moins de 4 s de vol, faire grandir le
seuil avec la portée, ou plafonner les Oreilles.

### 6. Les saisons suivantes : impossible avec un bonus qui grandit d'autant à chaque harmonique

Le joueur simulé hiberne dès que les feuilles tombent (H ≥ 1) et garde ses
harmoniques. À la saison k, il a k − 1 harmoniques, et tout le jeu va
1 + x · (k − 1) fois plus vite (x : le bonus par harmonique). La saison k dure
donc T1 / (1 + x · (k − 1)), où T1 est la durée de la première.

Tenir T1 entre 20 et 25 min et les saisons 2 à 10 entre 10 et 15 min
demanderait à la fois 1 + x ≥ 20 / 15, soit x ≥ 0,33, et 1 + 9x ≤ 25 / 10,
soit x ≤ 0,17. C'est impossible : les deux bouts du tableau « Rythme visé » se
contredisent. Le meilleur compromis est x ≈ 14 % (6 saisons sur 9) : c'est
la valeur retenue.

| Saison | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | dans la cible |
|---|---|---|---|---|---|---|---|---|---|---|---|
| GDD : +2 % par harmonique | 21,0 | 20,6 | 20,2 | 20,1 | 19,4 | 19,0 | 18,6 | 18,3 | 18,1 | 17,7 | 0 sur 9 |
| calage retenu : +14 % | 22,9 | 20,3 | 18,0 | 16,6 | 14,8 | 13,7 | 12,3 | 11,7 | 10,8 | 10,2 | 6 sur 9 |
| +60 % à la première, puis +2 % | 22,9 | 14,5 | 14,1 | 14,4 | 13,8 | 13,7 | 13,2 | 13,4 | 12,9 | 12,8 | 9 sur 9 |

(durées en minutes, joueur moyen, moyenne de 5 séries ; la ligne GDD utilise
aussi les productions et `secondes_de_colonie` du GDD)

Avec les +2 % du GDD, la deuxième saison n'est qu'à peine plus courte que la
première (20,6 contre 21,0 min), alors que l'issue #18 la veut « nettement
plus rapide ».

Attendre le givre (`--politique givre` : hiberner quand le gain double
depuis la saison précédente) fait pire : les saisons s'allongent, de 29 min
à la saison 2 à 94 min à la saison 10. Avec H = ⌊(I / 10^5)^0,45⌋, doubler H
demande 4,7 fois plus d'insectes.

Ce qui marche : **une forte accélération à la première Hibernation, puis une
faible**. Avec +60 % dès la première harmonique, puis +2 % par harmonique
comme dans le GDD, les 9 saisons tiennent leur cible. La place naturelle de ce
bonus est la première note (ou le premier accord) de la Partition (issue #19).
Pour l'essayer : `bonus_production_pourcent` à 2 et
`bonus_premiere_harmonique_pourcent` à 60.

### 7. L'idle pur atteint sa première Hibernation en une heure

L'idle pur la touche à 62 min, application ouverte, sans gains hors-ligne ni
expéditions (absentes du MVP). Les gains hors-ligne (production de la colonie,
jusqu'à 10 h) l'aideront ; à vérifier avec l'issue #20.

## Journal des valeurs

### Règles et valeurs du GDD

| Valeur | GDD | Calée | Pourquoi | Effet mesuré |
|---|---|---|---|---|
| `insectes.secondes_de_colonie` (ajout) | 0 (la règle n'existe pas) | 1,5 | que le vol compte pour la progression | rapport idle / attentif 1,3 → 3,3 ; part du vol (moyen) 2 % → 74 % |
| `especes.liste[].production_par_seconde` | 0,1 / 1 / 8 / 47 | 0,025 / 0,25 / 2 / 12 | compenser le vol, devenu trois fois plus rentable | première Hibernation (moyen) 7,4 min → 22,9 min, toutes les espèces achetées pendant la première saison |
| `harmoniques.bonus_production_pourcent` | 2 | 14 | que les saisons suivantes raccourcissent | saisons 2 à 10 dans la cible : 0 → 6 sur 9 |
| `harmoniques.bonus_premiere_harmonique_pourcent` (ajout) | — | 0 | levier pour la Partition (#19), sans effet à 0 | à 60, avec un bonus de 2 : 9 sur 9 |
| `audace.division_bonus_seul` (ajout) | — | false | variante à essayer, sans effet à false | à true : spam puni de 13 % au lieu de 10 % |

### Valeurs inventées (absentes du GDD)

| Valeur | Premier essai | Retenue | Pourquoi | Effet mesuré |
|---|---|---|---|---|
| `vol.vitesse_m_s` | 10 | 20 | à 10 m/s, l'audace monte trop lentement pour punir le spam | spam (un écho par seconde) : −4 % → −10 % |
| `echo.portee_m` | 30 | 60 | garder 3 s de vol couvertes par un écho à 20 m/s | optimum à 2,5 s |
| `echo.vitesse_onde_m_s` | 60 | 120 | même échelle : l'onde atteint le bout de sa portée en 0,5 s | — |
| `grottes[0].obstacles` | 6 à 14 m | 20 à 46 m | à 20 m/s, un obstacle toutes les 1,7 s au lieu d'un par seconde (GDD : premières grottes peu denses) | idle pur : 9,8 collisions par minute |
| `grottes[0].insectes` | 10 à 30 m | 20 à 60 m | même rythme par seconde à 20 m/s : un insecte toutes les 2 s | — |
| `grottes[0].essaims` | tous les 1 000 à 1 600 m, sur 12 m | tous les 2 400 à 3 200 m, sur 24 m | même rythme par seconde à 20 m/s | premier Chœur à 2 min 18 s |

Inventées et gardées telles quelles : `grottes[0].valeur_insecte` (1), les
raisons de coût des espèces (1,15 / 1,13 / 1,11 / 1,09) et les prix des sens
(50 × 1,6^n, Instinct 30 × 1,5^n).

### Le joueur simulé a aussi été corrigé

Deux défauts du modèle de joueur faussaient les premières mesures :

- il améliorait un sens dès qu'il coûtait moins cher que l'espèce visée, et
  dépensait ainsi 70 % de ses insectes en sens. Il achète désormais sens et
  espèces selon la même règle : ce qui est remboursé le plus vite ;
- avec plus de portée, il espaçait ses échos au point que les insectes
  lointains arrivaient démarqués. L'écart entre deux échos ne dépasse plus ce
  que la chauve-souris parcourt pendant le marquage.

## Décisions

Prises le 3 novembre 2026 :

1. **`secondes_de_colonie` est validé** (k = 1,5) : la valeur des insectes
   attrapés suit la colonie, et le vol compte pendant toute la saison.
2. **Le bonus de +14 % par harmonique est retenu**, avec ses 6 saisons sur 9
   dans la cible. Le levier `bonus_premiere_harmonique_pourcent` reste
   disponible pour concevoir la Partition (issue #19) : une première note à
   +60 %, avec un bonus ramené à 2 % par harmonique, ferait tenir les
   9 saisons.

Le GDD (`docs/gdd.md`) garde ses valeurs d'origine, comme celui du
Somnambule : `data/README.md` signale chaque écart.

Restent ouvertes, pour les issues concernées :

3. **Audace** : division littérale (×1,4 en moyenne au rythme optimal) ou
   division du bonus seul (×1,8, calage à refaire).
4. **Sens et Chœur** : revoir les Oreilles (#15) et lier le seuil du Chœur à
   la portée (#11).
5. **Profils de joueur** : leurs adresses sont inventées ; les playtests (#12,
   #21) diront s'il faut les corriger, et le calage avec.
