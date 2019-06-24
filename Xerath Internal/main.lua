local version = "1.0"
local evade = module.seek("evade")
local common = module.load("Xerathplus", "common")
local orb = module.internal("orb")
local TS = module.internal("TS")
local preds = module.internal("pred")

local spellE = {
	range = 975 - 30,
	delay = 0.2,
	width = 60,
	speed = 1400,
	boundingRadiusMod = 1,
	collision = {
		wall = true,
		minion = true
	}
}

local interruptableSpells = {
	["anivia"] = {
		{menuslot = "R", slot = 3, spellname = "glacialstorm", channelduration = 6}
	},
	["caitlyn"] = {
		{menuslot = "R", slot = 3, spellname = "caitlynaceinthehole", channelduration = 1}
	},
	["ezreal"] = {
		{menuslot = "R", slot = 3, spellname = "ezrealtrueshotbarrage", channelduration = 1}
	},
	["fiddlesticks"] = {
		{menuslot = "W", slot = 1, spellname = "drain", channelduration = 5},
		{menuslot = "R", slot = 3, spellname = "crowstorm", channelduration = 1.5}
	},
	["gragas"] = {
		{menuslot = "W", slot = 1, spellname = "gragasw", channelduration = 0.75}
	},
	["janna"] = {
		{menuslot = "R", slot = 3, spellname = "reapthewhirlwind", channelduration = 3}
	},
	["karthus"] = {
		{menuslot = "R", slot = 3, spellname = "karthusfallenone", channelduration = 3}
	}, --common.IsValidTargetTarget will prevent from casting @ karthus while he's zombie
	["katarina"] = {
		{menuslot = "R", slot = 3, spellname = "katarinar", channelduration = 2.5}
	},
	["lucian"] = {
		{menuslot = "R", slot = 3, spellname = "lucianr", channelduration = 2}
	},
	["lux"] = {
		{menuslot = "R", slot = 3, spellname = "luxmalicecannon", channelduration = 0.5}
	},
	["malzahar"] = {
		{menuslot = "R", slot = 3, spellname = "malzaharr", channelduration = 2.5}
	},
	["masteryi"] = {
		{menuslot = "W", slot = 1, spellname = "meditate", channelduration = 4}
	},
	["missfortune"] = {
		{menuslot = "R", slot = 3, spellname = "missfortunebullettime", channelduration = 3}
	},
	["nunu"] = {
		{menuslot = "R", slot = 3, spellname = "absolutezero", channelduration = 3}
	},
	--excluding Orn's Forge Channel since it can be cancelled just by attacking him
	["pantheon"] = {
		{menuslot = "R", slot = 3, spellname = "pantheonrjump", channelduration = 2}
	},
	["shen"] = {
		{menuslot = "R", slot = 3, spellname = "shenr", channelduration = 3}
	},
	["twistedfate"] = {
		{menuslot = "R", slot = 3, spellname = "gate", channelduration = 1.5}
	},
	["varus"] = {
		{menuslot = "Q", slot = 0, spellname = "varusq", channelduration = 4}
	},
	["warwick"] = {
		{menuslot = "R", slot = 3, spellname = "warwickr", channelduration = 1.5}
	},
	["xerath"] = {
		{menuslot = "R", slot = 3, spellname = "xerathlocusofpower2", channelduration = 3}
	}
}

local menu = menu("Xerathplus", "Xerath Internal+")

menu:menu("Gap", "Gapcloser Settings")
menu.Gap:boolean("GapA", "Use E for Anti-Gapclose", true)
menu:menu("interrupt", "Interrupt Settings")
menu.interrupt:boolean("inte", "Use E to Interrupt", true)
menu.interrupt:menu("interruptmenu", "Interrupt Settings")
for i = 1, #common.GetEnemyHeroes() do
	local enemy = common.GetEnemyHeroes()[i]
	local name = string.lower(enemy.charName)
	if enemy and interruptableSpells[name] then
		for v = 1, #interruptableSpells[name] do
			local spell = interruptableSpells[name][v]
			menu.interrupt.interruptmenu:boolean(
				string.format(tostring(enemy.charName) .. tostring(spell.menuslot)),
				"Interrupt " .. tostring(enemy.charName) .. " " .. tostring(spell.menuslot),
				true
			)
		end
	end
end
menu:menu("draws", "Draw Settings")

menu.draws:boolean("drawq", "Draw Q Range", true)
menu.draws:color("colorq", "  ^- Color", 255, 153, 153, 255)
menu.draws:boolean("draww", "Draw W Range", false)
menu.draws:color("colorw", "  ^- Color", 255, 153, 153, 255)
menu.draws:boolean("drawe", "Draw E Range", true)
menu.draws:color("colore", "  ^- Color", 255, 153, 153, 255)
menu.draws:boolean("drawr", "Draw R Range", true)
menu.draws:color("colorr", "  ^- Color", 255, 153, 153, 255)
menu.draws:boolean("drawdamage", "Draw R Damage", true)

local function AutoInterrupt(spell)
	if menu.interrupt.inte:get() then
		if spell.owner.type == TYPE_HERO and spell.owner.team == TEAM_ENEMY then
			local enemyName = string.lower(spell.owner.charName)
			if interruptableSpells[enemyName] then
				for i = 1, #interruptableSpells[enemyName] do
					local spellCheck = interruptableSpells[enemyName][i]
					if
						menu.interrupt.interruptmenu[spell.owner.charName .. spellCheck.menuslot]:get() and
							string.lower(spell.name) == spellCheck.spellname
					 then
						if player.pos2D:dist(spell.owner.pos2D) < spellE.range and common.IsValidTarget(spell.owner) then
							local pos = preds.linear.get_prediction(spellE, spell.owner)
							if pos and pos.startPos:dist(pos.endPos) < spellE.range then
								if not preds.collision.get_prediction(spellE, pos, spell.owner) then
									player:castSpell("pos", 2, spell.owner.pos)
								end
							end
						end
					end
				end
			end
		end
	end
end
local function OnTick()
	if menu.Gap.GapA:get() then
		local seg = {}
		local target =
			TS.get_result(
			function(res, obj, dist)
				if dist <= spellE.range and obj.path.isActive and obj.path.isDashing then --add invulnverabilty check
					res.obj = obj
					return true
				end
			end
		).obj
		if target then
			local pred_pos = preds.core.lerp(target.path, network.latency + spellE.delay, target.path.dashSpeed)
			if pred_pos and pred_pos:dist(player.path.serverPos2D) <= spellE.range then
				seg.startPos = player.path.serverPos2D
				seg.endPos = vec2(pred_pos.x, pred_pos.y)

				if not preds.collision.get_prediction(spellE, seg, target.pos:to2D()) then
					player:castSpell("pos", 2, vec3(pred_pos.x, target.y, pred_pos.y))
				end
			end
		end
	end

	if common.CheckBuff(player, "xerathrshots") then
		if (evade) then
			evade.core.set_pause(math.huge)
		end
	else
		evade.core.set_pause(0)
	end
end

local RLevelDamage = {200, 240, 280}
function RDamage(target)
	local meow = 0
	if player:spellSlot(3).level == 1 then
		meow = 3
	end
	if player:spellSlot(3).level == 2 then
		meow = 4
	end
	if player:spellSlot(3).level == 3 then
		meow = 5
	end
	local damage = 0
	if player:spellSlot(3).level > 0 then
		damage =
			common.CalculateMagicDamage(target, (RLevelDamage[player:spellSlot(3).level] + (common.GetTotalAP() * .43)), player)
	end
	return damage * meow
end

local function OnDraw()
	if menu.draws.drawq:get() then
		graphics.draw_circle(player.pos, 1450, 2, menu.draws.colorq:get(), 80)
	end
	if menu.draws.drawr:get() then
		if player:spellSlot(3).level == 1 then
			minimap.draw_circle(player.pos, 3520, 2, menu.draws.colorr:get(), 30)
			graphics.draw_circle(player.pos, 3520, 2, menu.draws.colorr:get(), 30)
		end
		if player:spellSlot(3).level == 2 then
			minimap.draw_circle(player.pos, 4840, 2, menu.draws.colorr:get(), 30)
			graphics.draw_circle(player.pos, 4840, 2, menu.draws.colorr:get(), 30)
		end
		if player:spellSlot(3).level == 3 then
			minimap.draw_circle(player.pos, 6160, 2, menu.draws.colorr:get(), 30)
			graphics.draw_circle(player.pos, 6160, 2, menu.draws.colorr:get(), 30)
		end
	end

	if menu.draws.draww:get() then
		graphics.draw_circle(player.pos, 1100, 2, menu.draws.colorw:get(), 80)
	end
	if menu.draws.drawe:get() then
		graphics.draw_circle(player.pos, 1050, 2, menu.draws.colore:get(), 80)
	end

	if menu.draws.drawdamage:get() then
		for i = 0, objManager.enemies_n - 1 do
			local obj = objManager.enemies[i]
			if obj and obj.isVisible and obj.team == TEAM_ENEMY and obj.isOnScreen then
				--GetBestQLocation(obj)

				local hp_bar_pos = obj.barPos
				local xPos = hp_bar_pos.x + 164
				local yPos = hp_bar_pos.y + 122.5
				local Rdmg = player:spellSlot(3).state == 0 and RDamage(obj) or 0

				local damage = obj.health - (Rdmg)
				local x1 = xPos + ((obj.health / obj.maxHealth) * 102)
				local x2 = xPos + (((damage > 0 and damage or 0) / obj.maxHealth) * 102)
				if damage > 0 then
					graphics.draw_line_2D(x1, yPos, x2, yPos, 10, 0xFFEE9922)
				else
					graphics.draw_line_2D(x1, yPos, x2, yPos, 10, 0xFF00B159)
				end
			end
		end
	end
end

orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.spell, AutoInterrupt)
