require("scripts.loader-snapping")

-- Older versions of this mod named the loaders k2-*, while Krastorio 2 uses
-- kr-* (and so does this mod from 1.0.2 on). Convert leftovers when the mod is
-- added to or updated in an existing save so nothing disappears.
local LEGACY_NAMES = {
  ["k2-loader"] = "kr-loader",
  ["k2-fast-loader"] = "kr-fast-loader",
  ["k2-express-loader"] = "kr-express-loader",
  ["k2-turbo-loader"] = "kr-advanced-loader",
  ["k2-ultimate-loader"] = "kr-superior-loader",
}

local function migrate_loader(entity, new_name)
  if not entity.valid then
    return
  end

  local surface = entity.surface
  local position = entity.position
  local direction = entity.direction
  local force = entity.force
  local quality = entity.quality
  local health = entity.health

  local filters = {}
  for index = 1, entity.filter_count or 0 do
    local ok, filter = pcall(entity.get_filter, entity, index)
    if ok and filter then
      filters[index] = filter
    end
  end

  entity.destroy()

  local created = surface.create_entity({
    name = new_name,
    position = position,
    direction = direction,
    force = force,
    quality = quality,
    create_build_effect_smoke = false,
  })
  if not created then
    return
  end

  if health and created.health then
    created.health = math.min(health, created.max_health)
  end

  for index, filter in pairs(filters) do
    pcall(created.set_filter, created, index, filter)
  end
end

script.on_configuration_changed(function()
  for legacy_name, new_name in pairs(LEGACY_NAMES) do
    for _, surface in pairs(game.surfaces) do
      local entities = surface.find_entities_filtered({
        name = legacy_name,
        type = "loader-1x1",
      })
      for _, entity in pairs(entities) do
        migrate_loader(entity, new_name)
      end
    end
  end
end)
