-- Train Foundry (variante BP) — prototypes SPÉCIFIQUES à la variante blueprint.
--
-- Seule différence de data stage vs la variante STC : le COFFRE À BLUEPRINTS.
-- Le bâtiment, l'item, la recette, la techno et les enfants communs sont dans
-- common/data-common.lua.

local names = require("names")

-- Coffre à BLUEPRINTS : vrai coffre visible sur le parvis, filtré blueprints.
-- Le joueur y dépose ses plans de trains ; le livre de la fenêtre lit ce coffre.
-- Rendu BLEU pour le distinguer de la réserve grise.
local bpchest = table.deepcopy(data.raw["container"]["iron-chest"])
bpchest.name = names.bpchest
bpchest.minable = nil
bpchest.next_upgrade = nil
bpchest.fast_replaceable_group = nil
bpchest.flags = { "not-blueprintable", "not-deconstructable", "not-upgradable",
                  "no-copy-paste", "player-creation" }
bpchest.inventory_size = 50
bpchest.inventory_type = "with_filters_and_bar"
bpchest.circuit_wire_max_distance = 0
bpchest.hidden_in_factoriopedia = true
bpchest.selection_priority = 100
bpchest.picture = {
  filename = "__train-foundry__/graphics/foundry-bpchest-v1.png",
  priority = "extra-high",
  width = 63,
  height = 72,
  shift = { 0, -0.15 },
}
if mods["space-exploration"] then bpchest.se_allow_in_space = true end

data:extend({ bpchest })
