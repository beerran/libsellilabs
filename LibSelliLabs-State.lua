local projectName = "SelliLabs-State"
local major = "1.0"
local minor = 0
local currentMajorVersion = projectName.."-"..major
local utilitiesVersion = "SelliLabs-Utilities-"..major

assert(LibStub, format("%s requires LibStub", currentMajorVersion))
local Lib = LibStub:NewLibrary(currentMajorVersion, minor)
if not Lib then return end

Lib.Utilities = Lib.Utilities or LibStub(utilitiesVersion)
if not Lib.Utilities then error(major.." requires "..utilitiesVersion) end

function Lib:GetNewState(autoHide, duration, expirationTime, icon, name, caster, stacks, glow, progress)    
    local state = {
      show = true,
      changed = true,
      progressType = "timed",
      autoHide = autoHide,
      duration = duration,
      expirationTime = expirationTime,
      icon = icon,
      name = name,
      caster = caster
    }
  
    if (stacks) then state.stacks = stacks end
    if (glow) then state.glow = glow end
    if (progress) then state.progress = progress end
  
    return state
end
  
function Lib:ResetState(allstates, name)
    allstates[name] = {
      show = false,
      changed = true,
      name = name
    }
end
  
function Lib:ShouldResetState(processed, condition) 
    return processed == nil or processed == false or condition == false
end
  
function Lib:LoopAuras(key, settings, allstates, processed)
    local index = 1
    local auraName, auraIcon, auraStacks, _, auraDuration, auraExpiration, auraSource, _, _, auraSpellId = self.Utilities:GetAura("player", index)
    
    settings.show = settings.show and auraName
  
    while auraName do
        if auraName == key and settings.show then
            local state = self:GetNewState(
              true,
              auraDuration,
              auraExpiration,
              auraIcon,
              key,
              auraSource,
              settings.stacks and auraStacks or nil,
              settings.glow,
              settings.progress
            )
            state.unit = settings.unit
            state.unitBuffIndex = index
            state.absorbValue = settings.absorb and self.Utilities:GetAuraAbsorbValue(settings.unit, index) or nil
  
            allstates[key] = state
            processed[key] = true
        elseif self:ShouldResetState(processed[key], settings.show) then
            self:ResetState(allstates, key)
        end
        
        index = index + 1 
        auraName, auraIcon, auraStacks, _, auraDuration, auraExpiration, auraSource, _, _, auraSpellId = self.Utilities:GetAura("player", index)
    end
end