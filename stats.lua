-- CONFIG
---------------------------------------------

local addonList = 50
local font = 'Fonts\\FRIZQT__.ttf'
local fontSize = 12
local fontFlag = 'THINOUTLINE'
local textAlign = 'CENTER'
local position = { "TOP", UIParent, "TOP", 0, -15 }
local customColor = false
local useShadow = true
local showClock = true
local use12 = false -- ignored if showClock is false.

-- CODE ITSELF
---------------------------------------------

local StatsFrame = CreateFrame('Frame', 'LynStats', UIParent)

local color
if customColor then
	color = { r = 0, g = 1, b = 0.7 }
else
	local _, class = UnitClass("player")
	color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
end

local gradientColor = {
    0, 1, 0,
    1, 1, 0,
    1, 0, 0
}

local function memFormat(number)
	if number > 1024 then
		return string.format("%.2f mb", (number / 1024))
	else
		return string.format("%.1f kb", floor(number))
	end
end

local function numFormat(v)
	if v > 1E10 then
		return (floor(v/1E9)).."b"
	elseif v > 1E9 then
		return (floor((v/1E9)*10)/10).."b"
	elseif v > 1E7 then
		return (floor(v/1E6)).."m"
	elseif v > 1E6 then
		return (floor((v/1E6)*10)/10).."m"
	elseif v > 1E4 then
		return (floor(v/1E3)).."k"
	elseif v > 1E3 then
		return (floor((v/1E3)*10)/10).."k"
	else
		return v
	end
end

-- http://www.wowwiki.com/ColorGradient
local function ColorGradient(perc, ...)
    if (perc > 1) then
        local r, g, b = select(select('#', ...) - 2, ...) return r, g, b
    elseif (perc < 0) then
        local r, g, b = ... return r, g, b
    end

    local num = select('#', ...) / 3

    local segment, relperc = math.modf(perc*(num-1))
    local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

    return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local function RGBGradient(num)
    local r, g, b = ColorGradient(num, unpack(gradientColor))
    return r, g, b
end

local function RGBToHex(r, g, b)
    r = r <= 1 and r >= 0 and r or 0
    g = g <= 1 and g >= 0 and g or 0
    b = b <= 1 and b >= 0 and b or 0
    return string.format('|cff%02x%02x%02x', r*255, g*255, b*255)
end

local function addonCompare(a, b)
	return a.memory > b.memory
end

local function clearGarbage()
	UpdateAddOnMemoryUsage()
	local before = gcinfo()
	collectgarbage()
	UpdateAddOnMemoryUsage()
	local after = gcinfo()
	print("|c0000ddffCleaned:|r "..memFormat(before-after))
end

StatsFrame:EnableMouse(true)
StatsFrame:SetScript("OnMouseDown", function()
	clearGarbage()
end)

local function getFPS()
	return "|c00ffffff" .. floor(GetFramerate()) .. "|r fps"
end

local function getLatencyWorldRaw()
	return select(4, GetNetStats())
end

local function getLatencyWorld()
	return "|c00ffffff" .. getLatencyWorldRaw() .. "|r ms"
end

local function getLatencyRaw()
	return select(3, GetNetStats())
end

local function getLatency()
	return "|c00ffffff" .. getLatencyRaw() .. "|r ms"
end

local function getMail()
	if HasNewMail() ~= false then
		return "|c00ff00ffMail!|r"
	else
		return ""
	end
end

local function getTime()
	if use12 == true then
		local t = date("%I:%M")
		local ampm = date("%p")
		return "|c00ffffff"..t.."|r "..strlower(ampm)
	else
		local t = date("%H:%M")
		return "|c00ffffff"..t.."|r"
	end
end

local function addonTooltip(self)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	local blizz = collectgarbage("count")
	local addons = {}
	local enry, memory
	local total = 0
	local nr = 0
	UpdateAddOnMemoryUsage()
	GameTooltip:AddLine("AddOns", color.r, color.g, color.b)
	--GameTooltip:AddLine(" ")
	for i=1, GetNumAddOns(), 1 do
		if (GetAddOnMemoryUsage(i) > 0 ) then
			memory = GetAddOnMemoryUsage(i)
			entry = {name = GetAddOnInfo(i), memory = memory}
			table.insert(addons, entry)
			total = total + memory
		end
	end
	table.sort(addons, addonCompare)
	for _, entry in pairs(addons) do
		if nr < addonList then
			GameTooltip:AddDoubleLine(entry.name, memFormat(entry.memory), 1, 1, 1, RGBGradient(entry.memory / 800))
			nr = nr+1
		end
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Total", memFormat(total), 1, 1, 1, RGBGradient(total / (1024*10)))
	GameTooltip:AddDoubleLine("Total incl. Blizzard", memFormat(blizz), 1, 1, 1, RGBGradient(blizz / (1024*10)))
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Network", color.r, color.g, color.b)
	--GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Home", getLatencyRaw().." ms", 1, 1, 1, RGBGradient(getLatencyRaw()/ 100))
	GameTooltip:AddDoubleLine("World", getLatencyWorldRaw().." ms", 1, 1, 1, RGBGradient(getLatencyWorldRaw()/ 100))
	GameTooltip:Show()
end

StatsFrame:SetScript("OnEnter", function()
	addonTooltip(StatsFrame)
end)
StatsFrame:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

StatsFrame:SetPoint(unpack(position))
StatsFrame:SetWidth(50)
StatsFrame:SetHeight(fontSize)

StatsFrame.text = StatsFrame:CreateFontString(nil, 'BACKGROUND')
StatsFrame.text:SetPoint(textAlign, StatsFrame)
StatsFrame.text:SetFont(font, fontSize, fontFlag)
if useShadow then
	StatsFrame.text:SetShadowOffset(1, -1)
	StatsFrame.text:SetShadowColor(0, 0, 0)
end
StatsFrame.text:SetTextColor(color.r, color.g, color.b)

local lastUpdate = 0

local function update(self,elapsed)
	lastUpdate = lastUpdate + elapsed
	if lastUpdate > 1 then
		lastUpdate = 0
		if showClock == true then
			StatsFrame.text:SetText(getFPS().." "..getLatency().." "..getMail().." "..getTime())
		else
			StatsFrame.text:SetText(getFPS().." "..getLatency().." "..getMail())
		end
		self:SetWidth(StatsFrame.text:GetStringWidth())
		self:SetHeight(StatsFrame.text:GetStringHeight())
	end
end

StatsFrame:SetScript("OnEvent", function(self, event)
	if(event=="PLAYER_LOGIN") then
		self:SetScript("OnUpdate", update)
	end
end)
StatsFrame:RegisterEvent("PLAYER_LOGIN")