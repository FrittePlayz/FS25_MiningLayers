# Mining Layers (FS25)

[![Buy me fries](https://img.shields.io/badge/Buy%20me%20fries-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/fritteplayz)
[![Latest release](https://img.shields.io/github/v/release/FrittePlayz/FS25_MiningLayers?style=for-the-badge&color=2d8a4e)](https://github.com/FrittePlayz/FS25_MiningLayers/releases)
[![Langues](https://img.shields.io/badge/en--jeu-FR%20·%20EN%20·%20DE%20·%20PL-2d8a4e?style=for-the-badge)](#)

![Mining Layers — le matériau dépend de la profondeur, ou crée ta propre gravière](docs/images/00_header.jpg)

**Du vrai gameplay minier pour Farming Simulator 25 — creuse à travers des couches géologiques, ou crée ta propre gravière dans FS25.**
Le matériau dans ton godet dépend de la profondeur, pas d'un menu déroulant : terre végétale d'abord, puis gravier, puis le filon, socle rocheux en bas. Depuis la 1.4.0 le filon est sélectionnable — mine de charbon, gravière ou carrière de calcaire, sur n'importe quelle carte, sans édition de carte. **Le mod et son manuel en jeu existent intégralement en français** (traduction automatique — corrections bienvenues !).

🇬🇧 [English](README.md) · 🇩🇪 [Deutsch](README.de.md) · 🇵🇱 [Polski](README.pl.md) — *page FR compacte ; la documentation détaillée vit dans la version anglaise, le manuel complet est en jeu, en français.*

---

## Prérequis

- **[TerraFarm](https://github.com/scfmod/FS25_TerraFarm)** de scfmod — disponible sur GitHub uniquement. Ne renomme pas son dossier : il doit rester `FS25_0_TerraFarm` (ordre de chargement).
- Au moins **une machine avec une configuration TerraFarm** (par ex. l'officiel `FS25_TerraFarmMachines`).
- **PC ou Mac uniquement** — mod script, les consoles ne les acceptent pas.

Addon non officiel, aucune affiliation avec scfmod ni GIANTS. Aucun fichier TerraFarm n'est livré.

## Installation

1. Télécharge TerraFarm (lien ci-dessus).
2. Télécharge `FS25_MiningLayers.zip` depuis les [releases](https://github.com/FrittePlayz/FS25_MiningLayers/releases).
3. Mets les deux ZIP — tels quels, sans les décompresser — dans ton dossier mods :
   `Documents\My Games\FarmingSimulator2025\mods\`
4. Active les DEUX mods dans la sélection de mods de ta sauvegarde.

## Première fosse en une étape

Trace une zone TerraFarm (polygone) autour de ta future fosse et **laisse les champs de matériau vides**. C'est tout : creuse n'importe où dans la zone et le matériau vient de la profondeur. La hauteur de référence se calcule toute seule à partir du contour.

Réglages et couches : menu ESC → Mining Layers. Le manuel complet y est aussi, en français.

## Géologie personnalisée — gravière, mine de charbon

Depuis la 1.4.0, le filon se choisit dans l'éditeur (ESC → Mining Layers → Couches) : le filon est la dernière ligne, fixe — prends COAL pour une mine de charbon, LIMESTONE ou STONE pour une gravière, ou GRAVEL, SAND, DIRT, SOIL. PAYDIRT reste la valeur par défaut. Le socle rocheux en dessous termine la fosse — c'est voulu.

À savoir : COAL et LIMESTONE ne sont pas des matériaux du jeu de base — ta carte ou un mod minier doit les fournir (les cartes RGC comme Yukon Back Country les ont).

## Épaisseur des couches

Au moins 1,5 m par couche (l'éditeur impose 1 m pour la couche du haut, 1,5 m en dessous) — plus fin, la reprise des tas casse. **Avec de grosses machines type PC 8000, 2 m par couche tourne nettement mieux.**

## FAQ

**Mining Layers fonctionne-t-il sur n'importe quelle carte ?**
Oui. Aucune édition de carte : trace une zone TerraFarm autour de ta fosse et creuse. Pour les textures, le mod prend automatiquement le sol le plus proche que la carte propose ; si rien ne convient, ta propre sélection reste simplement active.

**Faut-il une nouvelle sauvegarde ?**
Non. Mining Layers fonctionne avec les sauvegardes existantes — installe, active les deux mods dans ta sauvegarde et continue de jouer. Les zones TerraFarm existantes continuent de fonctionner ; les zones sans matériau renseigné reçoivent simplement des couches.

**Comment faire une gravière dans FS25 ?**
Installe TerraFarm et Mining Layers, trace une zone, puis menu ESC → Mining Layers → Couches : DIRT en haut, LIMESTONE ou STONE comme filon. Depuis la 1.4.0, tout se règle dans l'éditeur — sans XML.

**Comment extraire du charbon dans FS25 ?**
Choisis COAL comme filon dans l'éditeur. Attention : COAL n'est pas un matériau du jeu de base — ta carte ou un mod minier doit le fournir.

**Pourquoi ma pelle ne creuse-t-elle pas ?**
TerraFarm a besoin d'une configuration machine pour ce véhicule — sans elle, rien ne se passe (ce n'est pas un problème de Mining Layers). Installe un pack de configs comme FS25_TerraFarmMachines, et évite les entrées en double venant de plusieurs packs.

**Pourquoi j'obtiens toujours le même matériau, quelle que soit la profondeur ?**
Un matériau est renseigné sur ta zone TerraFarm — la zone passe alors en TerraFarm classique sans couches (voulu, pour les chantiers). Laisse les champs de matériau vides et les couches prennent le relais.

**Jusqu'où peut-on creuser ?**
Jusqu'au socle rocheux sous ta couche la plus profonde — là, ça s'arrête volontairement. C'est ce qui en fait du minage et pas un trou à argent sans fond.

**Quelle épaisseur pour mes couches ?**
Au moins 1,5 m (l'éditeur impose 1 m en haut, 1,5 m en dessous). Avec de grosses machines type PC 8000, 2 m par couche creuse nettement mieux.

**Y a-t-il une limite de tas — combien puis-je déverser ?**
Non. Le matériau déversé devient du vrai terrain via TerraFarm, pas un tas du jeu de base — aucune limite de capacité ne s'applique. La mémoire des tas est une grille de 2 m par sauvegarde, sans plafond de nombre ni de taille. À savoir : chaque cellule de 2 m retient UN matériau (le dernier déversement gagne) — ne mélange pas les matériaux au même endroit si tu veux les récupérer séparément.

**Comment masquer (ou réafficher) l'affichage de profondeur ?**
Appuie sur **Pavé num. 5** quand une machine est active (depuis la 1.4.1). Touche réassignable : Options → Commandes → Mining Layers. Pour démarrer sans affichage : `showHeightDisplay="false"` dans `modSettings/FS25_MiningLayers/miningLayers.xml`.

**Puis-je déplacer l'affichage pour éviter les conflits avec d'autres HUD ?**
Oui. Règle `displayPosX` / `displayPosY` dans `modSettings/FS25_MiningLayers/miningLayers.xml` (fractions d'écran, `0 0` = bas gauche ; défaut `0.012` / `0.55`). Aucun mod HUD supplémentaire nécessaire.

**Ça tourne sur PS5 ou Xbox ?**
Non. Mining Layers est un mod script, et les mods script ne tournent que sur PC/Mac.

**Quelles langues sont disponibles ?**
Français, anglais, allemand et polonais — manuel en jeu complet inclus.

**C'est vraiment gratuit ?**
Oui. Téléchargement gratuit sur GitHub, pas de paywall, pas d'accès anticipé. Pour dire merci : [offre-moi des frites](https://buymeacoffee.com/fritteplayz). 🍟

## Traduction

Cette page et les textes en jeu FR sont traduits automatiquement — les corrections de francophones sont très bienvenues : ouvre une [issue](https://github.com/FrittePlayz/FS25_MiningLayers/issues) ou une pull request (les fichiers de langue sont du simple XML dans `l10n/`), et tu seras crédité.

## Bugs et questions

[GitHub Issues](https://github.com/FrittePlayz/FS25_MiningLayers/issues) — joins ton `log.txt` et le nom de la carte.

## Sponsor

Ce mod est soutenu par [farmersingles.de](https://www.farmersingles.de), un site de rencontre pour agriculteurs — d'où le petit panneau au coin de chaque zone. `sponsorSign="false"` dans `miningLayers.xml` et il disparaît ; rien d'autre ne change.

*Mining Layers par Tommy Honold, Farmersingles.de. Un projet [FrittePlayz](https://www.youtube.com/@FrittePlayz). Gratuit, et ça le restera.*
