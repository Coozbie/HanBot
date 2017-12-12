local version = "1.0"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw
local ts = alib.targetSelector
local WP, WCheck = nil, nil
local onE = false
local enemies = common.GetEnemyHeroes()

local orb = module.internal("orb/main")
local gpred = module.internal("pred/main")

local QlvlDmg = {10, 25, 40, 55, 70}
local WlvlDmg = {20, 30, 40, 50, 60}
local ElvlDmg = {70, 120, 170, 220, 270}
local RlvlDmg = {225, 325, 425}

local ePred = { delay = 0.25, radius = 270, speed = 1000, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local rPred = { delay = 0.25, width = 120, speed = 1350, boundingRadiusMod = 1, collision = { hero = true, minion = false } }

local menu = menuconfig("fizz", "Cyrex Fizz")
	ts = ts(menu, 1200)
	menu:header("script", "Cyrex Fizz")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("run", "Marathon Mode", "S", false)
		menu.keys:keybind("manual", "Manual R Aim", "T", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:slider("qr", "Min. Q Range", 350, 0, 550, 25)
		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)
		menu.combo:header("xd", "E Settings")
		menu.combo:boolean("e", "Use E", true)
		menu.combo:dropdown("ed", "E Mode", 2, {"Mouse Pos", "With Prediction"})
		menu.combo:header("xd", "R Settings")
		menu.combo:boolean("r", "Use R", true)
		menu.combo:slider("rr", "Min. R Range", 900, 0, 1200, 100)

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("w", "Use W", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "KillSteal Settings")
			menu.auto:boolean("uks", "Use Smart Killsteal", true)
			menu.auto:boolean("urks", "Use R in Killsteal", true)

	ts:addToMenu()
	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("e", "Draw R Range", true)
	menu:header("version", "Version: 1.0")
	menu:header("author", "Author: Coozbie")

function OnTick()
	if menu.keys.combo:get() then Combo() end
	if menu.keys.harass:get() then Harass() end
	if menu.auto.uks:get() then KillSteal() end
	if menu.keys.run:get() then Run() end
	if menu.keys.manual:get() then AimR() end
end

function Combo()
	if menu.keys.combo:get() then
		local target = ts.target
		if target and not target.isDead then
			if menu.combo.e:get() then
				if menu.combo.ed:get() == 1 then
					if common.CanUseSpell(2) and common.GetDistance(player, target) <= 600 then
						common.DelayAction(function()game.cast("pos", 2, vec3(game.mousePos)) end, 0.5)
					end
				elseif menu.combo.ed:get() == 2 then
					CastE(target)
				end
			end
			if menu.combo.q:get() then
				CastQ(target)
			end
			if menu.combo.w:get() and common.CanUseSpell(1) and WP and common.GetDistance(player, target) <= 225 and not orb.core.can_attack() then
				game.cast("self", 1)
			elseif menu.combo.w:get() and common.CanUseSpell(1) and wDmg(target) > target.health and common.GetDistance(player, target) <= 225 and not orb.core.can_attack() then
				game.cast("self", 1)
			end
			if menu.combo.r:get() and common.GetDistance(player, target) >= menu.combo.rr:get() then
				CastR(target)
			end
		end
	end
end

function Harass()
	if menu.keys.harass:get() then
		if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
			local target = ts.target
			if target and not target.isDead then
				if menu.harass.q:get() then
					CastQ(target)
				end
				if menu.harass.w:get() and common.CanUseSpell(1) and common.GetDistance(player, target) <= 225 and not orb.core.can_attack() then
					game.cast("self", 1)
				end
			end
		end
	end
end


function CastE(target)
	if common.CanUseSpell(2) then
		local res = gpred.circular.get_prediction(ePred, target)
		if res and res.startPos:dist(res.endPos) < 400 then
			game.cast("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

function CastR(target)
	if common.CanUseSpell(3) then
		local seg = gpred.linear.get_prediction(rPred, target)
		if seg and seg.startPos:dist(seg.endPos) < 1275 then
			if not gpred.collision.get_prediction(rPred, seg, target) then
				game.cast("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end

function CastQ(target)
	if common.CanUseSpell(0) and common.GetDistance(player, target) <= menu.combo.qr:get() then
		game.cast("obj", 0, target)
	end
end


function KillSteal()
	for i, enemy in pairs(enemies) do
		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.auto.uks:get() then
			local hp = enemy.health;
			if hp == 0 then return end
			if qDmg(enemy) > hp then
				CastQ(enemy);
			elseif rDmg(enemy) > hp and menu.auto.urks:get() then
				CastR(enemy);
			end
		end
	end
end

function oncreateobj(obj)
    if obj and obj.name and obj.type then
        if obj.name:find("Fizz_Base_W_DmgMarkerMaintain") then
            WP = true
        end
        if obj.name:find("Fizz_Base_W_DmgMarker_champion") then
            WCheck = true
        end
        --if obj and obj.name and obj.name:lower():find("fizz") then print("Created "..obj.name) end
    end
end

function ondeleteobj(obj)
    if obj and obj.name and obj.type then
        if obj.name:find("Fizz_Base_W_DmgMarkerMaintain") then
            WP = false
        end
        if obj.name:find("Fizz_Base_W_DmgMarker_champion") then
            WCheck = false
        end
    end
end

--[[function processSpell(unit, spellProc)
	if unit == player and player:spellslot(2).name == "FizzE" then
		onE = true print("E ON")
	elseif player:spellslot(2).name == "FizzETwo" then 
		onE = false print("E OFF")
	end
end]]--

function Run()
	if menu.keys.run:get() then
		game.issue("move", vec3(game.mousePos))
		if common.CanUseSpell(2) then
			game.cast("pos", 2, vec3(game.mousePos))
		end
	end
end

function AimR()
	if menu.keys.manual:get() then
		local target = ts.target
		if common.GetDistance(player, target) <= 1200 then
			CastR(target)
		end
	end
end



--[Spyk Credits]--
function qDmg(target)
	local qDamage = CalcMagicDmg(target, QlvlDmg[player:spellslot(0).level] + player.flatMagicDamageMod * .55, player)
	return qDamage
end

function wDmg(target)
	local wDamage = CalcMagicDmg(target, WlvlDmg[player:spellslot(1).level] + player.flatMagicDamageMod * .4, player)
	return wDamage
end

function eDmg(target)
	local eDamage = CalcMagicDmg(target, ElvlDmg[player:spellslot(2).level] + player.flatMagicDamageMod * .75, player)
	return eDamage
end

function rDmg(target)
	local rDamage = CalcMagicDmg(target, RlvlDmg[player:spellslot(3).level] + player.flatMagicDamageMod * .8, player)
	return rDamage
end


function CalcMagicDmg(target, amount, from)
	local from = from or player or objmanager.player;
	local target = target or orb.combat.target;
	local amount = amount or 0;
	local targetMR = target.spellBlock * math.ceil(from.percentMagicPenetration) - from.flatMagicPenetration;
	local dmgMul = 100 / (100 + targetMR);
	if dmgMul < 0 then
		dmgMul = 2 - (100 / (100 - targetMR));
	end
	amount = amount * dmgMul;
	return math.floor(amount)
end
--[End Spyk Credits]--


function OnDraw()
	if menu.draws.q:get() and common.CanUseSpell(0) then
		glx.world.circle(player.pos, menu.combo.qr:get(), 2, draw.color.red, 100)
	end
	if menu.draws.e:get() and common.CanUseSpell(3) then
		glx.world.circle(player.pos, menu.combo.rr:get(), 3, draw.color.blue, 50)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)
callback.add(enum.callback.recv.createobj, oncreateobj)
callback.add(enum.callback.recv.deleteobj, ondeleteobj)
--callback.add(enum.callback.recv.spell, processSpell)

print("Cyrex Fizz v"..version..": Loaded")