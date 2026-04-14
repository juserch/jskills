# Guide utilisateur de Council Fuse

> Demarrez en 5 minutes — deliberation multi-perspective pour de meilleures reponses

---

## Installation

### Claude Code (recommande)

```bash
claude plugin add juserai/forge
```

### Installation universelle en une ligne

```
Fetch and follow https://raw.githubusercontent.com/juserai/forge/main/skills/council-fuse/SKILL.md
```

> **Zero dependance** — Council Fuse ne necessite aucun service externe ni API. Installez et c'est parti.

---

## Commandes

| Commande | Fonction | Quand l'utiliser |
|----------|----------|------------------|
| `/council-fuse <question>` | Lancer une deliberation complete du conseil | Decisions importantes, questions complexes |

---

## Fonctionnement

Council Fuse condense le pattern LLM Council de Karpathy en une seule commande :

### Etape 1 : Convocation

Trois agents sont generes **en parallele**, chacun avec une perspective differente :

| Agent | Role | Modele | Force |
|-------|------|--------|-------|
| Generaliste | Equilibre, pratique | Sonnet | Meilleures pratiques courantes |
| Critique | Adversarial, trouve les failles | Opus | Cas limites, risques, angles morts |
| Specialiste | Detail technique approfondi | Sonnet | Precision d'implementation |

Chaque agent repond **independamment** — ils ne peuvent pas voir les reponses des autres.

### Etape 2 : Notation

Le President (agent principal) anonymise toutes les reponses en Reponse A/B/C, puis note chacune sur 4 dimensions (0-10) :

- **Exactitude** — precision factuelle, solidite logique
- **Completude** — couverture de tous les aspects
- **Praticite** — applicabilite, pertinence dans le monde reel
- **Clarte** — structure, lisibilite

### Etape 3 : Synthese

La reponse la mieux notee devient le squelette. Les apports uniques des autres reponses sont integres. Les objections valides du critique sont conservees comme mises en garde.

---

## Cas d'utilisation

### Decisions d'architecture

```
/council-fuse Should we use microservices or a monolith for our 10-person team?
```

Le generaliste fournit une analyse equilibree des compromis, le critique remet en question le battage mediatique des microservices et le specialiste detaille les schemas de migration. La synthese fournit une recommandation conditionnelle.

### Choix technologiques

```
/council-fuse Redis vs PostgreSQL for our job queue
```

Trois angles differents garantissent que vous ne manquez pas les preoccupations operationnelles (critique), les details d'implementation (specialiste) ou l'option pragmatique par defaut (generaliste).

### Revue de code

```
/council-fuse Is this error handling pattern correct? <paste code>
```

Obtenez une validation conventionnelle, une analyse adversariale des cas limites et une verification technique approfondie en une seule passe.

---

## Structure de sortie

Chaque deliberation du conseil produit :

1. **Matrice de notation** — notation transparente des trois perspectives
2. **Analyse de consensus** — points d'accord et de desaccord
3. **Reponse synthetisee** — la meilleure reponse fusionnee
4. **Opinion minoritaire** — avis dissidents valides meritant attention

---

## Personnalisation

### Changer les perspectives

Editez `agents/*.md` pour definir des membres personnalises du conseil. Triades alternatives :

- Optimiste / Pessimiste / Pragmatique
- Architecte / Implementeur / Testeur
- Defenseur de l'utilisateur / Developpeur / Expert en securite

### Changer les modeles

Editez le champ `model:` dans chaque fichier d'agent :

- `model: haiku` — conseils economiques
- `model: opus` — tout en poids lourds pour les decisions critiques

---

## Plateformes

| Plateforme | Fonctionnement des membres du conseil |
|------------|---------------------------------------|
| Claude Code | 3 spawns independants d'Agent en parallele |
| OpenClaw | Agent unique, 3 tours de raisonnement independant sequentiel |

---

## FAQ

**Q : Est-ce que cela consomme 3 fois plus de tokens ?**
R : Oui, approximativement. Trois reponses independantes plus la synthese. Utilisez-le pour les decisions qui justifient l'investissement.

**Q : Puis-je ajouter plus de membres au conseil ?**
R : Le framework le supporte — ajoutez un autre fichier `agents/*.md` et mettez a jour le workflow dans SKILL.md. Cependant, 3 est le point optimal entre cout et diversite.

**Q : Que se passe-t-il si un agent echoue ?**
R : Le President attribue un score de 0 a ce membre et synthetise a partir des reponses restantes. Degradation elegante, sans plantage.
