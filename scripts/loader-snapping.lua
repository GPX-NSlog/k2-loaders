local loader_snapping_enabled = true

---@type table<defines.direction, number[]>
local offsets = {
  [defines.direction.north] = { 0, -1 },
  [defines.direction.east] = { 1, 0 },
  [defines.direction.south] = { 0, 1 },
  [defines.direction.west] = { -1, 0 },
}

local belt_types = {
  "linked-belt",
  "loader",
  "loader-1x1",
  "splitter",
  "transport-belt",
  "underground-belt",
}

local container_types = {
  "assembling-machine",
  "beacon",
  "boiler",
  "burner-generator",
  "container",
  "curved-rail",
  "furnace",
  "infinity-container",
  "lab",
  "linked-container",
  "logistic-container",
  "mining-drill",
  "proxy-container",
  "rail",
  "reactor",
  "rocket-silo",
  "straight-rail",
}

---@param direction defines.direction
---@return defines.direction
local function opposite(direction)
  return (direction + 8) % 16
end

---@param position MapPosition
---@param offset number[]
---@return MapPosition
local function add(position, offset)
  return { x = position.x + offset[1], y = position.y + offset[2] }
end

---@param entity LuaEntity
local function flip_loader(entity)
  entity.direction = opposite(entity.direction)
  entity.loader_type = entity.loader_type == "output" and "input" or "output"
end

---Find entities and entity ghosts of the corresponding types.
---@param surface LuaSurface
---@param position MapPosition
---@param force ForceID
---@param types string[]
---@return LuaEntity[]
local function find_entities(surface, position, force, types)
  local entities = surface.find_entities_filtered({
    force = force,
    position = position,
    type = types,
  })
  local ghosts = surface.find_entities_filtered({
    force = force,
    ghost_type = types,
    position = position,
  })
  for i = 1, #ghosts do
    entities[#entities + 1] = ghosts[i]
  end
  return entities
end

---Ensure that the loader has the belt on the correct side.
---@param entity LuaEntity
local function snap_direction(entity)
  local offset_direction = entity.direction
  if entity.loader_type == "input" then
    offset_direction = opposite(offset_direction)
  end
  local container_position = add(entity.position, offsets[offset_direction])

  -- Case 1: If a container is in front, then flip the loader.
  local containers = find_entities(entity.surface, container_position, entity.force, container_types)
  if #containers > 0 then
    -- Do not flip when the container is another loader.
    local is_composite = entity.surface.count_entities_filtered({
      force = entity.force,
      position = container_position,
      type = { "loader", "loader-1x1" },
    }) > 0
    if not is_composite then
      flip_loader(entity)
      return
    end
  end

  -- Case 2: If a belt is behind, then flip the loader.
  offset_direction = opposite(offset_direction)
  local belt_position = add(entity.position, offsets[offset_direction])
  local belt = find_entities(entity.surface, belt_position, entity.force, belt_types)[1]
  if not belt then
    return
  end

  local belt_type = belt.type
  if belt_type == "entity-ghost" then
    belt_type = belt.ghost_type
  end
  if
    belt_type == "transport-belt"
    or belt_type == "underground-belt"
    or math.abs(offset_direction - belt.direction) % 4 == 0
  then
    flip_loader(entity)
  end
end

---@param entity LuaEntity
local function snap_to_belt(entity)
  local offset_direction = entity.direction
  if entity.loader_type == "input" then
    offset_direction = opposite(offset_direction)
  end
  local belt_position = add(entity.position, offsets[offset_direction])

  local belt = find_entities(entity.surface, belt_position, entity.force, belt_types)[1]
  if not belt then
    return
  end

  local belt_direction = belt.direction
  local belt_type = belt.type
  if belt_type == "entity-ghost" then
    belt_type = belt.ghost_type
  end

  if entity.direction == belt_direction then
    -- Pass.
  elseif entity.direction == opposite(belt_direction) then
    entity.loader_type = "input"
  elseif belt_type == "transport-belt" or belt_type == "underground-belt" then
    -- Sideloading.
    entity.loader_type = "output"
  end
end

---@param e EntityBuiltEvent
local function on_entity_built(e)
  if not loader_snapping_enabled then
    return
  end

  local entity = e.entity or e.destination
  if not entity or not entity.valid or not string.match(entity.name, "^k2%-.*loader$") then
    return
  end

  entity.update_connections()
  if not entity.loader_container then
    snap_direction(entity)
  end

  snap_to_belt(entity)
end

local function register_events()
  local handlers = {
    [defines.events.on_built_entity] = on_entity_built,
    [defines.events.on_entity_cloned] = on_entity_built,
    [defines.events.on_robot_built_entity] = on_entity_built,
    [defines.events.script_raised_built] = on_entity_built,
    [defines.events.script_raised_revive] = on_entity_built,
    [defines.events.on_space_platform_built_entity] = on_entity_built,
  }
  for event, handler in pairs(handlers) do
    script.on_event(event, handler)
  end
end

register_events()

remote.add_interface("k2_loader_snapping", {
  ---Sets whether or not loader snapping is enabled. Not preserved across save/load.
  ---@param value boolean
  set_enabled = function(value)
    assert(type(value) == "boolean", "`value` must be a boolean")
    loader_snapping_enabled = value
  end,
  ---Returns whether or not loader snapping is currently enabled.
  get_enabled = function()
    return loader_snapping_enabled
  end,
})
