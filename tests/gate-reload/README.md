# Régression : train bloqué dans une porte au rechargement

Le scénario pose une fonderie et un train automatique de trois véhicules, puis
sauvegarde lorsque le premier wagon traverse la porte. Il recharge cette partie
avec et sans changement de configuration et vérifie que le train sort, puis que
les portes se referment. Le changement de version du mod de test force la
reconstruction des portes qui reproduit le blocage.

Le test utilise Factorio 2.1 en mode headless, un serveur sur localhost et des
dossiers temporaires. Les mods installés et les sauvegardes du joueur ne sont
pas modifiés. Les paquets sont produits par `build.sh` dans le dossier temporaire.

```sh
python3 tests/gate-reload/run.py \
  --factorio /chemin/vers/Factorio/bin/x64/factorio \
  --data /chemin/vers/Factorio/data
```

Pour STC, ajouter la variante et les dépendances locales (dossiers ou archives) :

```sh
python3 tests/gate-reload/run.py \
  --factorio /chemin/vers/Factorio/bin/x64/factorio \
  --data /chemin/vers/Factorio/data \
  --variant stc \
  --dependency /chemin/vers/smart-train-combinator \
  --dependency /chemin/vers/flib_0.17.2.zip
```

Le convoi est créé par le scénario pour isoler le franchissement des portes ;
ce test ne couvre pas l'import du blueprint ni la consommation des composants.
