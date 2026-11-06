-- Wagons électriques de James' Electric Trains Plus : ce mod détruit, dans son
-- handler de construction, tout wagon électrique dont le train n'a pas de loco
-- électrique/hybride. La fonderie doit donc créer chaque wagon déjà attelé à une
-- loco, quelle que soit la place de la loco dans le template.

local LOCO, WAGON = "james-hybrid-train", "cargo-wagon-electric-1"

local CASES = {
  { name = "loco en queue",   stock = { WAGON, WAGON, LOCO } },
  { name = "loco en tête",    stock = { LOCO, WAGON, WAGON } },
  { name = "loco au milieu",  stock = { WAGON, LOCO, WAGON } },
  { name = "deux locos",      stock = { LOCO, WAGON, WAGON, LOCO } },
}

local function state()
  return remote.call("tf-jtm-test", "state", storage.main.unit_number)
end

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
  for x = -99, -23, 2 do
    assert(surface.create_entity({ name = "straight-rail", position = { x, 5 },
      direction = defines.direction.east, force = "player" }))
  end
  storage.main = assert(surface.create_entity({ name = "train-foundry",
    position = { 0, 0 }, force = "player", raise_built = true }))
  local source = assert(surface.create_entity({ name = "electric-energy-interface",
    position = { -25, -2 }, force = "player" }))
  source.power_production = 1000000000 / 60
  assert(surface.create_entity({ name = "medium-electric-pole",
    position = { -25, -4 }, force = "player" }))
end

local function run_case(case)
  local surface = game.surfaces[1]
  local input = state().input.get_inventory(defines.inventory.chest)
  input.clear()
  local counts = {}
  for _, name in ipairs(case.stock) do counts[name] = (counts[name] or 0) + 1 end
  for name, n in pairs(counts) do input.insert({ name = name, count = n }) end
  input.insert({ name = "coal", count = 200 })
  remote.call("tf-jtm-test", "set_template", storage.main.unit_number, case.stock)
  local result = remote.call("train-foundry", "spawn_template", storage.main.unit_number, 1)
  assert(result:find("^spawn%-ok"),
    case.name .. " : " .. tostring(result))
  local spilled = surface.count_entities_filtered({ name = "item-on-ground" })
  assert(spilled == 0, case.name .. " : " .. spilled .. " wagon(s) rejeté(s) au sol")
  local trains = {}
  for _, v in pairs(surface.find_entities_filtered({
      type = { "locomotive", "cargo-wagon" } })) do
    trains[v.train.id] = v.train
  end
  local n, train = 0, nil
  for _, t in pairs(trains) do n, train = n + 1, t end
  assert(n == 1, case.name .. " : " .. n .. " trains au lieu d'un")
  assert(#train.carriages == #case.stock, case.name .. " : " .. #train.carriages
    .. " véhicules au lieu de " .. #case.stock)
  for _, v in pairs(train.carriages) do v.destroy() end
end

script.on_event(defines.events.on_tick, function(event)
  if event.tick == 1 then setup() end
  if event.tick == 60 then
    for _, case in ipairs(CASES) do run_case(case) end
    log("JTM_TEST_OK")
    script.finish_test(true)
  end
end)
