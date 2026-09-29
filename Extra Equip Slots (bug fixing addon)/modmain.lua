local ORIGINAL_MOD = "workshop-3681081494"
local mod_index = GLOBAL.KnownModIndex

if mod_index == nil or not mod_index:IsModEnabledAny(ORIGINAL_MOD) then
    return
end

-- The affected inventory_classified methods exist only on clients.
if GLOBAL.TheNet:GetIsServer() then
    return
end

AddPrefabPostInit("inventory_classified", function(inst)
    -- This addon loads before Extra Equip Slots and retains the game's method.
    local native_has = inst.Has
    local receive_item = inst.ReceiveItem
    if type(native_has) ~= "function" or type(receive_item) ~= "function" then
        GLOBAL.print("[Extra Equip Slots addon] Native inventory methods are unavailable")
        return
    end

    local function get_overflow_container(inventory)
        if inventory.ignoreoverflow then
            return nil
        end
        local item = inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BACK)
        return item ~= nil and item.replica.container or nil
    end

    -- Extra Equip Slots runs later in the same prefab-init pass. Restore Has
    -- after that pass, so crafting keeps the game's open-container rules.
    inst:DoStaticTaskInTime(0, function()
        if inst.IsValid ~= nil and not inst:IsValid() then
            return
        end

        inst.Has = native_has
        inst.GetOverflowContainer = get_overflow_container

        -- The game's item-transfer methods capture a local overflow lookup.
        -- Assigning the public method does not affect that shared upvalue.
        local debugger = GLOBAL.debug
        if debugger ~= nil and debugger.getupvalue ~= nil and debugger.setupvalue ~= nil then
            local index = 1
            while true do
                local name = debugger.getupvalue(receive_item, index)
                if name == nil then
                    break
                elseif name == "GetOverflowContainer" then
                    debugger.setupvalue(receive_item, index, get_overflow_container)
                    return
                end
                index = index + 1
            end
        end
        GLOBAL.print("[Extra Equip Slots addon] Could not patch inventory overflow lookup")
    end)
end)
