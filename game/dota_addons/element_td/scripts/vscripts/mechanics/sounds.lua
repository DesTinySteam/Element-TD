if not Sounds then
  Sounds = class({})
end

function Sounds:Start()
    
end

function Sounds:EmitSoundOnClient( playerID, sound )
    local player = PlayerResource:GetPlayer(playerID)

    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "emit_client_sound", {sound=sound})
        return true
    else
        print("ERROR - No player with ID",playerID)
    end
    return false
end

function Sounds:PlayElementalSpawnSound(playerID, unit)
    local spawnSound = ElementalSounds[unit.element.."_spawn"]
    if spawnSound then
        unit:EmitSound(spawnSound)
    end
end

function Sounds:PlayElementalDeathSound(playerID, unit)
    local deathSound
    local emitUnit = unit
    if type(unit)=="string" then
        emitUnit = GetPlayerData(playerID).summoner
        deathSound = ElementalSounds[unit.."_death"]      
    else
        deathSound = ElementalSounds[unit.element.."_death"]
    end

    if deathSound then
        emitUnit:EmitSound(deathSound)
    end
end

Sounds:Start()