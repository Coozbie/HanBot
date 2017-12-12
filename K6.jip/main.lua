local version = "1.0"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw

local orb = module.internal("orb/main")
local gpred = module.internal("pred/main")

local QlvlDmg = {65, 90, 115, 140, 165}
local WlvlDmg = {85, 115, 145, 165, 205}
local ElvlDmg = {65, 100, 135, 170, 205}
local QRange, ERange = 0, 0

local ePred = { delay = 0.25, radius = 300, speed = 1500, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local wPred = { delay = 0.25, width = 70, speed = 1700, boundingRadiusMod = 1, collision = { hero = true, minion = true } }

local menu = menuconfig("k6", "Khantum Phyzix")
	menu:header("script", "Khantum Phyzix")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("run", "Marathon Mode", "S", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)
		menu.combo:header("xd", "E Settings")
		menu.combo:boolean("e", "Use E in Combo", false)
		menu.combo:dropdown("ed", "E Mode", 2, {"Mouse Pos", "With Prediction"})
		menu.combo:header("xd", "R Settings")
		menu.combo:boolean("r", "Use R", true)
		menu.combo:dropdown("rm", "Ultimate Mode: ", 2, {"Always Ultimate", "Smart Ultimate"})

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("w", "Use W", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "KillSteal Settings")
		menu.auto:boolean("uks", "Use Smart Killsteal", true)
		menu.auto:boolean("ukse", "Use E in Killsteal", false)

	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("e", "Draw E Range", true)
	menu:header("version", "Version: 1.0")
	menu:header("author", "Author: Coozbie")

function OnTick()
	target = GetTarget()
	if menu.keys.combo:get() and target then Combo() end
	if menu.keys.harass:get() and target then Harass() end
	if menu.auto.uks:get() then KillSteal() end
	if menu.keys.run:get() then Run() end
	if menu.draws.q:get() or menu.draws.e:get() then EvolutionCheck() end
end

function Combo()
	if menu.keys.combo:get() then
		if menu.combo.e:get() and CountEnemyHeroInRange(900) < 2 then
			if menu.combo.ed:get() == 1 then
				if common.CanUseSpell(2) and common.GetDistance(player, target) <= 700 then
					common.DelayAction(function()game.cast("pos", 2, vec3(game.mousePos)) end, 0.2)
				end
			elseif menu.combo.ed:get() == 2 then
				CastE(target)
			end
		end
		if menu.combo.q:get() then
			CastQ(target)
		end
		if menu.combo.w:get() then
			CastW(target)
		end
		if menu.combo.r:get() then
			if menu.combo.rm:get() == 2 then
				if target.health <= ((qDmg(target)*2) + wDmg(target) + eDmg(target)) and target.health > (wDmg(target) + eDmg(target)) then
	                if GetDistance(target) <= 900 then
	                    if common.CanUseSpell(2) then CastR(target) end
	                end
	            end
	        elseif menu.combo.rm:get() == 1 then
	            if GetDistance(target) <= 500 then 
	                if common.CanUseSpell(2) then CastR(target) end
	            end
	        end
		end
	end
end

function Harass()
	if menu.keys.harass:get() then
		if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
			if menu.harass.q:get() then
				CastQ(target)
			end
			if menu.harass.w:get() then
				CastW(target)
			end
		end
	end
end


function CastE(target)
	if common.CanUseSpell(2) then
		if player:spellslot(2).name == "KhazixE" then
			local res = gpred.circular.get_prediction(ePred, target)
			if res and res.startPos:dist(res.endPos) < 600 then
				game.cast("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
			end
		elseif player:spellslot(2).name == "KhazixELong" then
			local res = gpred.circular.get_prediction(ePred, target)
			if res and res.startPos:dist(res.endPos) < 900 then
				game.cast("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
			end
		end
	end
end

function CastW(target)
	if common.CanUseSpell(1) then
		local seg = gpred.linear.get_prediction(wPred, target)
		if seg and seg.startPos:dist(seg.endPos) < 970 then
			if not gpred.collision.get_prediction(wPred, seg, target) then
				game.cast("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end

function CastR(target)
	if common.CanUseSpell(3) then
		game.cast("self", 3)
	end
end

function CastQ(target)
	if common.CanUseSpell(0) then
		if player:spellslot(0).name == "KhazixQ" then
			if GetDistance(target) <= 325 then
				game.cast("obj", 0, target)
			end
		elseif player:spellslot(0).name == "KhazixQLong" then
			if GetDistance(target) <= 375 then
				game.cast("obj", 0, target)
			end
		end
	end
end


function KillSteal()
	for i, enemy in pairs(GetEnemy()) do
		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.auto.uks:get() then
			local hp = enemy.health;
			if hp == 0 then return end
			if qDmg(enemy) > hp then
				CastQ(enemy);
			elseif wDmg(enemy) > hp then
				CastW(enemy);
			elseif wDmg(enemy) + qDmg(enemy) > hp then
				CastQ(enemy)
				CastW(enemy)
			elseif qDmg(enemy) + eDmg(enemy) > hp and menu.auto.ukse:get() then
				CastE(enemy)
				CastQ(enemy)
			elseif qDmg(enemy) + eDmg(enemy) + wDmg(enemy) > hp and menu.auto.ukse:get() then
				CastE(enemy)
				CastQ(enemy)
				CastW(enemy)
			end
		end
	end
end


function Run()
	if menu.keys.run:get() then
		game.issue("move", vec3(game.mousePos))
		if common.CanUseSpell(2) then
			game.cast("pos", 2, vec3(game.mousePos))
		end
	end
end

function EvolutionCheck()
    if player:spellslot(0).name == "KhazixQ" then
        QRange = 325
    elseif player:spellslot(0).name == "KhazixQLong" then
    	QRange = 375
    end 
    if player:spellslot(2).name == "KhazixE" then
        ERange = 700
    elseif player:spellslot(2).name == "KhazixELong" then
    	ERange = 900
    end 
end 

--[Spyk Credits]--
function qDmg(target)
	local qDamage = CalcADmg(target, QlvlDmg[player:spellslot(0).level] + player.flatPhysicalDamageMod * 1.6, player)
	return qDamage
end

function wDmg(target)
	local wDamage = CalcADmg(target, WlvlDmg[player:spellslot(1).level] + player.flatPhysicalDamageMod * 1.3, player)
	return wDamage
end

function eDmg(target)
	local eDamage = CalcADmg(target, ElvlDmg[player:spellslot(2).level] + player.flatPhysicalDamageMod * .8, player)
	return eDamage
end

function CountEnemyHeroInRange(range)
	local range, count = range*range, 0 
	for i = 0, objmanager.enemies_n - 1 do
		if player.pos:distSqr(objmanager.enemies[i].pos) < range then 
	 		count = count + 1 
	 	end 
	end 
	return count 
end

function CalcADmg(target, amount, from)
	local from = from or player or objmanager.player;
	local target = target or orb.combat.target;
	local amount = amount or 0;
	local targetD = target.armor * math.ceil(from.percentArmorPenetration) - from.flatArmorPenetration;
	local dmgMul = 100 / (100 + targetD);
	if dmgMul < 0 then
		dmgMul = 2 - (100 / (100 - targetD));
	end
	amount = amount * dmgMul;
	return math.floor(amount)
end

function GetDistance(p1, p2)
	p2 = p2 or player;
	return p1.path.serverPos:dist(p2.path.serverPos)
end

function GetTarget(range)
	range = range or 900;
	if orb.combat.target and not orb.combat.target.isDead and orb.combat.target.isTargetable
	 and orb.combat.target.isInvulnerable and orb.combat.target.isMagicImmune and orb.combat.target.isVisible then
		return orb.combat.target
	else
		local dist, closest = math.huge, nil;
		for k, unit in pairs(GetEnemy()) do
			local unit_distance = GetDistance(unit);
			if not unit.isDead and unit.isVisible and unit.isTargetable 
				and unit.isInvulnerable and unit.isMagicImmune and unit_distance <= range then
				if unit_distance < dist then
					closest = unit;
					dist = unit_distance;
				end
			end
		end
		if closest then
			return closest
		end
	end
	return nil
end

function _enemy_init()
	_enemyHeroes = {};
	for i = 0, objmanager.enemies_n - 1 do
		_enemyHeroes[#_enemyHeroes + 1] = objmanager.enemies[i];
	end
	return _enemyHeroes
end

function GetEnemy()
	if _enemyHeroes then 
		return _enemyHeroes 
	else
		return _enemy_init();
	end
end
--[End Spyk Credits]--


function OnDraw()
	if menu.draws.q:get() and common.CanUseSpell(0) then
		glx.world.circle(player.pos, QRange, 2, draw.color.purple, 100)
	end
	if menu.draws.e:get() and common.CanUseSpell(2) then
		glx.world.circle(player.pos, ERange, 3, draw.color.blue, 100)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)

print("Khantum Phyzix v"..version..": Loaded")