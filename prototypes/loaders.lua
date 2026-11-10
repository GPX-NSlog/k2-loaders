local graphics = require("prototypes.loader-graphics")
local sounds = require("__base__.prototypes.entity.sounds")

local loaders = {}

local FIXED_TIERS = {
  ["transport-belt"] = {
    name = "k2-loader",
    icon = "__k2-loaders__/graphics/icons/loader.png",
    tint = { 249, 207, 70 },
    drain = "400W",
  },
  ["fast-transport-belt"] = {
    name = "k2-fast-loader",
    icon = "__k2-loaders__/graphics/icons/fast-loader.png",
    tint = { 228, 24, 38 },
    drain = "500W",
  },
  ["express-transport-belt"] = {
    name = "k2-express-loader",
    icon = "__k2-loaders__/graphics/icons/express-loader.png",
    tint = { 90, 190, 220 },
    drain = "500W",
  },
  ["turbo-transport-belt"] = {
    name = "k2-turbo-loader",
    icon = "__k2-loaders__/graphics/icons/advanced-loader.png",
    tint = { 76, 232, 48 },
    drain = "1kW",
  },
  ["ultimate-transport-belt"] = {
    name = "k2-ultimate-loader",
    icon = "__k2-loaders__/graphics/icons/superior-loader.png",
    tint = { 151, 34, 191 },
    drain = "1.5kW",
  },
}

local BASE_BELTS = {
  ["transport-belt"] = true,
  ["fast-transport-belt"] = true,
  ["express-transport-belt"] = true,
  ["turbo-transport-belt"] = true,
}

local EXTRA_TINTS = {
  { 255, 140, 0 },
  { 0, 190, 190 },
  { 255, 80, 200 },
  { 220, 220, 220 },
  { 130, 130, 255 },
  { 180, 100, 255 },
  { 100, 220, 100 },
  { 255, 210, 120 },
}

local FALLBACK_ICON = "__k2-loaders__/graphics/icons/loader.png"

---Convert a 0-255 RGB tint into a proper Color table.
---@param tint number[]
---@return data.Color
local function make_color(tint)
  return { r = tint[1] / 255, g = tint[2] / 255, b = tint[3] / 255, a = 1 }
end

---@param belt data.TransportBeltPrototype
---@return data.ItemPrototype?
local function find_belt_item(belt)
  local direct = data.raw["item"][belt.name]
  if direct and direct.place_result == belt.name then
    return direct
  end

  local placeable_by = belt.placeable_by
  if placeable_by then
    if placeable_by.item and data.raw["item"][placeable_by.item] then
      return data.raw["item"][placeable_by.item]
    elseif placeable_by[1] and placeable_by[1].item and data.raw["item"][placeable_by[1].item] then
      return data.raw["item"][placeable_by[1].item]
    end
  end

  for _, item in pairs(data.raw["item"]) do
    if item.place_result == belt.name then
      return item
    end
  end
end

---@param item_name string
---@return data.RecipePrototype?
local function find_recipe_for_item(item_name)
  local direct = data.raw["recipe"][item_name]
  if direct then
    return direct
  end

  for _, recipe in pairs(data.raw["recipe"]) do
    if recipe.results then
      for _, result in pairs(recipe.results) do
        if result.name == item_name then
          return recipe
        end
      end
    end
  end
end

---@param recipe_name string
---@return data.TechnologyPrototype?
local function find_technology_for_recipe(recipe_name)
  for _, technology in pairs(data.raw["technology"]) do
    if technology.effects then
      for _, effect in pairs(technology.effects) do
        if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
          return technology
        end
      end
    end
  end
end

---@param technology data.TechnologyPrototype
---@param recipe_name string
local function add_recipe_unlock(technology, recipe_name)
  technology.effects = technology.effects or {}
  for _, effect in pairs(technology.effects) do
    if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
      return
    end
  end
  table.insert(technology.effects, { type = "unlock-recipe", recipe = recipe_name })
end

---Turn a belt name into a stable suffix for loader names.
---@param belt_name string
---@param rank integer
---@param used table<string, boolean>
---@return string
local function make_extra_loader_name(belt_name, rank, used)
  local base = belt_name:gsub("%-transport%-belt$", ""):gsub("transport%-belt$", "")
  base = base:gsub("[^%w%-]", "-"):gsub("%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
  if base == "" then
    base = "tier-" .. rank
  end

  local name = "k2-loader-" .. base
  if used[name] then
    name = name .. "-" .. rank
  end
  return name
end

---@param rank integer
---@return data.Ingredient[]
local function make_ingredients(rank, belt_item_name, previous_loader)
  local ingredients = {
    { type = "item", name = belt_item_name, amount = 1 },
  }

  if rank == 1 then
    ingredients[#ingredients + 1] = { type = "item", name = "iron-gear-wheel", amount = 10 }
    ingredients[#ingredients + 1] = { type = "item", name = "iron-plate", amount = 4 }
  else
    if previous_loader then
      ingredients[#ingredients + 1] = { type = "item", name = previous_loader, amount = 2 }
    end
    if rank >= 3 and data.raw["item"]["steel-gear-wheel"] then
      ingredients[#ingredients + 1] = { type = "item", name = "steel-gear-wheel", amount = 10 }
    elseif rank >= 3 then
      ingredients[#ingredients + 1] = { type = "item", name = "steel-plate", amount = 10 }
    else
      ingredients[#ingredients + 1] = { type = "item", name = "iron-gear-wheel", amount = 10 }
    end
  end

  return ingredients
end

---@param belt data.TransportBeltPrototype
---@return boolean
local function is_usable_belt(belt)
  if belt.hidden or not belt.speed or belt.speed <= 0 then
    return false
  end
  if string.match(belt.name, "^k2%-") then
    return false
  end
  return find_belt_item(belt) ~= nil
end

---Collect one representative belt per distinct speed.
---@param all_belts boolean
---@return table[]
local function collect_tiers(all_belts)
  local groups = {}
  local group_order = {}

  for _, belt in pairs(data.raw["transport-belt"]) do
    local allowed = all_belts or BASE_BELTS[belt.name]
    if allowed and is_usable_belt(belt) then
      local key = string.format("%.6f", belt.speed)
      local group = groups[key]
      if not group then
        group = { speed = belt.speed, entries = {} }
        groups[key] = group
        group_order[#group_order + 1] = key
      end
      group.entries[#group.entries + 1] = {
        belt = belt,
        item = find_belt_item(belt),
      }
    end
  end

  local tiers = {}
  for _, key in pairs(group_order) do
    local group = groups[key]
    local chosen

    -- Prefer a vanilla tier so its name, icon and tint stay recognisable.
    for _, entry in pairs(group.entries) do
      if FIXED_TIERS[entry.belt.name] then
        chosen = entry
        break
      end
    end

    if not chosen then
      table.sort(group.entries, function(a, b)
        return #a.belt.name < #b.belt.name
      end)
      chosen = group.entries[1]
    end

    tiers[#tiers + 1] = {
      speed = group.speed,
      belt = chosen.belt,
      item = chosen.item,
    }
  end

  table.sort(tiers, function(a, b)
    return a.speed < b.speed
  end)

  return tiers
end

---@param options table|nil
function loaders.create_loaders(options)
  options = options or {}

  local tiers = collect_tiers(options.all_belts ~= false)
  if #tiers == 0 then
    return
  end

  local used_names = {}
  for rank, tier in ipairs(tiers) do
    local fixed = FIXED_TIERS[tier.belt.name]
    if fixed then
      tier.loader_name = fixed.name
    else
      tier.loader_name = make_extra_loader_name(tier.belt.name, rank, used_names)
    end
    used_names[tier.loader_name] = true
  end

  local recipes_to_unlock = {}
  local previous_loader
  local need_power = options.need_power ~= false
  local utility_constants = data.raw["utility-constants"] and data.raw["utility-constants"].default
  local max_belt_stack_size = utility_constants and utility_constants.max_belt_stack_size

  for rank, tier in ipairs(tiers) do
    local belt = tier.belt
    local fixed = FIXED_TIERS[belt.name]
    local tint = fixed and fixed.tint or EXTRA_TINTS[((rank - 1) % #EXTRA_TINTS) + 1]
    local color = make_color(tint)
    local icon = fixed and fixed.icon or FALLBACK_ICON
    local drain = fixed and fixed.drain or string.format("%dW", 400 + (rank - 1) * 200)
    local base_belt = data.raw["transport-belt"]["transport-belt"]
    local animation_set = belt.belt_animation_set or (base_belt and base_belt.belt_animation_set)

    local energy_source
    if need_power then
      energy_source = {
        type = "electric",
        usage_priority = "secondary-input",
        drain = drain,
      }
    else
      energy_source = { type = "void" }
    end

    local belt_recipe = find_recipe_for_item(tier.item.name)
    local locale_name
    if not fixed then
      locale_name = { "", { "entity-name." .. belt.name }, { "entity-name.k2-loader-suffix" } }
    end

    local item = {
      type = "item",
      name = tier.loader_name,
      subgroup = "belt",
      order = string.format("d[loader]-%03d[%s]", rank, tier.loader_name),
      place_result = tier.loader_name,
      stack_size = 50,
      localised_name = locale_name,
    }

    local entity = {
      type = "loader-1x1",
      name = tier.loader_name,
      flags = { "placeable-neutral", "player-creation" },
      minable = { mining_time = 0.25, result = tier.loader_name },
      placeable_by = { item = tier.loader_name, count = 1 },
      fast_replaceable_group = "transport-belt",
      next_upgrade = tiers[rank + 1] and tiers[rank + 1].loader_name or nil,
      collision_box = { { -0.4, -0.45 }, { 0.4, 0.45 } },
      selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
      speed = belt.speed,
      container_distance = 0.75,
      filter_count = 5,
      max_belt_stack_size = max_belt_stack_size,
      energy_source = energy_source,
      energy_per_item = "9kJ",
      max_health = 300,
      corpse = "small-remnants",
      resistances = { { type = "fire", percent = 90 } },
      open_sound = sounds.machine_open,
      close_sound = sounds.machine_close,
      belt_animation_set = animation_set,
      animation_speed_coefficient = 32,
      icon_draw_specification = { scale = 0.7 },
      structure = graphics.structure(color),
      structure_render_layer = graphics.structure_render_layer,
      circuit_wire_max_distance = default_circuit_wire_max_distance,
      localised_name = locale_name,
    }

    if fixed then
      item.icon = icon
      item.icon_size = 64
      entity.icon = icon
      entity.icon_size = 64
    else
      local icons = { { icon = icon, icon_size = 64, tint = color } }
      item.icons = icons
      entity.icons = icons
    end

    local recipe = {
      type = "recipe",
      name = tier.loader_name,
      energy_required = 2,
      enabled = false,
      ingredients = make_ingredients(rank, tier.item.name, previous_loader),
      results = { { type = "item", name = tier.loader_name, amount = 1 } },
    }
    if belt_recipe then
      recipe.categories = belt_recipe.categories
      recipe.surface_conditions = belt_recipe.surface_conditions
    end

    data:extend({ item, recipe, entity })

    recipes_to_unlock[#recipes_to_unlock + 1] = {
      recipe_name = tier.loader_name,
      belt_recipe = belt_recipe,
      recipe = recipe,
    }

    previous_loader = tier.loader_name
  end

  -- Unlock each loader together with the belt it is built from.
  for _, entry in pairs(recipes_to_unlock) do
    local technology
    if entry.belt_recipe then
      technology = find_technology_for_recipe(entry.belt_recipe.name)
    end

    -- Belts that are available from the start are usually not unlocked by a
    -- technology; attach their loaders to the base logistics technology instead.
    if not technology and (not entry.belt_recipe or entry.belt_recipe.enabled ~= false) then
      technology = data.raw["technology"]["logistics"]
    end

    if technology then
      add_recipe_unlock(technology, entry.recipe_name)
    else
      entry.recipe.enabled = true
    end
  end
end

return loaders
