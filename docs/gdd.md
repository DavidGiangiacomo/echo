# L'Écho — Game Design Document

Oct 8, 2026 · @David

## Pitch et intention

L'Écho est un runner idle mobile où une chauve-souris vole dans des grottes plongées dans le noir. Un tap envoie une onde d'écholocation qui révèle le terrain quelques instants ; voler à l'aveugle rapporte davantage, mais coûte cher en cas de collision.

**Expérience visée** : le plaisir de lire l'obscurité. Chaque écho est une photo éclair du danger ; le joueur mémorise, anticipe, et choisit quand « regarder » à nouveau.

**Format** : mobile, paysage ou portrait selon le prototype (question ouverte), jouable à une main. Sessions de 30 secondes à 5 minutes ; la colonie progresse en continu.

**Cible** : joueurs d'incrémentaux mobiles qui aiment une part d'adresse, et joueurs sensibles à une ambiance sonore forte.

**Ce qui le distingue** : l'information est la ressource. Le joueur ne choisit pas seulement quand agir, mais quand voir. Et l'écran presque noir donne au jeu une identité visuelle immédiate.

## Piliers de design

Cinq principes tranchent les décisions ; une idée qui en contredit un est écartée.

1. **Voir est un choix.** L'écho est la seule source d'information, et il a un prix.
2. **Le son fait le jeu.** Chaque élément important s'entend autant qu'il se voit.
3. **Le noir est beau.** L'écran sombre est une esthétique, pas une contrainte à compenser.
4. **La colonie vit sans toi.** La part idle est une vraie communauté qui grandit, pas un compteur.
5. **Apprendre la vraie chauve-souris.** Espèces, comportements et hibernation s'inspirent du réel.

## Mécanique centrale : l'écho

La chauve-souris vole seule dans le noir ; le joueur décide quand envoyer un écho pour voir, et chaque écho se paie en audace. Mais un écho bien placé marque aussi les proies, qui valent alors trois fois plus.

### Contrôles

- **Tap** : envoyer un écho.
- **Glisser vers le haut ou le bas** : changer de couloir de vol (3 couloirs : plafond, milieu, sol).

### L'obscurité et l'écho

L'écran est noir, à part la chauve-souris. Un écho part d'elle en cercle et révèle tout ce qu'il touche : parois, stalactites, insectes, dangers. La révélation dure 1,5 seconde, puis les contours s'effacent en laissant un fantôme très pâle.

### L'audace (le multiplicateur)

L'audace monte avec la distance parcourue depuis le dernier écho, de plus en plus lentement : ×2,1 après 100 m, ×3,2 après 400 m. Un écho la divise par deux ; une collision la remet à ×1 et étourdit la chauve-souris 1 seconde.

### Le marquage (la contrepartie)

Les insectes touchés par l'onde sont marqués : attrapés dans les 4 secondes, ils valent ×3. Un écho qui marque 5 insectes ou plus déclenche un **Chœur**, qui double ce bonus.

Tout le jeu est là : voler à l'aveugle fait monter l'audace, mais l'écho au bon moment rapporte gros.

### L'instinct (la part idle à l'écran)

Sans écho récent, la chauve-souris esquive seule un obstacle invisible avec une probabilité qui augmente avec l'amélioration Instinct. Le jeu peut tourner sans les mains, avec un rendement bien plus faible qu'un joueur attentif.

### La frénésie

Les insectes remplissent une jauge de faim. Pleine, elle déclenche sur demande 15 secondes de frénésie : la grotte reste éclairée, les échos sont gratuits et chaque insecte vaut ×5. C'est l'équivalent du mode Rage d'Idle Slayer.

## Boucles de jeu

Le jeu tient en trois boucles imbriquées, et la décision « écho maintenant ? » est au centre de la plus courte.

**Trois boucles imbriquées : le vol, la colonie, la saison** (↺ : la boucle recommence)

**Moment-à-moment · quelques secondes**

Vol dans le noir → L'audace monte → **Écho maintenant ?** → Proies marquées ou collision ↺

↓ *les insectes financent la colonie*

**Session · 2 à 5 minutes**

Insectes attrapés → Espèces et sens → Expédition envoyée → Chœur ou frénésie ↺

↓ *la saison grossit jusqu'à l'Hibernation*

**Long terme · une saison par Hibernation**

Fin de saison, feuilles mortes → Hibernation : harmoniques → Partition et accords → Printemps, nouvelle grotte ↺

Les secondes bien jouées financent la colonie, et la colonie fait grossir la saison jusqu'à l'Hibernation.

## Ressources et économie

Quatre ressources : une monnaie, une jauge, une ressource rare d'exploration et une méta-monnaie.

| Ressource | Rôle | Sources | Puits |
| --- | --- | --- | --- |
| Insectes | Monnaie principale | Chasse en vol, chasse de la colonie, gains hors-ligne | Recruter des chauves-souris, améliorer les sens |
| Faim | Jauge de frénésie | Chaque insecte attrapé, davantage s'il est marqué | Déclencher une frénésie |
| Cristaux d'écho | Ressource rare, permanente entre deux hibernations | Expéditions de la colonie, galeries secrètes révélées par un écho | Techniques d'écho (voir Les sens) |
| Harmoniques | Méta-monnaie de prestige | Gagnées à l'Hibernation, selon les insectes de la saison | La Partition |

Insectes et colonie repartent de zéro à chaque Hibernation ; cristaux, techniques et harmoniques restent.

## La colonie et les améliorations

La colonie produit les insectes passifs, part en expédition, et chaque espèce apporte un trait tiré de son comportement réel.

### Les espèces (générateurs)

Valeurs de départ pour le simulateur ; production en insectes par seconde.

| Espèce | Coût de base (insectes) | Production de base (/s) | Trait inspiré du réel |
| --- | --- | --- | --- |
| Pipistrelle commune | 15 | 0,1 | Petite et nombreuse : aucun trait, c'est la base |
| Murin de Daubenton | 100 | 1 | Chasse au ras de l'eau : production ×2 dans les grottes à rivière |
| Oreillard | 1 100 | 8 | Très grandes oreilles : portée de l'écho du joueur +1 % par oreillard (plafond +50 %) |
| Grand rhinolophe | 12 000 | 47 | Écholocation par le nez, très précise : marquage +0,1 s par rhinolophe (plafond +3 s) |
| Noctule commune | 130 000 | 260 | Grande voyageuse : expéditions 25 % plus rapides |
| Roussette d'Égypte | 1 400 000 | 1 400 | Écholocation par claquements de langue : trouve parfois un cristal |

Tous les 25 individus d'une même espèce, sa production double. Une fiche courte et vraie accompagne chaque espèce.

### Les expéditions

Le joueur envoie un groupe de chauves-souris dans une galerie latérale, pour 1 à 8 heures. Elles ne produisent pas pendant ce temps, mais reviennent avec des cristaux d'écho et un butin d'insectes. C'est le lien entre la colonie et la progression rare.

### Les sens (améliorations à niveaux)

| Sens | Effet par niveau |
| --- | --- |
| Oreilles | Portée de l'écho +10 % |
| Mémoire | Durée de révélation +0,2 s |
| Ailes | Changement de couloir plus rapide |
| Instinct | Esquive automatique +3 points de probabilité |
| Estomac | Jauge de faim remplie 10 % plus vite |

### Les techniques d'écho (cristaux)

Achetées avec des cristaux et conservées pour toujours ; deux emplacements seulement, donc un vrai choix de build.

- **Double écho** : une seconde onde part 0,5 s après la première.
- **Écho dirigé** : un cône devant la chauve-souris, deux fois plus loin, mais rien derrière.
- **Écho résonant** : les contours révélés restent visibles deux fois plus longtemps.
- **Écho discret** : une fois par minute, un écho ne coûte pas d'audace.

## Prestige : l'Hibernation

L'Hibernation endort la colonie pour l'hiver : insectes, colonie et sens repartent de zéro, et la saison écoulée devient des harmoniques permanentes. Au réveil, c'est le printemps suivant.

### Déclenchement

Le joueur choisit le moment. Les feuilles qui tombent à l'entrée de la grotte signalent qu'une Hibernation rapporterait au moins 1 harmonique ; le givre apparaît quand le gain double depuis la dernière saison.

### Ce que rapportent les harmoniques

- **Non dépensées** : +2 % de production globale chacune.
- **Dépensées** dans la Partition.

### La Partition (arbre de prestige)

La Partition est une grille de 3 portées sur 8 mesures. Chaque harmonique dépensée écrit une note dans une case, avec son bonus propre.

| Portée | Thème | Exemples de notes |
| --- | --- | --- |
| Chasse | Jouer l'actif | Audace qui monte 20 % plus vite ; Chœur dès 4 insectes ; frénésie +5 s |
| Colonie | Jouer l'idle | Espèces achetées automatiquement ; plafond hors-ligne +2 h ; expéditions simultanées +1 |
| Écho | Jouer l'information | Troisième emplacement de technique ; fantôme des contours plus visible ; écho gratuit au départ de chaque grotte |

**Les accords** : quand les trois portées d'une même mesure sont remplies, un accord sonne et donne un bonus supplémentaire. Le joueur choisit donc entre se spécialiser sur une portée ou compléter des accords. La musique du jeu s'enrichit à chaque accord joué.

### Les hivers rudes (défis)

À partir de la saison 10 : une saison sans colonie, une sans écho, une avec un seul couloir, etc. Chaque défi réussi donne un bonus permanent unique.

### Deuxième couche : la Migration

Après un certain nombre de saisons, la colonie peut migrer vers un nouveau réseau de grottes. La Migration réinitialise aussi la Partition et débloque de nouveaux biomes et de nouvelles espèces. À n'introduire qu'après validation de la première couche.

## Les grottes

Chaque grotte a une règle acoustique qui change la façon dont l'écho se comporte ; une nouvelle grotte se débloque tous les 3 à 5 hivers.

| Grotte | Déblocage | Règle acoustique | Danger propre |
| --- | --- | --- | --- |
| Grotte calcaire | Départ | Aucune ; stalactites et stalagmites | Gouttes qui tombent |
| Rivière souterraine | Saison 3 | L'eau absorbe le son : portée de l'écho −30 % au-dessus de l'eau | Remous qui projettent de l'eau |
| Mine abandonnée | Saison 6 | Des machines grondent : l'écho est brouillé quand elles tournent | Wagons sur rails |
| Gouffre cristallin | Saison 10 | Les cristaux renvoient l'écho : chaque onde rebondit une fois | Éclats qui se détachent |
| Catacombes | Saison 15 | Les couloirs étroits renvoient un écho mais déformé | Passages qui se referment |
| Cathédrale engloutie | Saison 21 | Réverbération immense : un écho révèle tout l'écran, mais coûte toute l'audace | Cloches qui assourdissent |

### Les prédateurs et les intrus

- **Chouette** (aux sorties de grotte) : chaque écho l'attire. Il faut traverser à l'aveugle.
- **Araignées** : toiles invisibles même à l'écho ; seul le fantôme des contours les trahit.
- **Spéléologues** : leur lampe éclaire tout, ce qui supprime l'audace mais rend le passage facile. Les éviter ou en profiter est un choix.

### Les galeries secrètes

Certaines parois sonnent creux à l'écho. Un écho envoyé juste devant ouvre une galerie courte, riche en cristaux. C'est la récompense de l'écoute attentive.

## Progression hors-ligne et notifications

Quand l'application est fermée, la colonie continue de chasser et les expéditions avancent. La chauve-souris du joueur, elle, se repose au perchoir.

- **Gains** : production de la colonie, sans audace ni marquage. Les expéditions reviennent à l'heure prévue, application ouverte ou non.
- **Plafond** : 10 heures, extensible par la portée Colonie.
- **Retour** : un écran « Pendant ton absence » montre le butin et les expéditions revenues, avec leur cristal éventuel.
- **Notifications** : uniquement le retour d'une expédition, désactivable. Pas de relance quotidienne.
- **Anti-triche** : l'heure système est comparée à la dernière sauvegarde ; un saut en arrière annule le gain de la session.

## Direction artistique, son et accessibilité

Un écran noir traversé d'ondes lumineuses : le jeu doit être reconnaissable sur une seule capture d'écran.

### Image

- **Style** : fond noir pur, contours au trait fin révélés par l'onde, un seul point de couleur par élément important (insectes dorés, dangers rouges, cristaux cyan).
- **L'onde** : un cercle lumineux qui s'étend ; les contours s'allument au passage puis s'éteignent doucement.
- **La chauve-souris** : une petite silhouette toujours visible, légèrement lumineuse, au battement d'ailes lisible.
- **Le perchoir** (écran de la colonie) : la seule scène éclairée, chaude, où l'on voit la colonie suspendue grandir.
- **Atout technique** : sur les écrans OLED, le noir économise la batterie. C'est un argument à mettre en avant.

### Son

- L'écho s'entend : chaque obstacle touché renvoie un clic, plus aigu s'il est proche, spatialisé gauche/droite au casque.
- Les insectes bourdonnent avant d'être visibles.
- Le Chœur et les accords de la Partition ajoutent des notes à la musique de fond.

### Accessibilité

- **Mode contraste** : contours plus épais et plus longtemps visibles.
- **Jeu au son** : les indices sonores suffisent à éviter la plupart des obstacles, ce qui rend le jeu en partie jouable par des joueurs malvoyants. Piste à explorer sérieusement.
- Toutes les vibrations sont désactivables.

## Formules et équilibrage

Ces formules sont des points de départ, à régler dans un simulateur d'économie avant tout prototype jouable.

### Audace

d est la distance en mètres depuis le dernier écho. La croissance logarithmique rend le vol aveugle de plus en plus risqué pour un gain de plus en plus faible : ×1,7 à 50 m, ×2,1 à 100 m, ×3,2 à 400 m.

```latex
A(d) = 1 + \ln\left(1 + \frac{d}{50}\right)
```

### Valeur d'un insecte attrapé

b est la valeur de base de la grotte ; m vaut 3 si l'insecte est marqué (6 pendant un Chœur), 1 sinon.

```latex
V = b \cdot A(d) \cdot m
```

### Instinct (esquive automatique)

k est le niveau d'Instinct ; la probabilité est plafonnée à 85 % pour que le joueur attentif garde l'avantage.

```latex
i(k) = \min\left(0{,}85;\; 0{,}20 + 0{,}03\,k\right)
```

### Coût des espèces

Avec r entre 1,07 et 1,15 selon l'espèce.

```latex
C_n = C_0 \cdot r^{\,n}
```

### Harmoniques à l'Hibernation

I est le total d'insectes gagnés pendant la saison.

```latex
H = \left\lfloor \left(I / 10^{5}\right)^{0{,}45} \right\rfloor
```

### Rythme visé

| Moment | Durée cible |
| --- | --- |
| Premier Chœur | 2 à 3 min |
| Première expédition disponible | 10 min |
| Première Hibernation possible | 20 à 25 min |
| Saisons suivantes, jusqu'à la saison 10 | 10 à 15 min chacune |
| Nouvelle grotte | Tous les 3 à 5 hivers |

Le point à surveiller : un écho toutes les 2 à 4 secondes doit être le rythme optimal en début de partie, et s'allonger avec les améliorations.

## Monétisation mobile éthique

Recommandation : gratuit avec un achat unique « Colonie fondatrice », sans monnaie premium. Une pub plein écran casserait l'immersion dans le noir et le son.

- **Achat unique Colonie fondatrice** (3 à 5 €) : supprime les pubs, ajoute une expédition simultanée et un perchoir décoratif.
- **Pubs récompensées, toujours optionnelles** : doubler un retour d'expédition ou un gain hors-ligne. Au plus 3 par jour.
- **Cosmétiques** : couleurs d'onde, silhouettes de chauve-souris, décors du perchoir. Aucun effet sur la progression.
- **Interdits** : monnaie premium, cristaux achetables, accélérateurs de prestige payants.

Alternative : jeu payant 3 € sans aucune pub, cohérent avec un jeu d'ambiance.

## Périmètre MVP et feuille de route Godot

Le MVP doit prouver une seule chose : qu'il est amusant de choisir quand voir, pendant 20 minutes.

### Contenu du MVP

- [ ] Une grotte (calcaire), sans règle acoustique
- [ ] Écho, révélation et fantôme, audace, marquage, collision, 3 couloirs
- [ ] 4 espèces et 3 sens (Oreilles, Mémoire, Instinct)
- [ ] L'Hibernation avec une Partition de 3 portées × 2 mesures
- [ ] Gains hors-ligne et sauvegarde
- [ ] Pas d'expéditions, pas de frénésie, pas de techniques d'écho, pas de monétisation

### Architecture Godot 4

- **Langage** : GDScript pour un export mobile sans surprise.
- **Scènes** : `Cave` (défilement et génération des obstacles par segments), `Bat` (couloirs, collisions), `EchoWave` (l'onde), `Roost` (écran de la colonie), `Score`.
- **Révélation** : chaque obstacle garde l'heure à laquelle l'onde l'a atteint (quand le rayon dépasse sa distance) et calcule sa propre opacité. Plus simple et plus fidèle au gameplay qu'un shader de masque global.
- **Son** : `AudioStreamPlayer2D` par obstacle touché, pour obtenir le panoramique gauche/droite gratuitement.
- **Couloirs** : 3 positions fixes, transition par `Tween`.
- **État global, hors-ligne, sauvegarde** : même socle que pour Le Somnambule (autoload `GameState`, horodatage à la pause, JSON dans `user://`). Les deux jeux peuvent partager ce code.

### Étapes

1. **Simulateur d'économie** : valider audace, marquage et rythme d'écho optimal.
2. **Prototype gris** : formes blanches sur fond noir, onde, collision. Tester la sensation de « voir par éclairs ».
3. **MVP complet** : contenu ci-dessus, faire jouer 3 à 5 personnes, dont une au casque sans regarder l'écran.
4. **Tranche verticale** : expéditions, frénésie, une technique d'écho, la rivière souterraine, rendu définitif.
5. **Contenu et polish** : les 6 grottes, prédateurs, hivers rudes, fiches d'espèces.
6. **Publication** : test fermé Google Play, puis sortie.

## Risques et questions ouvertes

### Risques

| Risque | Pourquoi c'est un problème | Parade |
| --- | --- | --- |
| Le noir fatigue ou frustre | Le joueur se sent puni de ne pas voir | Fantôme des contours, mode contraste, premières grottes peu denses |
| Spam d'écho | Si l'écho coûte trop peu, le noir n'a plus d'intérêt | Division de l'audace par deux ; à régler dans le simulateur |
| Deux gestes sur une main | Tap et glisser peuvent se confondre | Seuil de glissement net ; tester tôt sur plusieurs téléphones |
| Joué sans le son | La moitié du plaisir disparaît dans le métro | Le visuel seul doit suffire ; le son est un bonus fort, pas une obligation |
| Le joueur idle pur stagne | Le jeu n'est pas un idle s'il exige l'actif | Colonie, expéditions et portée Colonie suffisantes pour progresser sans jouer |

### Questions ouvertes

- Portrait ou paysage ? Le paysage montre plus de grotte devant, le portrait favorise la main unique.
- Trois couloirs, ou un vol libre en hauteur (doigt glissé) ?
- Ton : documentaire et poétique, ou plus humoristique ?
- Viser sérieusement l'accessibilité au son, avec des testeurs concernés ?
