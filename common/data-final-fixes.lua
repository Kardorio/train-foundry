if mods["space-exploration"] then
  local names = require("names")
  local source = assert(data.raw["straight-rail"]["se-space-straight-rail"],
    "Space Exploration space rail prototype is missing")

  local function space_rail(name, external)
    local rail = table.deepcopy(source)
    rail.name = name
    rail.minable = nil
    rail.next_upgrade = nil
    rail.fast_replaceable_group = nil
    rail.hidden_in_factoriopedia = true
    if external then
      rail.selectable_in_game = true
      rail.flags = { "not-blueprintable", "not-deconstructable", "not-upgradable",
                     "no-copy-paste" }
    else
      rail.hidden = true
      rail.selectable_in_game = false
      rail.flags = { "not-blueprintable", "not-deconstructable", "not-upgradable",
                     "no-copy-paste", "not-on-map", "hide-alt-info" }
    end
    return rail
  end

  data:extend({
    space_rail(names.rail_space, false),
    space_rail(names.rail_over_space, false),
    space_rail(names.rail_ext_space, true),
  })
end
