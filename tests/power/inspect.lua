remote.add_interface("tf-power-test", {
  state = function(unit) return storage.foundries[unit] end,
  request_extension = function(unit)
    request_extension(game.get_player(1), storage.foundries[unit])
  end,
  queue = function(unit)
    local stock = {}
    for i = 1, 6 do stock[i] = { name = "cargo-wagon", orientation = 0.75 } end
    storage.foundries[unit].queue = {
      { name = "Power test", template = { name = "Power test", stock = stock } },
    }
  end,
  recycle = function(unit)
    local st = storage.foundries[unit]
    st.deco, st.deco_left, st.deco_right = true, true, false
    refresh_chain_track(st)
  end,
})
