-- scripts/transportation/fill_platform_thrusters.lua
-- Fills the current platform thrusters with the fluids required by each fluidbox.
-- Uses Factorio 2.1 LuaEntity fluid methods (LuaFluidBox was removed in 2.1).

local M = {}
local compat = require("scripts/utils/mod_compat")

local space_age_enabled = compat.is_space_age_stack_active()

local function get_required_fluid_name(thruster, index)
  local ok_proto, proto = pcall(function() return thruster:get_fluid_box_prototype(index) end)
  if ok_proto and proto and type(proto.filter) == "string" and proto.filter ~= "" then
    return proto.filter
  end

  local ok_filter, filter = pcall(function() return thruster:get_fluid_filter(index) end)
  if ok_filter and type(filter) == "string" and filter ~= "" then
    return filter
  end

  local ok_fluid, fluid = pcall(function() return thruster:get_fluid(index) end)
  if ok_fluid and fluid and type(fluid.name) == "string" and fluid.name ~= "" then
    return fluid.name
  end

  return nil
end

local function fill_fluidbox_slot(thruster, index, fluid_name)
  local ok_cap, capacity = pcall(function() return thruster:get_fluid_capacity(index) end)
  if not ok_cap or type(capacity) ~= "number" or capacity <= 0 then
    return false
  end

  local ok_set = pcall(function()
    thruster:set_fluid(index, { name = fluid_name, amount = capacity })
  end)
  return ok_set
end

function M.run(player)
  if not (player and player.valid) then return end
  if not is_allowed(player) then
    player.print({ "facc.not-allowed" })
    return
  end

  if not space_age_enabled then
    player.print({ "facc.fill-thrusters-no-space-age" })
    return
  end

  local surface = player.surface
  if not (surface and surface.valid and surface.platform) then
    player.print({ "facc.fill-thrusters-no-platform" })
    return
  end

  local thrusters = surface.find_entities_filtered{
    force = player.force,
    type = "thruster"
  }

  if #thrusters == 0 then
    player.print({ "facc.fill-thrusters-none" })
    return
  end

  local fueled_count = 0

  for _, thruster in pairs(thrusters) do
    if thruster.valid then
      local filled_any = false

      for i = 1, thruster.fluids_count do
        local fluid_name = get_required_fluid_name(thruster, i)
        if fluid_name and fill_fluidbox_slot(thruster, i, fluid_name) then
          filled_any = true
        end
      end

      if filled_any then
        fueled_count = fueled_count + 1
      end
    end
  end

  if fueled_count > 0 then
    player.print({ "facc.fill-thrusters-msg", fueled_count })
  else
    player.print({ "facc.fill-thrusters-failed" })
  end
end

return M
