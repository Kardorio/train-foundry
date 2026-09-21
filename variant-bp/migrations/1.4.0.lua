if storage and storage.foundries then
  for _, state in pairs(storage.foundries) do
    state.blocker_zones = nil
    state.blocker_signature = nil
    state.blocker_layout_version = nil
  end
end
