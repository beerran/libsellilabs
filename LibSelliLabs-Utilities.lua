local projectName = "SelliLabs-Utilities"
local major = "1.0"
local minor = 0
local currentMajorVersion = projectName.."-"..major

assert(LibStub, format("%s requires LibStub", currentMajorVersion))
local Lib = LibStub:NewLibrary(currentMajorVersion, minor)
if not Lib then return end

function Lib:GCD()
    return 1.5 / (_G.UnitSpellHaste("player") * 0.01 + 1)
end
  
function Lib:Throttle(aura, seconds)
    local throttle = aura.throttle

    if not throttle or throttle < _G.GetTime() - seconds then
    throttle = _G.GetTime()
    return true 
    end
end
  
function Lib:SetColor(aura, color)
    if color == nil then
        color = {[1] = 255, [2] = 255, [3] = 255, [4] = 100}
    end

    local r, g, b, a = color[1], color[2], color[3], color[4]
    
    aura.region:Color(r, g, b, a)
end
  
function Lib:InRange(spell, unit)
    local spellRange = LibStub("SpellRange-1.0")
  
    local inRange = _G.UnitExists(unit) and _G.UnitIsVisible(unit) and spellRange.IsSpellInRange(spell, unit) or nil
    
    return inRange == nil and false or inRange == 0
end
  
function Lib:SetupWatchers(aura)
    for key,value in pairs(aura.config.abilities) do
        for settingName,settingValue in pairs(value) do
            if settingName == "ability" then
                local _, _, _, _, _, _, spellId = _G.GetSpellInfo(settingValue)
                if spellId then
                    WeakAuras.WatchSpellCooldown(spellId)
                end
            end
        end
    end
end
  
function Lib:SpellIsReadyInState(state, treatChargeAsReady)
    local current, max = _G.GetSpellCharges(state.spellId)    
    if max and state.stacks and max > 0 then
        return treatChargeAsReady and current > 0 or current == max
    end
    
    if state.expirationTime > _G.GetTime() and state.duration > self:GCD() then      
        return false
    end
    return true
end
  
function Lib:SortGroup(a, b, configKey, propertyKey)     
    if a.data.config == nil or b.data.config == nil then
        return a.dataIndex <= b.dataIndex
    end

    local currentOrder, nextOrder

    for i,v in pairs(a.data.config[configKey]) do
        if a.cloneId == v[propertyKey] then
            currentOrder = i
        end
    end    
    
    for i,v in pairs(b.data.config[configKey]) do
        if b.cloneId == v[propertyKey] then
            nextOrder = i
        end
    end
    
    return currentOrder <= nextOrder
end
  
function Lib:GetAura(unit, index, type)
    if type == nil then
      return _G.UnitAura(unit, index)
    else
      if unit == "player" then
        return _G.UnitAura(unit, index)
      else
        return _G.UnitAura(unit, index, "PLAYER|"..type == "buff" and "HELPFUL" or "HARMFUL")
      end
    end
end
  
function Lib:GetAuraAbsorbValue(unit, index)
    return _G.select(16, _G.UnitBuff(unit, index))
end