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

local FILTER_COUNT = 5

---@param entity LuaEntity
---@return table
local function read_filters(entity)
  local filters = {}
  for index = 1, FILTER_COUNT do
    local filter = entity.get_filter(index)
    if filter then
      filters[index] = filter
    end
  end
  return filters
end

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

  local filters = read_filters(entity)

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
    created.set_filter(index, filter)
  end
end

script.on_configuration_changed(function()
  for legacy_name, new_name in pairs(LEGACY_NAMES) do
    -- A legacy prototype only exists if its belt tier exists, so never query
    -- entities by a name that this save's prototype list does not contain.
    if prototypes.entity[legacy_name] and prototypes.entity[new_name] then
      for _, surface in pairs(game.surfaces) do
        local entities = surface.find_entities_filtered({
          name = legacy_name,
          type = "loader-1x1",
        })
        for _, entity in pairs(entities) do
          local ok, err = pcall(migrate_loader, entity, new_name)
          if not ok then
            log("[k2-loaders] failed to migrate " .. legacy_name .. ": " .. tostring(err))
          end
        end
      end
    end
  end
end)
