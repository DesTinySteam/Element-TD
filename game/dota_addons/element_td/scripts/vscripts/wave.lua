Wave = createClass({
		constructor = function(self, playerID, waveNumber)
			self.playerID = playerID
			self.playerData = GetPlayerData(self.playerID)

			self.waveNumber = waveNumber
			self.creepsRemaining = CREEPS_PER_WAVE
			self.creeps = {}
			self.startTime = 0
			self.endTime = 0
			self.leaks = 0
			self.kills = 0
			self.callback = nil
		end
	},
{}, nil)

function Wave:GetWaveNumber()
	return self.waveNumber
end

function Wave:GetCreeps()
	return self.creeps
end

-- call the callback when the player beats this wave
function Wave:SetOnCompletedCallback(func)
	self.callback = func
end

function Wave:OnCreepKilled(index)
	if self.creeps[index] then
		self.creeps[index] = nil
		self.creepsRemaining = self.creepsRemaining - 1
		self.kills = self.kills + 1

		-- Remove from scoreboard count
		local playerData = GetPlayerData(self.playerID)
		playerData.remaining = playerData.remaining - 1		
		UpdateScoreboard(self.playerID)

		if self.creepsRemaining == 0 and self.callback then
			self.endTime = GameRules:GetGameTime()
			self.callback()
		end
	end
end

function Wave:RegisterCreep(index)
	if not self.creeps[index] then
		self.creeps[index] = index
	else
		Log:warn("Attemped to register creep " .. index .. " which is already register!")
	end
end

function Wave:SpawnWave()
	local playerData = GetPlayerData(self.playerID)
	local difficulty = playerData.difficulty
	local startPos = EntityStartLocations[playerData.sector + 1]
	local entitiesSpawned = 0
	local sector = playerData.sector + 1
	local ply = PlayerResource:GetPlayer(self.playerID)

	if ply then
		EmitSoundOnClient("ui.contract_complete", ply)
	end

	self.startTime = GameRules:GetGameTime() + 0.5
	self.leaks = 0
	self.kills = 0

	self.spawnTimer = Timers:CreateTimer("SpawnWave"..self.waveNumber..self.playerID, {
		endTime = 0.5,
		callback = function()
			if playerData.health == 0 then
				return nil
			end
			local entity = SpawnEntity(WAVE_CREEPS[self.waveNumber], self.playerID, startPos)
			if entity then
				self:RegisterCreep(entity:entindex())
				entity:SetForwardVector(Vector(0, -1, 0))
				entity:CreatureLevelUp(self.waveNumber-entity:GetLevel())
				entity.waveObject = self
				entitiesSpawned = entitiesSpawned + 1

				-- set bounty values
				local bounty = difficulty:GetBountyForWave(self.waveNumber)
				entity:SetMaximumGoldBounty(bounty)
				entity:SetMinimumGoldBounty(bounty)

				-- set max health based on wave
				local health = WAVE_HEALTH[self.waveNumber] * difficulty:GetHealthMultiplier()
				entity:SetMaxHealth(health)
				entity:SetBaseMaxHealth(health)
				entity:SetHealth(entity:GetMaxHealth())

				-- Boss mode
				if self.waveNumber == WAVE_COUNT and not EXPRESS_MODE then
					local bossHealth = WAVE_HEALTH[self.waveNumber] * difficulty:GetHealthMultiplier() * (math.pow(1.2,playerData.bossWaves))
					entity:SetMaxHealth(bossHealth)
					entity:SetBaseMaxHealth(bossHealth)
					entity:SetHealth(entity:GetMaxHealth())
				end

				entity.scriptObject:OnSpawned() -- called the OnSpawned event

				CreateMoveTimerForCreep(entity, sector)
				if entitiesSpawned == CREEPS_PER_WAVE then
					ClosePortalForSector(self.playerID, sector)

					-- Endless waves are started as soon as the wave finishes spawning
					if GameSettings:GetEndless() == "Endless" then
						playerData.nextWave = playerData.nextWave + 1

						-- Boss Waves
				        if playerData.nextWave > WAVE_COUNT and not EXPRESS_MODE then
				        	playerData.bossWaves = playerData.bossWaves + 1
				            Log:info("Spawning boss wave " .. playerData.bossWaves .. " for ["..self.playerID.."] ".. playerData.name)
				            ShowBossWaveMessage(self.playerID, playerData.bossWaves + 1)
				            SpawnWaveForPlayer(self.playerID, WAVE_COUNT) -- spawn dat boss wave
				            return nil
				        elseif playerData.nextWave > WAVE_COUNT and EXPRESS_MODE then
				        	return nil
				        end
						StartBreakTime(self.playerID, GetPlayerDifficulty(self.playerID):GetWaveBreakTime(playerData.nextWave))

						-- Update UI for dead players
						StartBreakTime_DeadPlayers(self.playerID, GetPlayerDifficulty(self.playerID):GetWaveBreakTime(playerData.nextWave), playerData.nextWave)
					end
					return nil
				else
					return 0.5
				end
			end
		end
	})
end