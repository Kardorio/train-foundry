
remote.add_interface("tf-jtm-test", {
  state = function(unit) return storage.foundries[unit] end,
  set_template = function(unit, names)
    local stock = {}
    for i, name in ipairs(names) do stock[i] = { name = name, orientation = 0.75 } end
    storage.foundries[unit].templates = { { name = "JTM test", stock = stock } }
  end,
})
