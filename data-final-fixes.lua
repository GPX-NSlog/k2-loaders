if not settings.startup["k2-loaders-enabled"].value then
  return
end

require("prototypes.loaders").create_loaders({
  all_belts = settings.startup["k2-loaders-all-belts"].value,
  need_power = settings.startup["k2-loaders-need-power"].value,
})
