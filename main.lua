log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
PATH = _ENV["!plugins_mod_folder_path"]
mods.on_all_mods_loaded(function()
    for k, v in pairs(mods) do
        if type(v) == "table" and v.tomlfuncs then
            Toml = v
        end
    end
    params = {
        Version = 0.02,
        ChatKey = -1,
        InteractableList = {
            oActivator = 1,
            oArtiSnap = 0,
            oArtifactButton = 0,
            oBarrel1 = 1,
            oBarrel2 = 1,
            oBarrel3 = 2,
            oBarrelEquipment = 2,
            oBlastdoorPanel = 0,
            oBlockDestroy = 0,
            oBlockDestroy2 = 0,
            oBossKiller = 2,
            oChest1 = 2,
            oChest2 = 2,
            oChest4 = 2,
            oChest5 = 2,
            oChestDamage1 = 2,
            oChestDamage2 = 2,
            oChestHealing1 = 2,
            oChestHealing2 = 2,
            oChestToxin = 2,
            oChestUtility1 = 2,
            oChestUtility2 = 2,
            oCommand = 0,
            oCommandFinal = 0,
            oDeadman = 0,
            oDoor = 0,
            oDroneItem = 2,
            oDroneRecycler = 1,
            oDroneUpgrader = 1,
            oEfMine = 0,
            oEfPoisonMine = 0,
            oFeralCage = 0,
            oGauss = 0,
            oGunChest = 0,
            oGunchest = 0,
            oHiddenHand = 0,
            oIfritTower = 0,
            oMedCab = 0,
            oMedbay = 0,
            oMedcab = 0,
            oMushroomButton = 0,
            oRiftChest1 = 0,
            oRoboBuddyBroken = 0,
            oRoboBuddybroken = 0,
            oScreen = 0,
            oShamGBlock = 0,
            oShop1 = 2,
            oShop2 = 2,
            oShopEquipment = 2,
            oShrine1 = 2,
            oShrine2 = 1,
            oShrine3 = 2,
            oShrine4 = 2,
            oShrine5 = 1,
            oShrineMountain = 1,
            oTeleporter = 0,
            oTeleporterEpic = 0,
            oTeleporterFake = 0,
            oTimedArtifact = 0,
            oUsechest = 0,
            oVendor = 2
        },
        droneList = {
            oDrone10Item = 2,
            oDrone1Item = 2,
            oDrone2Item = 2,
            oDrone3Item = 2,
            oDrone4Item = 2,
            oDrone5Item = 2,
            oDrone6Item = 2,
            oDrone7Item = 2,
            oDrone8Item = 2,
            oDroneGolemItem = 2
        }
    }
    local oldparams = Toml.config_update(_ENV["!guid"], params) -- Load Save
    if oldparams.Version == params.Version then
        params = oldparams
    end
end)

local openRecap = false
local ActivatedTP = false
local StageInteractables = {}

local blacklist = {
    gm.constants.oBNoSpawn, gm.constants.oBarrel4
}

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

    gm.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
        if (result.value.active == 0 or GM.object_get_parent(result.value.object_index) == gm.constants.pInteractableChest) and 
        result.value.sprite_index ~= -1 and 
        GM.object_get_parent(result.value.object_index) ~= gm.constants.pInteractableDrone then
            if params.InteractableList[result.value.object_name] == nil then
                params.InteractableList[result.value.object_name] = 0
                Toml.save_cfg(_ENV["!guid"], params)
            end
            if params.InteractableList[result.value.object_name] == 0 or result.value.x < 0 then
                return
            end
            for _, listItem in ipairs(blacklist) do
                if result.value.object_index == listItem then
                    return
                end
            end

            -- log.warning(result.value.object_name)
            -- Helper.log_struct(result.value)

            local newtoList = true
            for i, interactable in ipairs(InteractableList) do
                if interactable.object_index == result.value.object_index then
                    newtoList = false
                    stackList[i] = stackList[i] + 1
                end
            end
            if result.value.charges then
                Instance.wrap(result.value):get_data().maxCharges = result.value.charges
            end
            if newtoList then
                table.insert(InteractableList, Object.wrap(result.value.object_index):create(-1000, 0).value)
                -- log.warning(result.value.object_name)
                -- table.insert(InteractableList, result.value)
                table.insert(stackList, 1)
                table.insert(activatedList, 0)
            end
        end

        if result.value:get_object_index_self() and GM.object_get_parent(result.value:get_object_index_self()) ==
            gm.constants.pInteractableDrone then
            if params.droneList[result.value.object_name] == nil then
                params.droneList[result.value.object_name] = 0
                Toml.save_cfg(_ENV["!guid"], params)
            end
            if params.droneList[result.value.object_name] == 0 then
                return
            end

            local newdrone = true
            for k, v in ipairs(Instance.find_all(result.value.object_index)) do
                if v.x < 0 then
                    newdrone = false
                end
            end
            if newdrone then
                table.insert(droneList, Object.wrap(result.value.object_index):create(-1000, 0).value)
            end
        end
    end)

    gm.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
        -- set get number of active and non active interactables
        if self.object_index == gm.constants.oTeleporter or self.object_index == gm.constants.oTeleporterEpic then
            for i, type in ipairs(InteractableList) do
                for _, interactable in ipairs(Instance.find_all(type:get_object_index_self())) do
                    if _ == 1 then
                        activatedList[i] = 0
                    end
                    if interactable.x > 0 then
                        if interactable:get_data().maxCharges ~= nil then
                            if interactable.charges < 0 then
                                activatedList[i] = activatedList[i] + interactable.charges /
                                                       interactable:get_data().maxCharges
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
                end
                -- check for things that can disappear when activated (gauss turret and probably some more stuff)
                if type.spawns then
                    if stackList[i] ~= #Instance.find_all(type:get_object_index_self()) - type.spawns - 1 then
                        activatedList[i] = stackList[i] - #Instance.find_all(type:get_object_index_self()) + type.spawns + 1
                    end
                else
                    if stackList[i] ~= #Instance.find_all(type:get_object_index_self()) - 1 then
                        activatedList[i] = stackList[i] - #Instance.find_all(type:get_object_index_self()) + 1
                    end
                end
            end
        end
    end)

    gm.post_code_execute("gml_Object_oInit_Draw_64", function(self, other)
        if gm._mod_game_getDirector() and gm._mod_game_getDirector() ~= -4 and (gm._mod_game_getDirector().teleporter_active >= 4 or openRecap) then
            if fade < 1 then
                fade = fade + 0.1
            end
            local ViewWidth = gm.display_get_gui_width()
            local ViewHeight = gm.display_get_gui_height()
            gm.draw_set_alpha(0.5 * fade)
            gm.draw_rectangle_colour(ViewWidth * 0.3, ViewHeight * 0.22, ViewWidth * 0.7, ViewHeight * 0.75, 0, 0, 0, 0,
                false);

            gm.draw_set_font(0)
            gm.draw_set_alpha(1 * fade)

            -- get activated and not activated interactables for final percentage
            local numInteractables = 0
            local numActivated = 0
            for i, Interactable in ipairs(InteractableList) do
                -- log.warning(Interactable.object_name, Interactable)
                if params.InteractableList[Interactable.object_name] == 2 then
                    numActivated = numActivated + activatedList[i]
                    numInteractables = numInteractables + stackList[i]

                    -- log.warning(Interactable.object_name, activatedList[i], stackList[i])
                end
            end
            for i, drone in ipairs(droneList) do
                if drone and params.droneList[drone.object_name] == 2 then
                    numInteractables = numInteractables + #Instance.find_all(drone:get_object_index_self()) - 1
                end
            end
            gm.draw_text_transformed(ViewWidth * 0.63, ViewHeight * 0.29,
                "Stage Clear: " .. math.floor((numActivated / numInteractables) * 100) .. "%", ViewHeight / 600,
                ViewHeight / 600, 0)

            for i = 0, #InteractableList - 1 do
                local spriteScale = math.max(gm.sprite_get_height(InteractableList[i + 1].sprite_index),
                                    gm.sprite_get_width(InteractableList[i + 1].sprite_index)) ^ 1.6

                self:draw_sprite_ext(InteractableList[i + 1].sprite_index, 0,
                                ViewWidth * 0.29 + ViewWidth * ((i % 5) + 1) * 0.07,
                                ViewHeight * 0.25 + ViewHeight * (math.floor(i / 5) + 1) * 0.15,
                                ViewHeight / spriteScale + ViewHeight / 1500, ViewHeight / spriteScale + ViewHeight / 1500, 0,
                                Color.WHITE, 1)

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
                                            ViewHeight / 1200,
                                            ViewHeight / 1200, 0)
                end
            end
            gm.draw_set_colour(Color.WHITE)
            for i = #InteractableList, #InteractableList + #droneList - 1 do
                if droneList[i - #InteractableList + 1] and 
                #Instance.find_all(droneList[i - #InteractableList + 1]:get_object_index_self()) > 1 then
                    local spriteScale = math.max(gm.sprite_get_width(droneList[i - #InteractableList + 1].sprite_index),
                                        gm.sprite_get_height(droneList[i - #InteractableList + 1].sprite_index)) + 100
                    self:draw_sprite_ext(droneList[i - #InteractableList + 1].sprite_index, 0,
                                    ViewWidth * 0.29 + ViewWidth * ((i % 5) + 1) * 0.07,
                                    ViewHeight * 0.25 + ViewHeight * (math.floor(i / 5) + 1) * 0.15, ViewHeight / 3 / spriteScale,
                                    ViewHeight / 3 / spriteScale, 0, Color.WHITE, 1)

                    gm.draw_text_transformed(ViewWidth * 0.31 + ViewWidth * ((i % 5) + 1) * 0.07,
                                            ViewHeight * 0.28 + ViewHeight * (math.floor(i / 5) + 1) * 0.15, 
                                            #Instance.find_all(droneList[i - #InteractableList + 1]:get_object_index_self()) - 1, 
                                            ViewHeight / 600,
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
    openRecap = ImGui.IsKeyDown(params.ChatKey)
end)
