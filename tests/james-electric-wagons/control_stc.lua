-- Variante STC : les compositions ne passent par aucun train réel, la fonderie
-- applique donc elle-même la règle de James (wagon électrique ⇒ loco électrique
-- ou hybride), choisit une loco hybride pour les modèles par défaut à wagons
-- électriques et construit ces trains sans rien rejeter au sol.

local function call(fn, ...) return remote.call("tf-jtm-test", fn, ...) end

local function setup()
  local surface = game.surfaces[1]
  surface.request_to_generate_chunks({ 0, 0 }, 4)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered({
      type = { "tree", "simple-entity", "cliff" } })) do entity.destroy() end
  local tiles = {}
  for x = -100, 100 do
    for y = -20, 20 do tiles[#tiles + 1] = { name = "grass-1", position = { x, y } } end
  end
  surface.set_tiles(tiles)
  game.forces.player.research_all_technologies()
  for x = -99, -23, 2 do
    assert(surface.create_entity({ name = "straight-rail", position = { x, 5 },
      direction = defines.direction.east, force = "player" }))
  end
  storage.main = assert(surface.create_entity({ name = "tfstc-foundry",
    position = { 0, 0 }, force = "player", raise_built = true }))
end

local function check(label, got, expected)
  assert(got == expected, label .. " : " .. tostring(got) .. " au lieu de " .. tostring(expected))
end

local function check_train(label, count)
  local surface = game.surfaces[1]
  local spilled = surface.count_entities_filtered({ name = "item-on-ground" })
  check(label .. " (objets au sol)", spilled, 0)
  local vehicles = surface.find_entities_filtered({ type = { "locomotive", "cargo-wagon" } })
  check(label .. " (véhicules)", #vehicles, count)
  check(label .. " (un seul train)", #vehicles[1].train.carriages, count)
  for _, v in pairs(vehicles) do v.destroy() end
end

local function stock(items)
  local input = call("state", storage.main.unit_number).input
    .get_inventory(defines.inventory.chest)
  input.clear()
  for name, n in pairs(items) do input.insert({ name = name, count = n }) end
  -- Carburant générique : seul un carburant produit par une recette débloquée
  -- est retenu (voir setup).
  input.insert({ name = "rocket-fuel", count = 500 })
end

script.on_event(defines.events.on_tick, function(event)
  if event.tick == 1 then setup() end
  if event.tick ~= 60 then return end
  local un = storage.main.unit_number
  local EW1, EW3 = "cargo-wagon-electric-1", "cargo-wagon-electric-3"

  -- Validation des compositions custom.
  check("loco vanilla + wagon électrique", call("shape_err", { "locomotive", EW1 }),
    "jtm-electric-wagon")
  check("hybride + wagon électrique", call("shape_err", { "james-hybrid-train", EW1 }), "ok")
  check("loco vanilla + wagon vanilla", call("shape_err", { "locomotive", "cargo-wagon" }), "ok")

  -- Loco des modèles par défaut.
  check("loco du wagon électrique 1", call("locomotive_for", EW1), "james-hybrid-train")
  check("loco du wagon électrique 3", call("locomotive_for", EW3), "james-hybrid-train-3")
  check("loco du wagon vanilla", call("locomotive_for", "cargo-wagon"), "locomotive")

  -- Modèle par défaut à wagons électriques : construit en entier.
  stock({ ["james-hybrid-train-3"] = 1, [EW3] = 2 })
  check("modèle par défaut", call("spawn_default", un, EW3, 2), "spawn-ok")
  check_train("modèle par défaut", 3)

  -- Custom, loco hybride en queue à contre-sens.
  stock({ ["james-hybrid-train"] = 1, [EW1] = 2 })
  check("custom loco en queue", call("spawn_custom", un, {
    { name = EW1 }, { name = EW1 }, { name = "james-hybrid-train", flip = true } }),
    "spawn-ok")
  check_train("custom loco en queue", 3)

  -- Custom interdit : refusé avant toute consommation.
  check("custom interdit", call("spawn_custom", un, {
    { name = "locomotive" }, { name = EW1 } }), "jtm-electric-wagon")

  log("JTM_TEST_OK")
  script.finish_test(true)
end)
