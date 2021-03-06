-- summoner.lua
-- manages the Elemental Summoner and Elementals

ElementalBaseHealth = {300, 1500, 7500}
Particles = {
    light_elemental = "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_spirit_form_ambient.vpcf",
}

ExplosionParticles = {
    water = "particles/custom/elements/water/explosion.vpcf",
    fire = "particles/custom/elements/fire/explosion.vpcf",
    nature = "particles/custom/elements/nature/explosion.vpcf",
    earth = "particles/custom/elements/earth/explosion.vpcf",
    light = "particles/custom/elements/light/explosion.vpcf",
    dark = "particles/custom/elements/dark/explosion.vpcf",
}

TrailParticles = {
    water = "particles/econ/items/lion/fish_stick/fish_stick_spell_ambient.vpcf",
    fire = "particles/econ/courier/courier_trail_lava/courier_trail_lava.vpcf",
    nature = "particles/custom/elements/nature/courier_greevil_green_ambient_3.vpcf",
    earth = "particles/custom/elements/earth/trail.vpcf",
    light = "particles/econ/courier/courier_trail_05/courier_trail_05.vpcf",
    dark = "particles/econ/courier/courier_greevil_purple/courier_greevil_purple_ambient_3.vpcf",
}

ElementalSounds = {
    water_spawn = "Hero_Morphling.Replicate",
    water_death = "Hero_Morphling.Waveform",

    fire_spawn = "Ability.LightStrikeArray",
    fire_death = "Hero_Lina.DragonSlave",

    nature_spawn = "Hero_Furion.Teleport_Appear",
    nature_death = "Hero_Furion.TreantSpawn",

    earth_spawn = "Ability.TossImpact",
    earth_death = "Ability.Avalanche",

    light_spawn = "Hero_KeeperOfTheLight.ChakraMagic.Target",
    light_death = "Hero_KeeperOfTheLight.BlindingLight",

    dark_spawn = "Hero_Nevermore.RequiemOfSouls",
    dark_death = "Hero_Nevermore.Shadowraze",

    --[[water = "morphling_mrph_",
    water_S = 8,
    water_D = 12,
    fire = "lina_lina_",
    fire_S = 9,
    fire_D = 12,
    nature = "furion_furi_",
    nature_S = 3,
    nature_D = 11,
    earth = "tiny_tiny_",
    earth_S = 9,
    earth_D = 13,
    light = "keeper_of_the_light_keep_",
    light_S = 5,
    light_D = 15,
    dark = "nevermore_nev_",
    dark_S = 11,
    dark_D = 19,--]]
}

function GetSoundNumber( max )
    local rand = math.random(max)
    local str = ""
    str = string.format("%02d", rand)
    return str
end

function ModifyLumber(playerID, amount)
    local playerData = GetPlayerData(playerID)
    playerData.lumber = playerData.lumber + amount
    UpdateSummonerSpells(playerID)

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero then
        hero:SetAbilityPoints(playerData.lumber)
    end

    if amount > 0 then
        PopupLumber(ElementTD.vPlayerIDToHero[playerID], amount)

        if playerData.elementalCount == 0 then
            Highlight(playerData.summoner, playerID)
        end

        if GameSettings.elementsOrderName == "AllPick" then
            SendLumberMessage(playerID, "#etd_lumber_add", amount)
        end
    end

    local current_lumber = playerData.lumber
    local summoner = playerData.summoner
    if current_lumber > 0 then
        if not summoner.particle then
            local origin = summoner:GetAbsOrigin()
            local particleName = "particles/econ/courier/courier_trail_01/courier_trail_01.vpcf"
            summoner.particle = ParticleManager:CreateParticleForPlayer(particleName, PATTACH_CUSTOMORIGIN, summoner, PlayerResource:GetPlayer(playerID))
            ParticleManager:SetParticleControl(summoner.particle, 0, Vector(origin.x, origin.y, origin.z+30))
            ParticleManager:SetParticleControl(summoner.particle, 15, Vector(255,255,255))
            ParticleManager:SetParticleControl(summoner.particle, 16, Vector(1,0,0))
        end        
    else
        if summoner.particle then
            ParticleManager:DestroyParticle(summoner.particle, false)
            summoner.particle = nil
        end
    end

    CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerID), "etd_update_lumber", { lumber = current_lumber, summoner = playerData.summoner:GetEntityIndex() } )
    UpdateScoreboard(playerID)
end

function ModifyPureEssence(playerID, amount, bSkipMessage)
    GetPlayerData(playerID).pureEssence = GetPlayerData(playerID).pureEssence + amount
    UpdatePlayerSpells(playerID)
    if amount > 0 and not bSkipMessage then
        PopupEssence(ElementTD.vPlayerIDToHero[playerID], amount)
        SendEssenceMessage(playerID, "#etd_essence_add", amount)
    end
    CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(playerID), "etd_update_pure_essence", { pureEssence = GetPlayerData(playerID).pureEssence } )
    UpdateScoreboard(playerID)
end

function UpdateSummonerSpells(playerID)
    local lumber = GetPlayerData(playerID).lumber
    local summoner = GetPlayerData(playerID).summoner
    local playerData = GetPlayerData(playerID)

    UpdateRunes(playerID)

    for i=0,5 do
        local item = summoner:GetItemInSlot(i)
        if item then
            itemName = item:GetAbilityName()
            if itemName == "item_buy_pure_essence_disabled" and CanPlayerBuyPureEssence(playerID) then
                item:RemoveSelf()
                summoner:AddItem(CreateItem("item_buy_pure_essence", nil, nil))
            end
        end
    end

    if EXPRESS_MODE and not playerData.elementalActive then
        for k, v in pairs(NPC_ABILITIES_CUSTOM) do
            if summoner:HasAbility(k) and v["LumberCost"] then
                local level = playerData.elements[v["Element"]] + 1
                local ability = summoner:FindAbilityByName(k)
                if level == 1 then
                    ability:SetActivated(lumber >= v["LumberCost"] and level <= 3)
                elseif level == 2 and playerData.completedWaves >= 6 then
                    ability:SetActivated(lumber >= v["LumberCost"] and level <= 3)
                elseif level == 3 and playerData.completedWaves >= 15 then
                    ability:SetActivated(lumber >= v["LumberCost"] and level <= 3)
                else
                    ability:SetActivated(false)
                end
                ability:SetLevel(level)
            end
        end
    elseif playerData.elementalActive then
        for k, v in pairs(NPC_ABILITIES_CUSTOM) do
            if summoner:HasAbility(k) and v["LumberCost"] then
                local ability = summoner:FindAbilityByName(k)
                ability:SetActivated(false)
                ability:SetLevel(playerData.elements[v["Element"]] + 1)
            end
        end
    else
        for k, v in pairs(NPC_ABILITIES_CUSTOM) do
            if summoner:HasAbility(k) and v["LumberCost"] then
                local ability = summoner:FindAbilityByName(k)
                ability:SetActivated(lumber >= v["LumberCost"] and playerData.elements[v["Element"]] < 3)
                ability:SetLevel(playerData.elements[v["Element"]] + 1)
            end
        end
    end
end

--[[ 
      Fire Nature 
    Water    Earth 
      Dark Light
--]]
RUNES = {
    ["water"] = { model = "models/props_gameplay/rune_doubledamage01.vmdl", animation = "rune_doubledamage_anim" },
    ["fire"] = { model = "models/props_gameplay/rune_haste01.vmdl", animation = "rune_haste_idle" },
    ["nature"] = { model = "models/props_gameplay/rune_regeneration01.vmdl", animation = "rune_regeneration_anim" },
    ["earth"] = { model = "models/props_gameplay/rune_illusion01.vmdl", animation = "rune_illusion_idle" },
    ["light"] = { model = "models/props_gameplay/rune_arcane.vmdl", animation = "rune_arcane_idle" },
    ["dark"] = { model = "models/props_gameplay/rune_invisibility01.vmdl", animation = "rune_invisibility_idle" }
}

function UpdateRunes(playerID)
    local summoner = GetPlayerData(playerID).summoner
    local origin = summoner:GetAbsOrigin()
    local angle = 360/6
    local rotate_pos = origin + Vector(1,0,0) * 70
    summoner.runes = summoner.runes or {[2]={["fire"] = {}}, [1]={["nature"] = {}}, [6]={["earth"] = {}}, [5]={["light"] = {}}, [4]={["dark"] = {}}, [3]={["water"] = {}}}

    for i=1,6 do
        for element,value in pairs(summoner.runes[i]) do
            local level = GetPlayerElementLevel(playerID, element)
            if level > 0 then
                local position = RotatePosition(origin, QAngle(0, angle*i, 0), rotate_pos)
                if not value.level then
                    summoner.runes[i][element].props = CreateRune( element, position, level )
                elseif value.level ~= level then
                    ClearRunes(summoner.runes[i][element].props)
                    summoner.runes[i][element].props = CreateRune( element, position, level )
                end
                summoner.runes[i][element].level = level
            end
        end
    end
end

function CreateRune( element, position, level )
    local angle = 360/level
    local distance = level == 1 and 0 or 20
    local rotate_pos = position + Vector(1,0,0) * distance
    local props = {}

    for i=1,level do
        local rune = SpawnEntityFromTableSynchronous("prop_dynamic", {model = RUNES[element].model, DefaultAnim = RUNES[element].animation})
        local pos = RotatePosition(position, QAngle(0, angle*(i-1), 0), rotate_pos)
        rune:SetModelScale(1-level*0.1)
        rune:SetAbsOrigin(pos)

        table.insert(props, rune)
    end

    return props
end

function ClearRunes( propsTable )
    for k,v in pairs(propsTable) do
        v:RemoveSelf()
    end
end

function CanPlayerBuyPureEssence( playerID )
    local playerData = GetPlayerData(playerID)
    local elements = playerData.elements

    local hasLvl3 = false
    local hasLvl1 = true
    for i,v in pairs(elements) do
        if v == 3 then -- if level 3 of element
            hasLvl3 = true
        end
        if v == 0 then
            hasLvl1 = false
        end
    end

    return hasLvl3 or hasLvl1
end

function BuyPureEssence( keys )
	local summoner = keys.caster
    local item = keys.ability
	local playerID = summoner:GetPlayerOwnerID()
	local playerData = GetPlayerData(playerID)
	local elements = playerData.elements

    if playerData.health == 0 then
        return
    end

	if playerData.lumber > 0 then
		ModifyLumber(playerID, -1)
		ModifyPureEssence(playerID, 1)
        playerData.pureEssenceTotal = playerData.pureEssenceTotal + 1
		Sounds:EmitSoundOnClient(playerID, "General.Buy")

        -- Track pure essence purchasing as part of the element order
        playerData.elementOrder[#playerData.elementOrder+1] = "Pure"
        
        -- Gold bonus to help stay valuable by comparison to getting an element upgrade
        GivePureEssenceGoldBonus(playerID)

        item:SetCurrentCharges(item:GetCurrentCharges()-1)
        if item:GetCurrentCharges() == 0 then
            item:RemoveSelf()
        end
	else
        ShowWarnMessage(playerID, "#etd_need_more_lumber")
    end
end

function GivePureEssenceGoldBonus( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local playerData = GetPlayerData(playerID)
    local waveNumber = playerData.nextWave
    local difficultyBountyBonus = playerData.difficulty:GetBountyBonusMultiplier()
    local extra_gold
    if EXPRESS_MODE then
        extra_gold = round(math.pow(waveNumber+5, 2.3) * 2.5 * difficultyBountyBonus)
    else
        extra_gold = round(math.pow(waveNumber+5, 2) * 2.5 * difficultyBountyBonus)
    end
    PopupAlchemistGold(PlayerResource:GetSelectedHeroEntity(playerID), extra_gold)
    hero:ModifyGold(extra_gold, true, 0)
end

function BuyPureEssenceWarn( event )
    local playerID = event.caster:GetPlayerOwnerID()

    if not CanPlayerBuyPureEssence(playerID) then
        Log:info("Player " .. playerID .. " does not meet the pure essence purchase requirements.")
        ShowWarnMessage(playerID, "#etd_essence_buy_warning", 4)
    end
end

function BuyElement(playerID, element)
    local playerData = GetPlayerData(playerID)

    if playerData.lumber > 0 then
        ModifyLumber(playerID, -1)
        ModifyElementValue(playerID, element, 1)

        AddElementalTrophy(playerID, element)
    end
end

function SummonElemental(keys)
    local summoner = keys.caster
    local playerID = summoner:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)
    local element = GetUnitKeyValue(keys.Elemental.."1", "Element")
    local difficulty = playerData.difficulty

    if playerData.health == 0 then
        return
    end

    -- Explosion cast effect for each element
    local explosion = ParticleManager:CreateParticle(ExplosionParticles[element], PATTACH_CUSTOMORIGIN, summoner)
    local origin = summoner:GetAbsOrigin()
    origin.z = origin.z + 20
    ParticleManager:SetParticleControl(explosion, 0, origin)

    if playerData.elementalCount == 0 or EXPRESS_MODE then
        Sounds:PlayElementalDeathSound(playerID, element)
        BuyElement(playerID, element)
        return
    end

    playerData.elementalActive = true
    ModifyLumber(playerID, -1)

    local level = playerData.elements[element] + 1
    local name = keys.Elemental..level

    local marker_dummy = CreateUnitByName("tower_dummy", EntityStartLocations[playerData.sector + 1], false, nil, nil, PlayerResource:GetTeam(playerID))

    local elemental = CreateUnitByName(name, EntityStartLocations[playerData.sector + 1], true, nil, nil, DOTA_TEAM_NEUTRALS)
    if not elemental then
        print("Failed to spawn ",name)
        return
    end
    elemental:AddNewModifier(nil, nil, "modifier_phased", {})
    elemental["element"] = element
    elemental["isElemental"] = true
    elemental["playerID"] = playerID
    elemental["class"] = keys.Elemental
    elemental.marker_dummy = marker_dummy

    -- Spawn sound
    Sounds:PlayElementalSpawnSound(playerID, elemental)

    -- Trail effect
    local particle = ParticleManager:CreateParticle(TrailParticles[element], PATTACH_ABSORIGIN_FOLLOW, elemental)

    playerData.elementalUnit = elemental

    elemental:AddNewModifier(elemental, nil, "modifier_damage_block", {});
    --GlobalCasterDummy:ApplyModifierToTarget(elemental, "creep_damage_block_applier", "modifier_damage_block")
    --ApplyArmorModifier(elemental, GetPlayerDifficulty(playerID):GetArmorValue() * 100)
    
    -- Adjust health bar
    -- Every five waves elemental HP goes up by 50%. So if you summon a level 1 at wave 20 you get 1,519 HP.
    local health = ElementalBaseHealth[level] * math.pow(1.5, (math.floor(playerData.nextWave / 5))) * difficulty:GetHealthMultiplier()
    CustomNetTables:SetTableValue("elementals", tostring(elemental.marker_dummy:GetEntityIndex()), {health_marker=health/4})
    Timers:CreateTimer(0.03, function()
        marker_dummy:AddNewModifier(elemental.marker_dummy, nil, "modifier_health_bar_markers", {})
    end)

    local scale = elemental:GetModelScale()
    elemental:SetMaxHealth(health)
    elemental:SetBaseMaxHealth(health) -- This is needed to properly set the max health otherwise it won't work sometimes
    elemental:SetHealth(health)
    elemental:SetModelScale(scale)
    elemental:SetForwardVector(Vector(0, -1, 0))
    elemental.level = level

    local label = GetEnglishTranslation(keys.Elemental) or keys.Elemental
    if label then
        elemental:SetCustomHealthLabel(label, ElementColors[element][1], ElementColors[element][2], ElementColors[element][3])
    end

    -- Adjust slows multiplicatively
    elemental:AddNewModifier(elemental, nil, "modifier_slow_adjustment", {})

    local particle = Particles[keys.Elemental]
    if particle then
        local h = ParticleManager:CreateParticle(particle, 2, elemental) 
        ParticleManager:SetParticleControlEnt(h, 0, elemental, 5, "attach_origin", elemental:GetOrigin(), true)
    end

    Timers:CreateTimer(0.1, function()
        if not IsValidEntity(elemental) or not elemental:IsAlive() then
            elemental.marker_dummy:RemoveSelf()
            return 
        end
        
        local entity = elemental
        local destination = EntityEndLocations[playerData.sector + 1]

        ExecuteOrderFromTable({ UnitIndex = entity:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = destination, Queue = false })

        if (entity:GetAbsOrigin() - destination):Length2D() <= 100 then
            local playerData = PlayerData[playerID]

            -- Minus 3 lives
            ReduceLivesForPlayer(playerID, 3)

            Sounds:EmitSoundOnClient(playerID, "ui.click_back")
            local hero = PlayerResource:GetSelectedHeroEntity(playerID)
            CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerHealth", {playerId=playerID, health=playerData.health/hero:GetMaxHealth() * 100} )
            UpdateScoreboard(playerID)
            --Say(nil, playerData.name .. "'s Health: " .. playerData.health, false)

            FindClearSpaceForUnit(entity, EntityStartLocations[playerData.sector + 1], true)
            entity:SetForwardVector(Vector(0, -1, 0))
        end
        return 0.1
    end)
end

function AddElementalTrophy(playerID, element)
    local team = PlayerResource:GetTeam(playerID)
    local level = GetPlayerElementLevel(playerID, element)
    local unitName = element.."_elemental"..level
    local scale = GetUnitKeyValue(unitName, "ModelScale")
    local playerData = GetPlayerData(playerID)
    local summoner = playerData.summoner

    -- Elementals are placed from east to west X, at the same Y of the summoner
    playerData.elemCount = playerData.elemCount or 0 --Number of elementals killed
    local count = playerData.elemCount

    -- At 9 we make another row
    local Y = -100
    if count >= 9 then 
        Y = 100
        count = count - 9
    end

    local position = summoner:GetAbsOrigin() + Vector(750,Y,0) + count * Vector(120,0,0)
    playerData.elemCount = playerData.elemCount + 1

    local elemental = CreateUnitByName(unitName, position, false, nil, nil, team)
    elemental:SetModelScale(scale)
    elemental:SetForwardVector(Vector(0, -1, 0))

    elemental:AddNewModifier(elemental, nil, "modifier_disabled", {})
end

function ItemRandomUse(event)
    local caster = event.caster
    local item = event.ability
    local playerID = caster:GetPlayerOwnerID()

    GameSettings:EnableRandomForPlayer(playerID)
end