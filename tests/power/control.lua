local stc = script.active_mods["train-foundry-stc"] ~= nil
local building = stc and "tfstc-foundry" or "train-foundry"
local power_name = stc and "tfstc-power" or "tf-power"

local function state()
  return remote.call("tf-power-test", "state", storage.main.unit_number)
end

local function supply(position)
  local source = assert(game.surfaces[1].create_entity({
    name = "electric-energy-interface", position = position, force = "player",
  }))
  source.power_production = 1000000000 / 60
  return source
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
  storage.main = assert(surface.create_entity({ name = building, position = { 0, 0 },
    force = "player", raise_built = true }))
  storage.extension = assert(surface.create_entity({ name = building, position = { 36, 0 },
    force = "player" }))
  script.raise_script_built({ entity = storage.extension,
    tags = { tf_extension_master = storage.main.unit_number } })
  assert(#state().extensions == 1, "Extension was not attached")
  assert(surface.count_entities_filtered({ name = power_name }) == 1,
    "Only the main foundry may consume electricity")
  state().input.insert({ name = "cargo-wagon", count = 6 })
  remote.call("tf-power-test", "queue", storage.main.unit_number)
end

script.on_event(defines.events.on_tick, function(event)
  local tick = event.tick
  if tick == 1 then setup() end
  if tick == 60 then
    local st = state()
    assert(not st.power_available and not st.work and #st.queue == 1,
      "Production started without electricity")
    assert(st.input.get_item_count("cargo-wagon") == 6,
      "Components were consumed without electricity")
    assert(game.surfaces[1].create_entity({ name = "medium-electric-pole",
      position = { -25, -2 }, force = "player" }))
    storage.source = supply({ -25, -2 })
  end
  if tick == 180 then
    local st = state()
    assert(st.work and st.work.phase == "building" and st.work.progress > 0,
      "Powered main foundry did not build with an unpowered extension")
    assert(st.input.get_item_count("cargo-wagon") == 0, "Components not consumed")
    storage.source.destroy()
    assert(game.surfaces[1].create_entity({ name = "medium-electric-pole",
      position = { 36, -2 }, force = "player" }))
    storage.extension_source = supply({ 36, -2 })
  end
  if tick == 270 then
    local st = state()
    assert(not st.power_available, "Powering only the extension powered the main foundry")
    storage.paused_progress = st.work.progress
  end
  if tick == 390 then
    local st = state()
    assert(st.work.progress == storage.paused_progress, "Work progressed during a power cut")
    assert(st.input.get_item_count("cargo-wagon") == 0, "Paid components were refunded")
    storage.source = supply({ -25, -2 })
  end
  if tick == 510 then
    assert(state().work.progress > storage.paused_progress, "Work did not resume")
  end
  if tick == 2100 then
    assert(not state().work and #state().queue == 0, "Work did not finish")
    assert(game.surfaces[1].count_entities_filtered({ type = "cargo-wagon" }) == 6,
      "Incorrect finished train or duplicate production")
    assert(state().input.get_item_count("cargo-wagon") == 0, "Unexpected refund")
    for _, entity in pairs(game.surfaces[1].find_entities_filtered({ type = "cargo-wagon" })) do
      entity.destroy()
    end
    remote.call("tf-power-test", "recycle", storage.main.unit_number)
    storage.source.destroy()
    state().power.energy = 0
    local surface = game.surfaces[1]
    storage.recycle_loco = assert(surface.create_entity({ name = "locomotive",
      position = { 0, 1 }, direction = defines.direction.east, force = "player" }))
    assert(surface.create_entity({ name = "cargo-wagon", position = { -7, 1 },
      direction = defines.direction.east, force = "player" }))
    storage.recycle_loco.insert({ name = "coal", count = 50 })
    local stop = state().recycle_stops[1]
    assert(stop and stop.valid and stop.connected_rail, "Recycle station disconnected")
    storage.recycle_loco.train.schedule = { current = 1, records = {
      { station = stop.backer_name, wait_conditions = {
        { type = "time", ticks = 3600, compare_type = "and" },
      } },
    } }
    storage.recycle_loco.train.manual_mode = false
    assert(storage.recycle_loco.train.has_path, "No path to recycle station")
  end
  if tick == 2700 then
    assert(storage.recycle_loco.valid, "Train recycled without electricity")
    assert(storage.recycle_loco.train.state == defines.train_state.wait_station,
      "Recycle train did not reach its station")
    storage.source = supply({ -25, -2 })
  end
  if tick == 2790 then
    assert(not storage.recycle_loco.valid, "Train not recycled when power returned")
    assert(state().input.get_item_count("cargo-wagon") == 1, "Recycled wagon not refunded")
    assert(state().input.get_item_count("locomotive") == 1, "Recycled locomotive not refunded")
    storage.main.destroy({ raise_destroy = true })
    assert(game.surfaces[1].count_entities_filtered({ name = power_name }) == 0,
      "Orphan electric consumer after removing the main foundry")
    log("POWER_TEST_OK")
    script.finish_test(true)
  end
end)
