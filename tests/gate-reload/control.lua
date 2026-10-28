local stc = script.active_mods["train-foundry-stc"] ~= nil
local building = stc and "tfstc-foundry" or "train-foundry"
local gate_name = stc and "tfstc-gate" or "tf-gate"

local function setup()
  local surface = game.surfaces[1]
  surface.request_to_generate_chunks({ 0, 0 }, 3)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered({
      type = { "tree", "simple-entity", "cliff" } })) do
    entity.destroy()
  end
  local tiles = {}
  for x = -100, 100 do
    for y = -20, 20 do
      tiles[#tiles + 1] = { name = "grass-1", position = { x, y } }
    end
  end
  surface.set_tiles(tiles)
  for x = -99, -23, 2 do
    assert(surface.create_entity({ name = "straight-rail", position = { x, 5 },
      direction = defines.direction.east, force = "player" }))
  end
  assert(surface.create_entity({ name = building, position = { 0, 0 },
    force = "player", raise_built = true }))
  storage.gates = surface.find_entities_filtered({ name = gate_name })
  assert(#storage.gates == 2, "Expected two foundry gates")

  storage.loco = assert(surface.create_entity({ name = "locomotive",
    position = { -12, 5 }, direction = defines.direction.west, force = "player" }))
  storage.wagon = assert(surface.create_entity({ name = "cargo-wagon",
    position = { -5, 5 }, direction = defines.direction.west, force = "player" }))
  assert(surface.create_entity({ name = "cargo-wagon", position = { 2, 5 },
    direction = defines.direction.west, force = "player" }))
  assert(#storage.loco.train.carriages == 3, "Expected a coupled train")
  storage.loco.insert({ name = "coal", count = 50 })
  local stop = assert(surface.create_entity({ name = "train-stop",
    position = { -81, 3 }, direction = defines.direction.west, force = "player" }))
  assert(stop.connected_rail, "Station must be attached to the railway")
  stop.backer_name = "Destination"
  storage.loco.train.schedule = { current = 1, records = {
    { station = "Destination", wait_conditions = {
      { type = "time", ticks = 3600, compare_type = "and" },
    } },
  } }
  storage.loco.train.manual_mode = false
  assert(storage.loco.train.has_path, "Train must have a route out of the foundry")
end

script.on_event(defines.events.on_tick, function(event)
  if event.tick == 1 then setup() end
  if event.tick < 1 then return end
  local loco = storage.loco
  if not storage.saved_tick and storage.wagon.position.x < -17.8 then
    assert(storage.gates[1].is_opened(), "Gate must be open when saving")
    storage.saved_tick = event.tick
    game.server_save("gate-crossing")
  end
  if event.tick >= 900 then
    assert(storage.saved_tick, "Train never reached the gate")
    assert(loco.position.x < -50, "Train remained trapped in the foundry gate")
    for _, gate in pairs(game.surfaces[1].find_entities_filtered({ name = gate_name })) do
      assert(gate.is_closed(), "Empty gates must close after the train departs")
    end
    log("GATE_RELOAD_OK")
    script.finish_test(true)
  end
end)
