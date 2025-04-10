log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(false)
PATH = _ENV["!plugins_mod_folder_path"]
mods.on_all_mods_loaded(function()
    for k, v in pairs(mods) do
        if type(v) == "table" and v.tomlfuncs then
            Toml = v
        end
    end
    params = {
        Version = 0.01,
        ChatKey = 9,
        InteractableList = {
            oShop2 = 2,
            oRiftChest1 = 2,
            oActivator = 2,
            oBarrel1 = 1,
            oChest4 = 2,
            oTeleporterFake = 0,
            oShrineMountain = 2,
            oChest1 = 2,
            oChestHealing2 = 2,
            oBarrel2 = 1,
            oGauss = 0,
            oTeleporter = 0,
            oShrine1 = 2,
            oShrine2 = 2,
            oCommandFinal = 0,
            oMedCab = 2,
            oShop1 = 2,
            oChestUtility2 = 2,
            oMedbay = 0,
            oUseChest = 2,
            oRoboBuddybroken = 0,
            oDroneItem = 2,
            oHiddenHand = 0,
            oChestHealing1 = 2,
            oGunChest = 2,
            oTeleporterEpic = 0,
            oDroneUpgrader = 2,
            oShopEquipment = 2,
            oBarrelEquipment = 2,
            oChestDamage2 = 2,
            oBarrel3 = 2,
            oChestToxin = 2,
            oChest5 = 2,
            oBarrel4 = 2,
            oBlastdoorPanel = 0,
            oChestDamage1 = 2,
            oChestUtility1 = 2,
            oShrine3 = 2,
            oDroneRecycler = 2,
            oChest2 = 2
        },
        droneList = {
            oDrone5Item = 2,
            oDrone4Item = 2,
            oDrone3Item = 2,
            oDrone8Item = 2,
            oDrone2Item = 2,
            oDrone6Item = 2,
            oDrone1Item = 2
        }
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

local openRecap = false
local ActivatedTP = false
local StageInteractables = {}
Initialize(function()
    local InteractableList = {}
    local stackList = {}
    local activatedList = {}
    local droneList = {}
    local fade = 0

    gm.pre_script_hook(gm.constants.room_goto, function(self, other, result, args)
        InteractableList = {}
        stackList = {}
        activatedList = {}
        droneList = {}
        fade = 0
    end)

    -- Callback.add(Callback.TYPE.onStageStart, "asdfgyutfg", function()
    --     InteractableList = {}
    --     stackList = {}
    --     activatedList = {}
    --     droneList = {}
    -- end)

    gm.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
        -- log.warning(result.value.object_name)
        -- log.warning(result.value.object_index)
        -- log.warning(result.value.active)
        -- log.warning(result.value.sprite_index)
        -- log.warning(result.value:get_object_index_self())
        -- oCustomObject
        -- result.value.sprite_index ~= -1
        -- GM.object_get_parent(result.value.object_index) == gm.constants.pInteractableChest
        if result.value.active == 0 and result.value.sprite_index ~= -1 and result.value:get_object_index_self() ~=
            gm.constants.oBNoSpawn and result.value:get_object_index_self() and
            GM.object_get_parent(result.value:get_object_index_self()) ~= gm.constants.pInteractableDrone then
            -- log.warning(result.value.object_name)
            if params.InteractableList[result.value.object_name] == nil then
                params.InteractableList[result.value.object_name] = 0
                Toml.save_cfg(_ENV["!guid"], params)
            end
            if params.InteractableList[result.value.object_name] == 0 then
                return
            end

            local newtoList = true
            for i, interactable in ipairs(InteractableList) do
                if interactable:get_object_index_self() == result.value:get_object_index_self() then
                    newtoList = false
                    stackList[i] = stackList[i] + 1
                    -- if result.value.charges then
                    --     stackList[i] = stackList[i] + interactable.charges
                    -- else
                    --     stackList[i] = stackList[i] + 1
                    -- end
                end
            end
            if result.value.charges then
                Instance.wrap(result.value):get_data().maxCharges = result.value.charges
            end
            if newtoList then
                table.insert(InteractableList, result.value)
                table.insert(stackList, 1)
                table.insert(activatedList, 0)
            end
        end

        if result.value:get_object_index_self() and GM.object_get_parent(result.value:get_object_index_self()) ==
            gm.constants.pInteractableDrone then
            if params.droneList[result.value.object_name] == nil then
                params.droneList[result.value.object_name] = false
                Toml.save_cfg(_ENV["!guid"], params)
            end
            if params.droneList[result.value.object_name] == 0 then
                return
            end

            local newdrone = true
            for _, drone in ipairs(droneList) do
                if result.value:get_object_index_self() == drone:get_object_index_self() then
                    newdrone = false
                end
            end
            if newdrone then
                table.insert(droneList, result.value)
            end
        end
    end)

    gm.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
        -- get teleporter when interacting with it
        if self.object_index == gm.constants.oTeleporter or self.object_index == gm.constants.oTeleporterEpic then
                for i, type in ipairs(InteractableList) do
                    for _, interactable in ipairs(Instance.find_all(type:get_object_index_self())) do
                        if _ == 1 then
                            activatedList[i] = 0
                        end

                        if interactable:get_data().maxCharges ~= nil then
                            if interactable.charges < 0 then
                                activatedList[i] = activatedList[i] + interactable.charges/interactable:get_data().maxCharges
                            end
                            activatedList[i] = activatedList[i] +
                                                   (interactable:get_data().maxCharges - interactable.charges) /
                                                   interactable:get_data().maxCharges
                        else
                            if interactable.active ~= 0 then
                                activatedList[i] = activatedList[i] + 1
                            end
                        end
                    end
                    if stackList[i] ~= #Instance.find_all(type:get_object_index_self()) then
                        activatedList[i] = stackList[i] - #Instance.find_all(type:get_object_index_self())
                    end
                end
        end
    end)

    gm.post_code_execute("gml_Object_oInit_Draw_64", function(self, other)
        -- if gm._mod_game_getDirector() ~= -4 and gm._mod_game_getDirector().teleporter_active >= 4 then
        --     local ViewWidth = gm.display_get_gui_width()
        --     local ViewHeight = gm.display_get_gui_height()
        --     gm.draw_rectangle_colour(ViewWidth * 0.1, ViewHeight * 0.1, ViewWidth * 0.9, ViewHeight * 0.9, 0, 0, 0, 0, false);
        -- end

        if gm._mod_game_getDirector() ~= -4 and (gm._mod_game_getDirector().teleporter_active >= 4 or openRecap) then
            if fade < 1 then
                fade = fade + 0.1
            end
            local ViewWidth = gm.display_get_gui_width()
            local ViewHeight = gm.display_get_gui_height()
            gm.draw_set_alpha(0.5 * fade)
            gm.draw_rectangle_colour(ViewWidth * 0.3, ViewHeight * 0.22, ViewWidth * 0.7, ViewHeight * 0.75, 0, 0, 0, 0,
                false);

            gm.draw_set_font(1)
            gm.draw_set_alpha(1 * fade)
            local numInteractables = 0
            local numActivated = 0
            for i = 0, #InteractableList - 1 do
                if params.InteractableList[InteractableList[i + 1].object_name] == 2 then
                    numActivated = numActivated + activatedList[i + 1]
                    numInteractables = numInteractables + stackList[i + 1]
                end
            end
            for i = #InteractableList, #InteractableList + #droneList - 1 do
                if droneList[i + 1] and params.droneList[droneList[i + 1].object_name] == 2 then
                    numInteractables = numInteractables + #Instance.find_all(droneList[i - #InteractableList + 1]:get_object_index_self())
                end
            end
            gm.draw_text_transformed(ViewWidth * 0.63,
                    ViewHeight * 0.29, "Stage Clear: "..math.floor((numActivated/numInteractables) * 100).."%",
                    ViewHeight / 600, ViewHeight / 600, 0)

            for i = 0, #InteractableList - 1 do
                -- local spriteScale = math.max(gm.sprite_get_width(InteractableList[i + 1].sprite_index),
                    -- gm.sprite_get_height(InteractableList[i + 1].sprite_index)) + 50
                -- spriteScale = ((gm.sprite_get_height(InteractableList[i + 1].sprite_index)*InteractableList[i + 1].image_yscale) ^1.6)

                local spriteScale = math.max(gm.sprite_get_height(InteractableList[i + 1].sprite_index), gm.sprite_get_width(InteractableList[i + 1].sprite_index))^1.6
                -- spriteScale = (InteractableList[i + 1].image_yscale ^1.6) / 2
                
                -- log.warning(spriteScale)
                -- gm.draw_sprite_ext(InteractableList[i + 1].sprite_index, 0,
                --     ViewWidth * 0.29 + ViewWidth * ((i % 5) + 1) * 0.07,
                --     ViewHeight * 0.25 + ViewHeight * (math.floor(i / 5) + 1) * 0.15, ViewHeight / spriteScale,
                --     ViewHeight / spriteScale, 0, Color.WHITE, 1)
                gm.draw_sprite_ext(InteractableList[i + 1].sprite_index, 0,
                    ViewWidth * 0.29 + ViewWidth * ((i % 5) + 1) * 0.07,
                    ViewHeight * 0.25 + ViewHeight * (math.floor(i / 5) + 1) * 0.15, ViewHeight / spriteScale + ViewHeight/1500,
                    ViewHeight / spriteScale + ViewHeight/1500, 0, Color.WHITE, 1)
                -- gm.draw_sprite_ext(InteractableList[i + 1].sprite_index, 0,
                --     ViewWidth * 0.29 + ViewWidth * ((i % 5) + 1) * 0.07,
                --     ViewHeight * 0.25 + ViewHeight * (math.floor(i / 5) + 1) * 0.15, ViewHeight / spriteScale,
                --     ViewHeight / spriteScale, 0, Color.WHITE, 1)

                gm.draw_set_colour(3714480)
                if activatedList[i + 1] == stackList[i + 1] then
                    gm.draw_set_colour(5164622)
                end
                if activatedList[i + 1] == 0 then
                    gm.draw_set_colour(3684528)
                end

                local spawns = 0
                if InteractableList[i + 1].spawns then
                    spawns = InteractableList[i + 1].spawns
                end
                if activatedList[i + 1] / (spawns + 1) * 10 % 10 == 0 then
                    gm.draw_text_transformed(ViewWidth * 0.32 + ViewWidth * ((i % 5) + 1) * 0.07,
                    ViewHeight * 0.27 + ViewHeight * (math.floor(i / 5) + 1) * 0.15,
                    math.floor(activatedList[i + 1] / (spawns + 1)) .. "/" .. math.floor(stackList[i + 1] / (spawns + 1)),
                    ViewHeight / 1200, ViewHeight / 1200, 0)
                else
                    gm.draw_text_transformed(ViewWidth * 0.32 + ViewWidth * ((i % 5) + 1) * 0.07,
                    ViewHeight * 0.27 + ViewHeight * (math.floor(i / 5) + 1) * 0.15,
                    activatedList[i + 1] / (spawns + 1) .. "/" .. math.floor(stackList[i + 1] / (spawns + 1)),
                    ViewHeight / 1200, ViewHeight / 1200, 0)
                end

            end
            gm.draw_set_colour(Color.WHITE)
            for i = #InteractableList, #InteractableList + #droneList - 1 do
                if droneList[i - #InteractableList + 1]:exists() and #Instance.find_all(droneList[i - #InteractableList + 1]:get_object_index_self()) > 0 then
                    local spriteScale = math.max(gm.sprite_get_width(droneList[i - #InteractableList + 1].sprite_index),
                        gm.sprite_get_height(droneList[i - #InteractableList + 1].sprite_index)) + 100
                    gm.draw_sprite_ext(droneList[i - #InteractableList + 1].sprite_index, 0,
                        ViewWidth * 0.29 + ViewWidth * ((i % 5) + 1) * 0.07,
                        ViewHeight * 0.25 + ViewHeight * (math.floor(i / 5) + 1) * 0.15, ViewHeight / 3 / spriteScale,
                        ViewHeight / 3 / spriteScale, 0, Color.WHITE, 1)

                    gm.draw_text_transformed(ViewWidth * 0.31 + ViewWidth * ((i % 5) + 1) * 0.07,
                        ViewHeight * 0.28 + ViewHeight * (math.floor(i / 5) + 1) * 0.15, #Instance.find_all(
                            droneList[i - #InteractableList + 1]:get_object_index_self()), ViewHeight / 600,
                        ViewHeight / 600, 0)
                end
            end
        end
    end)
end)

local awaitingChatKeybind = false
gui.add_imgui(function()
    if ImGui.Begin("StageRecap") then
        -- ImGui.Text("Open Recap Keybind")
        -- if awaitingChatKeybind then
        --     ImGui.Button("<Waiting for Key>")
        -- else
        --     if ImGui.Button("          " .. params.ChatKey .. "          ") then
        --         awaitingChatKeybind = true
        --     end
        -- end
        -- for keyCode = 0, 512 do
        --     if ImGui.IsKeyPressed(keyCode) and awaitingChatKeybind then
        --         params.ChatKey = keyCode
        --         awaitingChatKeybind = false
        --         break
        --     end
        -- end

        local collapse = ImGui.CollapsingHeader("Interactables")
        if collapse then
            
            for i, interactable in pairs(params.InteractableList) do
                if i ~= "oIfritTower" and i ~= "oBlockDestroy" and i ~= "oEfMine" and i ~= "oArtifactButton" and i ~=
                    "oDoor" and i ~= "oScreen" and i ~= "oCommand" and i ~= "oMushroomButton" and i ~= "oGaussActive" then
                    params.InteractableList[i] = ImGui.SliderInt(i:sub(2), params.InteractableList[i], 0, 2)
                end
            end
        end

        collapse = ImGui.CollapsingHeader("Drones")
        if collapse then
            for i, drone in pairs(params.droneList) do
                params.droneList[i] = ImGui.SliderInt(i:sub(2), params.droneList[i], 0, 2)
            end
        end
        Toml.save_cfg(_ENV["!guid"], params)
    end
    ImGui.End()
end)

gui.add_always_draw_imgui(function()
    -- openRecap = ImGui.IsKeyDown(params.ChatKey)
end)
