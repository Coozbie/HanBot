local version = "1.0"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw

local orb = module.internal("orb/main")
local gpred = module.internal("pred/main")

local QlvlDmg = {80, 135, 190, 245, 300}
local WlvlDmg = {75, 125, 175, 225, 275}
local RlvlDmg = {300, 475, 650}
local HPlvl = {574.4, 632, 692.4, 755.6, 821.6, 890.4, 962, 1036.4, 1113.6, 1193.6, 1276.4, 1362, 1450.4, 1541.6, 1635.6, 1732.4, 1832, 1934.4}

local qPred = { delay = 1.2, radius = 125, speed = math.huge, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local wPred = { delay = 0.25, radius = 80, speed = math.huge, boundingRadiusMod = 0, collision = { hero = false, minion = false } }


local menu = menuconfig("cho", "Tasty Cho'Gath")
	menu:header("script", "Tasty Cho'Gath")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("run", "Marathon Mode", "S", false)
		menu.keys:keybind("StartW", "Start Combo With W", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)
		menu.combo:header("xd", "E Settings")
		menu.combo:boolean("e", "Use E", true)
		menu.combo:header("xd", "R Settings")
		menu.combo:boolean("r", "Use Smart R", true)

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("w", "Use W", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "KillSteal Settings")
		menu.auto:boolean("uks", "Use Smart Killsteal", true)
		menu.auto:boolean("ukse", "Use R in Killsteal", false)

	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("r", "Draw R Range", true)
	menu:header("version", "Version: 1.0")
	menu:header("author", "Author: Coozbie")

function OnTick()
	target = GetTarget()
	if menu.keys.combo:get() and target then Combo() end
	if menu.keys.harass:get() and target then Harass() end
	if menu.auto.uks:get() then KillSteal() end
	if menu.keys.run:get() then Run() end
end

function Combo()
	if menu.keys.combo:get() then
		if menu.combo.w:get() then
			CastW(target)
		end
		if menu.keys.StartW:get() and common.CanUseSpell(1) then return end
		if menu.combo.q:get() then
			CastQ(target)
		end
		if menu.combo.e:get() and common.CanUseSpell(2) and GetDistance(target) <= 180 then
			game.cast("self", 2)
		end
		if menu.combo.r:get() and player:spellslot(3).state == 0 then
			if target.health <= rDmg(target) then
                CastR(target)
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

function CastQ(target)
	if common.CanUseSpell(0) then
		local res = gpred.circular.get_prediction(qPred, target)
		if res and res.startPos:dist(res.endPos) < 950 then
			game.cast("pos", 0, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

function CastW(target)
	if common.CanUseSpell(1) then
		local res = gpred.circular.get_prediction(wPred, target)
		if res and res.startPos:dist(res.endPos) < 650 then
			game.cast("pos", 1, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

function CastR(target)
	if common.CanUseSpell(3) and GetDistance(target) <= 250 then
		game.cast("obj", 3, target)
	end
end


function KillSteal()
	for i, enemy in pairs(GetEnemy()) do
		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.auto.uks:get() and GetDistance(enemy) <= 1000 then
			local hp = enemy.health;
			if hp == 0 then return end
			if player:spellslot(0).state == 0 and qDmg(enemy) > hp then
				CastQ(enemy);
			elseif player:spellslot(1).state == 0 and wDmg(enemy) > hp then
				CastW(enemy);
			elseif player:spellslot(3).state == 0 and menu.auto.ukse:get() and rDmg(enemy) > hp then
				CastR(enemy);
			elseif player:spellslot(1).state == 0 and player:spellslot(0).state == 0 and wDmg(enemy) + qDmg(enemy) > hp and GetDistance(enemy) <= 800 then
				CastQ(enemy)
				CastW(enemy)
			elseif player:spellslot(3).state == 0 and player:spellslot(0).state == 0 and qDmg(enemy) + rDmg(enemy) > hp and menu.auto.ukse:get() and GetDistance(enemy) <= 500 then
				CastR(enemy)
				CastQ(enemy)
			elseif player:spellslot(1).state == 0 and player:spellslot(0).state == 0 and player:spellslot(3).state == 0 and qDmg(enemy) + rDmg(enemy) + wDmg(enemy) > hp and menu.auto.ukse:get() and GetDistance(enemy) <= 500 then
				CastR(enemy)
				CastQ(enemy)
				CastW(enemy)
			end
		end
	end
end


function Run()
	if menu.keys.run:get() then
		game.issue("move", vec3(game.mousePos))
	end
end


--[Spyk Credits]--
function qDmg(target)
	local qDamage = CalcMagicDmg(target, QlvlDmg[player:spellslot(0).level] + player.flatMagicDamageMod * 1, player)
	return qDamage
end

function wDmg(target)
	local wDamage = CalcMagicDmg(target, WlvlDmg[player:spellslot(1).level] + player.flatMagicDamageMod * .7, player)
	return wDamage
end

function rDmg(target)
	local rDamage = CalcMagicDmg(target, RlvlDmg[player:spellslot(3).level] + player.flatMagicDamageMod * .5 + ((player.maxHealth - HPlvl[player.level]) * 0.1), player)
	return rDamage
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
		glx.world.circle(player.pos, 950, 2, draw.color.purple, 100)
	end
	if menu.draws.r:get() and common.CanUseSpell(3) then
		glx.world.circle(player.pos, 250, 3, draw.color.blue, 100)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)
print("Tasty Cho'Gath v"..version..": Loaded")