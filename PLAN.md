# Plan du tutoriel Faust

Ce tutoriel apprend à programmer en Faust de façon progressive : chaque
chapitre ne s'appuie que sur les précédents. Il part des *idiomes* que la
pratique des programmeurs Faust a fait émerger (le document « Faust
programming idioms ») et les rattache aux fonctions des bibliothèques
standard (`faustlibraries`), où ils sont employés.

## Public et prérequis

- Avoir déjà programmé dans un langage quelconque.
- Savoir ce qu'est un échantillon, une fréquence d'échantillonnage, un
  filtre passe-bas. Aucune connaissance avancée de traitement du signal
  n'est requise : une grande part du travail en Faust consiste à fabriquer
  les signaux qui *pilotent* les algorithmes, pas les algorithmes eux-mêmes.
- Aucune connaissance de la programmation fonctionnelle : elle est
  introduite au fil des chapitres.

## Outils

- L'IDE en ligne (<https://faustide.grame.fr>) pour écouter et voir les
  diagrammes, ou le compilateur `faust` en ligne de commande.
- `faustprobe` (faust-rs) pour *mesurer* un programme : compiler, rendre
  hors ligne, lire les échantillons et les statistiques. Chaque exemple et
  chaque solution d'exercice du tutoriel porte les commandes qui le
  vérifient, et `make check` les exécute toutes.

## Forme de chaque chapitre

1. **L'idée** : le concept en quelques paragraphes.
2. **Un exemple minimal** exécutable (`exemples/NN/*.dsp`).
3. **L'idiome dans les bibliothèques** : la même idée dans une fonction
   réelle de `faustlibraries`, citée avec son préfixe (`ba.`, `si.`, ...).
4. **Pièges** : les erreurs typiques et comment les reconnaître.
5. **Exercices**, avec leurs solutions dans `exemples/NN/solutions/`,
   vérifiées par la même commande que les exemples.

## Partie A. Les bases du langage

1. **Premier son.** `process`, `import("stdfaust.lib")`, un oscillateur,
   un gain, une sortie stéréo. Écouter dans l'IDE, mesurer avec faustprobe.
   Les nombres, les opérateurs comme blocs (`+`, `*(0.5)`), les commentaires.
2. **L'algèbre de blocs.** Les cinq compositions `:` `,` `<:` `:>` `~`,
   le fil `_` et la coupure `!`, l'arité (entrées, sorties) et les règles
   de compatibilité, la lecture des diagrammes SVG. Un mixeur stéréo.
3. **Nommer les entrées.** Du câblage pur aux arguments :
   `foo(a, b, c) = ...`, les variantes `foo1` à `foo3` du document des
   idiomes ; définitions locales avec `with`. La forme en arguments et la
   forme en fils décrivent le même bloc. Les primitives `inputs(x)` et
   `outputs(x)`.
4. **La mémoire d'un échantillon.** `mem`, l'apostrophe `x'`, `@(n)` ;
   la récursion `~` et son retard implicite ; l'intégrateur `+ ~ _`, le
   compteur `1 : + ~ _`, la somme glissante `+(x - x@n) ~ _`, le filtre
   à un pôle. Le temps n'existe qu'au passé : on calcule l'échantillon
   suivant à partir des précédents.

## Partie B. Fabriquer des signaux de contrôle

5. **L'état à plusieurs variables.** Le motif `tick ~ (_, _) : !, _` :
   autant de fils de retour que de variables d'état, `tick(x, y) = x1, y1`
   donne les nouvelles valeurs, la sortie coupe ce qui est interne.
   Exemples : l'oscillateur en quadrature `quadosc` et le `line~` de Max
   (deux écritures) ; `letrec`, l'autre écriture du même état.
6. **Signaux logiques et événements.** Les booléens sont des 0 et des 1 ;
   fronts montants, descendants, changements ; `impulse`, `release`,
   `trigger` ; remise à zéro par multiplication ; `min` et `max` comme
   opérateurs logiques ; maintien d'une valeur (échantillonneur-bloqueur) ;
   compteurs avec remise à zéro ; `select2` et `ba.if`. Exemple : compter
   les fronts d'une horloge MIDI sur une seconde.
7. **Signaux périodiques et séquences.** Le phasor et `ma.frac`, gestion
   de la phase, trains d'impulsions, métronome, pas de séquenceur ; de la
   phase à l'oscillateur par table ; enveloppes et rampes, lissage des
   commandes. Exemple final : l'ADSR en boucle.
8. **L'interface utilisateur.** Sliders, boutons, cases, `nentry`, groupes
   `hgroup`/`vgroup`/`tgroup`, chemins et étiquettes, métadonnées
   (`[unit:Hz]`, `[scale:log]`, `[style:knob]`, `[midi:...]`), bargraphs
   pour afficher un signal interne, l'idiome des `*_demo` des
   bibliothèques : contrôles définis dans un `with`, contournement par
   case à cocher.

## Partie C. Calculer à la compilation

9. **Compilation ou exécution.** Faust ne compile pas le texte mais la
   sémantique du programme : propagation symbolique, constantes calculées
   à la compilation, sorties inutilisées supprimées, partage des
   sous-expressions. Ce qui doit être connu à la compilation (nombre de
   voies, ordre d'un filtre, taille d'un retard maximal) et ce qui peut
   varier à l'exécution. `int`, `float`, les erreurs quand une valeur
   d'exécution arrive là où une constante est attendue.
10. **Choisir parmi des valeurs.** `waveform` + `rdtable` contre
    `ba.selectn` : la table de la gamme majeure, le « choice mapper »,
    ce que coûte chaque forme ; `rdtable` avec une fonction génératrice,
    `rwtable` ; tabulation d'une fonction coûteuse.
11. **Itérer et filtrer par motifs.** `par`, `seq`, `sum`, `prod` avec un
    indice ; définitions par cas `foo(0) = ...; foo(n) = ...` et `case` ;
    récursion sur un entier ; motifs sur une liste `(x, xs)` ; le réseau
    d'oscillateurs réécrit par motifs, et pourquoi il compile plus vite.
12. **L'ordre supérieur.** Des blocs en argument, des blocs en résultat,
    les abstractions `\(x).(...)`, l'application partielle ; la convention
    des bibliothèques : paramètres fixes d'abord, signal audio en dernier ;
    combinateurs de `routes.lib` et `signals.lib`.

## Partie D. Écrire du code réutilisable

13. **Environnements.** Espaces de noms, `environment { }`, `library()`,
    le filtre à variables d'état `svf` comme « classe » ; la substitution
    explicite `expr[a = b]` ; les environnements passés en argument.
14. **Générique puis spécialisé.** Un algorithme général avec des
    paramètres dynamiques, spécialisé en fixant des constantes ou en
    coupant des sorties : le compilateur n'engendre que le code utile.
    Exemples : les familles `svf`, les filtres d'Eric Tarr à plusieurs
    sorties, les modèles de formants de physmodels.lib.
15. **Écrire une bibliothèque.** Couches (bloc générique, niveau
    intermédiaire, enveloppes pour l'utilisateur), préfixes et
    `stdfaust.lib`, `declare`, format de documentation des bibliothèques,
    tests.
16. **Projet final.** Une réverbération complète construite pas à pas
    (filtres en peigne et passe-tout, réseau à retards rebouclés,
    interface), qui réemploie tous les chapitres.

## Annexes

- **A. Observer un programme** : faustprobe, les diagrammes, `attach`,
  les bargraphs, la vérification des exemples de ce tutoriel.
- **B. Différentiation automatique** : `fad` et `rad` de faust-rs,
  extensions absentes du compilateur C++, pour qui veut apprendre les
  paramètres d'un programme Faust par descente de gradient.
- **C. Aide-mémoire** : syntaxe, priorités des opérateurs, préfixes des
  bibliothèques.

## Corrections apportées au document des idiomes

Le tutoriel reprend les exemples du document des idiomes après vérification.
Ceux qui ne compilaient pas ou ne faisaient pas ce qu'annonçait le texte
sont corrigés et la correction est signalée dans le chapitre :

- la définition de `impulse` citée depuis `faust_tutorial.pdf` est
  tronquée ;
- les deux versions de `release` ne sont pas équivalentes : celle avec
  `max(0, ...)` ne descend jamais sous zéro ;
- la réécriture par motifs du réseau d'oscillateurs ne reproduit pas
  l'original : l'original chaîne quatre nœuds, la réécriture trois, dans
  un autre ordre.
