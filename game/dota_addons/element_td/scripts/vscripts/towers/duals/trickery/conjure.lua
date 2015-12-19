trickery_tower_conjure = class({})

LinkLuaModifier("modifier_clone", "towers/duals/trickery/modifier_clone", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_conjure_prevent_cloning", "towers/duals/trickery/modifier_conjure_prevent_cloning", LUA_MODIFIER_MOTION_NONE)

function trickery_tower_conjure:OnSpellStart()
    local caster = self:GetCaster() --The tower
    local target = self:GetCursorTarget()
    local playerID = caster:GetPlayerOwnerID()
    local playerData = GetPlayerData(playerID)

    -- Prevent the targeted tower from getting cloned again for a duration
    target:AddNewModifier(caster, self, "modifier_conjure_prevent_cloning", {duration=60})
    
    local sector = playerID + 1
    local clonePos = target:GetAbsOrigin() + RandomVector(300) --FindClosestTowerPosition(sector, target:GetOrigin(), 10000)

    -- Create Tower Building
    local clone = CreateUnitByName(target.class, clonePos, false, nil, nil, target:GetTeam()) 

    --set some variables
    clone.class = target.class
    clone.element = GetUnitKeyValue(clone.class, "Element")
    clone.damageType = GetUnitKeyValue(clone.class, "DamageType")
    clone.isClone = true
    clone.ability = self
    clone:SetOwner(PlayerResource:GetPlayer(playerID):GetAssignedHero())
    clone:SetControllableByPlayer(playerID, true)
    clone.construction_size = target.construction_size

    --color
    clone:SetRenderColor(0, 148, 255)
    local children = clone:GetChildren()
    for k,v in pairs(children) do
        if v:GetClassname() == "dota_item_wearable" then
            v:SetRenderColor(0, 148, 255)
        end
    end

    -- create a script object for this tower
    local scriptClassName = GetUnitKeyValue(clone.class, "ScriptClass")
    if not scriptClassName then scriptClassName = "BasicTower" end
    if TOWER_CLASSES[scriptClassName] then
        local scriptObject = TOWER_CLASSES[scriptClassName](clone, clone.class)
        clone.scriptClass = scriptClassName
        clone.scriptObject = scriptObject
        clone.scriptObject:OnCreated()
    else
        Log:error("Unknown script class, " .. scriptClassName .. " for tower " .. clone.class)
    end

    -- Add abilities
    AddAbility(clone, "sell_tower_0")
    AddAbility(clone, clone.damageType .. "_passive")
    if GetUnitKeyValue(clone.class, "AOE_Full") and GetUnitKeyValue(clone.class, "AOE_Half") then
        AddAbility(clone, "splash_damage_orb")
    end

    -- Add the tower to the player data
    playerData.towers[clone:GetEntityIndex()] = target.class
    playerData.clones[clone.class] = playerData.clones[clone.class] or {} --init clone table of this tower name
    playerData.clones[clone.class][clone:GetEntityIndex()] = target.class -- add this clone
    UpdateScoreboard(playerID)

    -- apply the clone modifier to the clone
    print("Making a clone for "..self.clone_duration.." seconds")
    clone:AddNewModifier(caster, nil, "modifier_no_health_bar", {})
    clone:AddNewModifier(caster, self, "modifier_clone", {duration=self.clone_duration})
    clone:AddNewModifier(caster, self, "modifier_kill", {duration=self.clone_duration})
    self.clones[clone:entindex()] = 1 --Clones for this particular tower ability

    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/illusion_created.vpcf", PATTACH_ABSORIGIN, clone)
    ParticleManager:SetParticleControl(particle, 0, clone:GetAbsOrigin() + Vector(0, 0, 64))
end

--------------------------------------------------------------

function trickery_tower_conjure:CastFilterResultTarget(target)
    local result = UnitFilter(target, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, self:GetCaster():GetTeamNumber())
    
    if result ~= UF_SUCCESS then
        return result
    end
    
    local bClone = target:HasModifier("modifier_clone")
    local bPreventCloning = target:HasModifier("modifier_conjure_prevent_cloning")
    local bSupportTower = target:HasModifier("modifier_support_tower")
    if bClone or bPreventCloning or bSupportTower then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end

function trickery_tower_conjure:GetCustomCastErrorTarget(target)
    local bClone = target:HasModifier("modifier_clone")
    local bPreventCloning = target:HasModifier("modifier_conjure_prevent_cloning")
    local bSupportTower = target:HasModifier("modifier_support_tower")

    if bSupportTower then
        return "#etd_error_support_tower"
    elseif bPreventCloning then
        return "#etd_error_recently_cloned"
    elseif bClone then
        return "#etd_error_cloned_tower"
    end

    return ""
end