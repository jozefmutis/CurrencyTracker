local AddonName, Addon = ...

local CurrencyTracker = {}
Addon.CurrencyTracker = CurrencyTracker

CurrencyTracker.modules = {}

CurrencyTracker.events = CreateFrame("Frame")
CurrencyTracker.events:RegisterEvent("ADDON_LOADED")

CurrencyTracker.events:SetScript("OnEvent", function(self, event, ...)
	CurrencyTracker[event](CurrencyTracker, ...)
end)

local db, player, realm, faction, class, gold, tokens

CurrencyTracker.defaultDB = {
	realms = {}
}

function CurrencyTracker:ADDON_LOADED(addon)
	if addon == AddonName then
		for moduleName, module in pairs(self.modules) do
			module:OnLoad()
		end

		self:PrepareDB()

		self:RegisterEvents()
		self.events:UnregisterEvent("ADDON_LOADED")
	end
end

function CurrencyTracker:RegisterEvents()
	-- Register other main events here
	self.events:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.events:RegisterEvent("PLAYER_MONEY")
	self.events:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	self.events:RegisterEvent("PLAYER_LOGOUT")
end

function CurrencyTracker:PLAYER_ENTERING_WORLD()
	-- Player entered the world and every module is loaded, global API calls should work
	CurrencyTracker:UpdateTokens()
	CurrencyTracker:UpdateMoney()
	self.events:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function CurrencyTracker:PLAYER_MONEY()
	CurrencyTracker:UpdateMoney()
end

function CurrencyTracker:CURRENCY_DISPLAY_UPDATE()
	CurrencyTracker:UpdateTokens()
end

function CurrencyTracker:PLAYER_LOGOUT()

	--self.events:UnregisterAllEvents()
end

function CurrencyTracker:PrepareDB()
	CurrencyTrackerDB = CurrencyTrackerDB or CopyTable(self.defaultDB)
	for k, v in pairs(self.defaultDB) do
		if CurrencyTrackerDB[k] == nil then -- don't reset any false values
			CurrencyTrackerDB[k] = v
		end
	end

	db = CurrencyTrackerDB

	local realmname, playername, factionname, money, classname = GetRealmName(), GetUnitName("player", false), select(1,UnitFactionGroup("player")), GetMoney(), select(2,UnitClass("player"))
	db.realms[realmname] = db.realms[realmname] or {}
	realm = db.realms[realmname]

	db.realms[realmname][playername] = db.realms[realmname][playername] or {}
	player = db.realms[realmname][playername]

	player.faction = factionname
	faction = player.faction

	player.class = classname
	class = player.class

	db.realms[realmname][playername].tokens = db.realms[realmname][playername].tokens or {}
	tokens = db.realms[realmname][playername].tokens
end

function CurrencyTracker:UpdateMoney()
	local money =  GetMoney()
	--player.gold = player.gold or "n/a"
	player.gold = money
end

function CurrencyTracker:UpdateTokens()
	for i=1,GetNumWatchedTokens() do
		local name, count, extraCurrencyType, icon, itemid = GetBackpackCurrencyInfo(i)
		tokens[i] = {}
		tokens[i].itemid = itemid
		tokens[i].name = name
		tokens[i].count = count
		if extraCurrencyType == 1 then
			tokens[i].icon = "Interface\\PVPFrame\\PVP-ArenaPoints-Icon"
		elseif extraCurrencyType == 2 then
			tokens[i].icon = "Interface\\TargetingFrame\\UI-PVP-"..faction
			tokens[i]["tex_params"] = ":0:0:64:64:1:31:1:31"
		else
			tokens[i].icon = icon
		end
	end
end

function CurrencyTracker:PrintMoney(faction)
	local factionname = select(1,UnitFactionGroup("player"))

	local function Print(faction_param, divider)
		local function RGBPercToHex(r, g, b)
			r = r <= 1 and r >= 0 and r or 0
			g = g <= 1 and g >= 0 and g or 0
			b = b <= 1 and b >= 0 and b or 0
			return string.format("ff%02x%02x%02x", r*255, g*255, b*255)
		end
		local g = "|TInterface\\MoneyFrame\\UI-GoldIcon:12|t "
		local s = "|TInterface\\MoneyFrame\\UI-SilverIcon:12|t "
		local c = "|TInterface\\MoneyFrame\\UI-CopperIcon:12|t"
		local total, numchars = 0, 0
		for k, v in pairs(realm) do
			if v.faction == faction_param and v.gold then
				numchars = numchars + 1
				local color = "ff7f7f7f"
				local class = v.class
				--if v.class then color = RAID_CLASS_COLORS[v.class].colorStr end
				if class then color = RGBPercToHex(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b) end
				local money = floor((v.gold/100/100))..g..floor(((v.gold/100)%100))..s..(v.gold%100)..c
				local tokenlist = ",   "
				for i, t in ipairs(v.tokens) do
					local tex_params = t.tex_params or ""
					tokenlist = tokenlist .. t.count.."|T"..t.icon..":14:14"..tex_params.."|t "
				end

				total = total + v.gold
				print("".."|c"..color..k.."|r"..": "..money..tokenlist)
			end
		end
		local color
		if faction_param == "Horde" then color="ffb30000" else color="ff0078ff" end
		if numchars > 0 then
			print("".."|c"..color..faction_param.."|r".." total: "..floor((total/100/100))..g..floor(((total/100)%100))..s..(total%100)..c)
			if faction_param == "Alliance" and divider then
				print(" ---")
			end
		end
	end

	if faction == 1 then
		Print("Alliance")
	elseif faction == 2 then
		Print("Horde")
	elseif faction == 3 then
		Print("Alliance", true)
		Print("Horde")
	else
		Print(factionname)
	end
end

SLASH_CURRENCYTRACKER1 = "/money"
SLASH_CURRENCYTRACKER2 = "/currencytracker"
SlashCmdList["CURRENCYTRACKER"] = function(msg, editbox)
	CurrencyTracker:PrintMoney()
end 