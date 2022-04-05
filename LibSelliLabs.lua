local projectName = "SelliLabs"
local major = "1.0"
local minor = 0
local currentMajorVersion = projectName.."-"..major
local utilitiesVersion = projectName.."-Utilities-"..major
local stateVersion = projectName.."-State-"..major

assert(LibStub, format("%s requires LibStub", currentMajorVersion))

local Lib = LibStub:NewLibrary(currentMajorVersion, minor)
if not Lib then return end

Lib.Utilities = Lib.Utilities or LibStub(utilitiesVersion)
if not Lib.Utilities then error(major.." requires "..utilitiesVersion) end

Lib.State = Lib.State or LibStub(stateVersion)
if not Lib.State then error(major.." requires "..stateVersion) end

local EVENT_TYPES = {
  SELLI_SPELL_PULSE = "SELLI_SPELL_PULSE",
  PLAYER_TARGET_CHANGED = "PLAYER_TARGET_CHANGED",
  SPELL_COOLDOWN_CHANGED = "SPELL_COOLDOWN_CHANGED",
  SPELL_COOLDOWN_READY = "SPELL_COOLDOWN_READY",
  SPELL_UPDATE_COOLDOWN = "SPELL_UPDATE_COOLDOWN"
}

function Lib:GCD(...) return self.Utilities:GCD(...) end
function Lib:Throttle(...) return self.Utilities:Throttle(...) end
function Lib:SetColor(...) return self.Utilities:SetColor(...) end
function Lib:InRange(...) return self.Utilities:InRange(...) end
function Lib:SetupWatchers(...) return self.Utilities:SetupWatchers(...) end
function Lib:SpellIsReadyInState(...) return self.Utilities:SpellIsReadyInState(...) end
function Lib:SortGroup(...) return self.Utilities:SortGroup(...) end
function Lib:GetAura(...) return self.Utilities:GetAura(...) end
function Lib:GetAuraAbsorbValue(...) return self.Utilities:GetAuraAbsorbValue(...) end

function Lib:SendPulse(allstates, spellId, duration)
  if spellId then
    local expiration = _G.GetTime() + duration
    local name = "SELLI_PULSE"..spellId
    
    allstates[name] = self.State:GetNewState(true, duration, expiration, _G.GetSpellTexture(spellId), name)
    
    return true
  end
end

function Lib:Uptime(aura, allstates)   
  local config = aura.config
  local spells = config.spells
  
  local processed = {}
  
  for key,value in pairs(spells) do
      local settings = {}
      for settingName, settingValue in pairs(value) do
          if settingName == "spell" then
              settings.spell = settingValue
          end
          if settingName == "unit" then
              settings.unit = settingValue == 1 and "player" or "target"
          end
          if settingName == "type" then
              settings.type = settingValue == 1 and "buff" or "debuff"
          end
          if settingName == "settings" then              
              settings.stacks = settingValue[1];
              settings.show = settingValue[2];
              settings.glow = settingValue[3];
              settings.progress = settingValue[4];
              settings.absorb = settingValue[5];
          end
      end        
      
      self.State:LoopAuras(settings.spell, settings, allstates, processed)

      if self.State:ShouldResetState(processed[settings.spell], settings.show) then
        self.State:ResetState(allstates, settings.spell)
      end
  end
  
  return true
end

function Lib:Trinkets(aura, allstates)
    local config = aura.config
    local trinkets = config.trinkets  

    local processed = {}
    
    for trinketName,value in pairs(trinkets) do         
      local settings = {}
      for settingName, settingValue in pairs(value) do
          if settingName == "settings" then
              settings = {
                  stacks = settingValue[1],
                  absorb = settingValue[2],
                  show = settingValue[3],
                  glow = settingValue[4],
                  progress = settingValue[5],
                  unit = "player"
              }
          end
      end
      self.State:LoopAuras(trinketName, settings, allstates, processed)
    end

    return true
end

function Lib:Abilities(aura, allstates, event, eventSpellId)
  local config = aura.config
  local abilities = config.abilities

  for key,value in pairs(abilities) do
      local settings = {}
      for settingName, settingValue in pairs(value) do
          if settingName == "ability" then
              settings.ability = settingValue
          end
          if settingName == "settings" then
              settings.stacks = settingValue[1];
              settings.show = settingValue[2];
              settings.glow = settingValue[3];
              settings.progress = settingValue[4];
              settings.sound = settingValue[5];
              settings.pulse = settingValue[6]
          end
          if settingName == "sound" then
              settings.soundFile = settingValue
          end
      end

      local spellName, spellRank, spellIcon, spellCastTime, spellMinRange, spellMaxRange, spellId = _G.GetSpellInfo(settings.ability)
      local spellChargeCurrent, spellChargeMax, spellChargeCdStart, spellChargeCdDuration = _G.GetSpellCharges(settings.ability)

      if event == EVENT_TYPES.SPELL_COOLDOWN_READY and eventSpellId == spellId and settings.pulse then
        if spellChargeMax > 0 then
          if spellChargeCurrent == spellChargeMax then
            WeakAuras.ScanEvents(EVENT_TYPES.SELLI_SPELL_PULSE, spellId, _G.GetTime())
          end
        else
          WeakAuras.ScanEvents(EVENT_TYPES.SELLI_SPELL_PULSE, spellId, _G.GetTime())
        end
      end
      
      settings.show = settings.show and spellName

      if settings.show then
          local spellCooldownStart, spellCooldownDuration, spellCooldownEnabled, _ = _G.GetSpellCooldown(settings.ability)          
          
          local state = self.State:GetNewState(
            false,
            (settings.stacks and spellChargeCurrent < spellChargeMax) and spellChargeCdDuration or spellCooldownDuration,
            (settings.stacks and spellChargeCurrent < spellChargeMax) and spellChargeCdStart + spellChargeCdDuration or spellCooldownStart + spellCooldownDuration,
            spellIcon,
            settings.ability,
            "player",
            (settings.stacks and spellChargeCurrent > 0) and spellChargeCurrent or settings.stacks and "0" or nil,
            settings.glow,
            settings.progress
          )
          state.spellId = spellId
          state.sound = settings.sound
          state.soundFile = settings.soundFile
          state.pulse = settings.pulse

          allstates[settings.ability] = state;
      end
  end     
  return true
end