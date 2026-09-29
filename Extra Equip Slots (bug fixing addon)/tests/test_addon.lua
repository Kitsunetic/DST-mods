local addon_dir = (... and ... ~= "" and ...) or "Extra Equip Slots (bug fixing addon)"

local function make_world(original_enabled)
    local callbacks = {}
    local tasks = {}
    local messages = {}
    local equipped = {}
    local inventory = { twigs = 0 }
    local open_chest = { items = { twigs = 2 } }
    local backpack = { items = { twigs = 1 }, space = 1 }
    equipped.back = { replica = { container = backpack } }

    -- Model the game's shared local, which ReceiveItem and Has both capture.
    local function GetOverflowContainer(inst)
        return equipped.body and equipped.body.replica.container or nil
    end

    local function native_has(inst, prefab, amount, checkallcontainers)
        local count = inventory[prefab] or 0
        local overflow = GetOverflowContainer(inst)
        count = count + (overflow and overflow.items[prefab] or 0)
        if checkallcontainers then
            count = count + (open_chest.items[prefab] or 0)
        end
        return count >= amount, count
    end

    local function receive_item(inst, item)
        if inst.inventory_space > 0 then
            inst.inventory_space = inst.inventory_space - 1
            return "inventory"
        end
        local overflow = GetOverflowContainer(inst)
        if overflow and overflow.space > 0 then
            overflow.space = overflow.space - 1
            return "backpack"
        end
        return "no space"
    end

    local inst = {
        inventory_space = 0,
        Has = native_has,
        ReceiveItem = receive_item,
        GetOverflowContainer = GetOverflowContainer,
        GetEquippedItem = function(_, slot) return equipped[slot] end,
        DoStaticTaskInTime = function(_, delay, fn)
            assert(delay == 0)
            tasks[#tasks + 1] = fn
        end,
    }

    _G.GLOBAL = {
        TheNet = { GetIsServer = function() return false end },
        EQUIPSLOTS = { BODY = "body", BACK = "back" },
        KnownModIndex = {
            IsModEnabledAny = function(_, id)
                return original_enabled and id == "workshop-3681081494"
            end,
        },
        debug = debug,
        print = function(message) messages[#messages + 1] = message end,
    }
    _G.AddPrefabPostInit = function(name, fn)
        assert(name == "inventory_classified")
        callbacks[#callbacks + 1] = fn
    end

    dofile(addon_dir .. "/modmain.lua")

    local function apply_original()
        -- Original's public-method override leaves the game's local alone.
        inst.GetOverflowContainer = function(self)
            return self:GetEquippedItem("back").replica.container
        end
        inst.Has = function(self, prefab, amount)
            local count = inventory[prefab] or 0
            return count >= amount, count
        end
    end

    return {
        inst = inst,
        callbacks = callbacks,
        tasks = tasks,
        messages = messages,
        apply_original = apply_original,
        flush = function()
            for _, fn in ipairs(tasks) do fn(inst) end
        end,
    }
end

local enabled = make_world(true)
assert(#enabled.callbacks == 1, "addon should register one prefab hook")
enabled.callbacks[1](enabled.inst)
enabled.apply_original()
assert(enabled.inst:ReceiveItem({ prefab = "twigs" }) == "no space", "fixture must reproduce overflow bug")
assert(not enabled.inst:Has("twigs", 2, true), "fixture must reproduce open-chest crafting bug")
enabled.flush()
assert(enabled.inst:ReceiveItem({ prefab = "twigs" }) == "backpack", "BACK overflow should use native transfer logic")
local can_craft, count = enabled.inst:Has("twigs", 3, true)
assert(can_craft and count == 3, "native Has should count open chest and backpack")

local disabled = make_world(false)
assert(#disabled.callbacks == 0, "addon must not patch without its target mod")
assert(disabled.inst:ReceiveItem({ prefab = "twigs" }) == "no space")
local native_craft = disabled.inst:Has("twigs", 2, true)
assert(native_craft, "native behavior must remain intact without target mod")

print("addon behavior tests passed")
