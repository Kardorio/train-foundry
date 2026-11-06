# Wagons électriques de James' Electric Trains Plus

James' Electric Trains Plus détruit, dans son handler `script_raised_built`, tout
wagon électrique dont le train n'a pas de locomotive électrique ou hybride. Le test
vérifie que la fonderie construit des trains complets avec une loco hybride en tête,
en queue, au milieu ou aux deux bouts, sans wagon rejeté au sol.

Variante STC (`--variant stc`, plus `--dependency` pour Smart Train Combinator et
flib) : les compositions ne passent par aucun train réel, la fonderie applique donc
la règle de James elle-même. Le test vérifie le refus d'une composition custom à
wagons électriques sans loco électrique ou hybride, le choix d'une loco hybride au
même tier pour les modèles par défaut, et la construction complète de ces trains.

```sh
python3 tests/james-electric-wagons/run.py \
  --factorio /chemin/vers/Factorio/bin/x64/factorio \
  --data /chemin/vers/Factorio/data \
  --dependency /chemin/vers/James-Train-Mod_2.1.0.zip \
  --dependency /chemin/vers/LSlib_James_Fork_2026.10.10.zip
```
