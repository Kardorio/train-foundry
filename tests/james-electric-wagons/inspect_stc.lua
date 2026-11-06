
remote.add_interface("tf-jtm-test", {
  state = function(unit) return storage.foundries[unit] end,
  shape_err = function(names_)
    local slots = {}
    for i, name in ipairs(names_) do slots[i] = { name = name } end
    local shape, err = stc_template.shape_of({ slots = slots })
    return shape and "ok" or err
  end,
  locomotive_for = function(wagon) return stc_template.locomotive_for(wagon) end,
  -- Pose un modèle STC par défaut (loco choisie par la fonderie + N wagons).
  spawn_default = function(unit, wagon, n)
    local t, err = stc_template.build({ kind = "item", wagon_type = wagon,
      wagon_quality = "normal", wagons = n, group = "", storage = false })
    if not t then return err end
    local st = storage.foundries[unit]
    local ok, e, detail = builder.try_spawn(st, t, nil, true)
    return ok and "spawn-ok" or (e .. (detail and (" | " .. detail) or ""))
  end,
  -- Pose une composition custom (flip = loco tournée vers l'est).
  spawn_custom = function(unit, slots)
    local t, err = stc_template.build_custom({ id = 1, slots = slots })
    if not t then return err end
    local ok, e, detail = builder.try_spawn(storage.foundries[unit], t, nil, true)
    return ok and "spawn-ok" or (e .. (detail and (" | " .. detail) or ""))
  end,
})
