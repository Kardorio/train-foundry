# Alimentation de la fonderie principale

Le scénario Factorio 2.1 vérifie l'arrêt sans courant, la construction d'un train
de six véhicules avec une extension non alimentée, la coupure et la reprise sans
perte de composants, l'impossibilité d'alimenter uniquement l'extension, le recyclage
uniquement sous tension et la suppression du consommateur avec la fonderie.

```sh
python3 tests/power/run.py \
  --factorio /chemin/vers/Factorio/bin/x64/factorio \
  --data /chemin/vers/Factorio/data
```

Pour STC, ajouter `--variant stc`, puis `--dependency` pour le dossier ou le ZIP de
Smart Train Combinator et celui de flib.

Le test construit les deux paquets avec `build.sh` dans un dossier temporaire,
puis ajoute `inspect.lua` exclusivement au paquet temporaire testé pour observer
le travail et préparer la file. Le scénario exerce la vraie boucle de production.
Les mods installés et les sauvegardes du joueur ne sont pas modifiés.
