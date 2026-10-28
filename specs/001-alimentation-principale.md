# 001 — Alimentation par la fonderie principale

**Statut :** implémenté et testé localement — périmètre validé dans la conversation du 28 octobre 2026.

## Comportement attendu

Seul le bâtiment principal demande du courant. Les extensions augmentent la capacité
sans alimentation ni consommation supplémentaire. Une coupure suspend la production
et le recyclage ; le retour du courant reprend le travail sans perte de composants.
Le circuit et la réserve restent consultables pendant une coupure.

## Critères de validation

- Sans courant : aucun composant prélevé, aucune progression, aucun train créé ou recyclé.
- Avec courant sur le principal : production possible avec des extensions non alimentées.
- En cours de construction : coupure puis reprise sans perte ni duplication.
- Consommation du principal : 30 kW au repos et 450 kW supplémentaires en construction.
- Aucun avertissement électrique sur les extensions ; le principal signale la panne.
- Les parties existantes et les deux variantes conservent leur fonctionnement.

## Réalisation et validation

Un seul lot : alimentation, suspension/reprise, affichage et tests Factorio 2.1
sur les deux variantes, y compris le chargement d'une sauvegarde antérieure.

Vérifications réalisées sur Factorio 2.1.24 : scénario automatisé BP et STC,
contre-test sans la protection électrique et chargement d'une sauvegarde BP 1.4.3.
