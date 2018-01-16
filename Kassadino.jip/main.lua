local version = "1.0"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw
local ts = alib.targetSelector

local orb = module.internal("orb/main")
local gpred = module.internal("pred/main")

local enemies = common.GetEnemyHeroes()

local ePred = { delay = 0.4, radius = 350, speed = 1000, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local rPred = { delay = 0.25, radius = 270, speed = 1000, boundingRadiusMod = 0, collision = { hero = false, minion = false } }

local QlvlDmg = {65, 95, 125, 135, 185}
local WlvlDmg = {40, 65, 90, 115, 140}
local ElvlDmg = {80, 105, 130, 155, 180}
local RlvlDmg = {80, 100, 120}

local menu = menuconfig("kassadin", "Cyrex Kassadin")
	ts = ts(menu, 700)
	menu:header("script", "Cyrex Kassadin")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("run", "Marathon Mode", "S", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Combo Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:boolean("w", "Use W", true)
		menu.combo:boolean("e", "Use E", true)

		menu.combo:header("xd", "R Settings")
			menu.combo:menu("rs", "R Settings")
				menu.combo.rs:header("xd", "Player Settings")
				menu.combo.rs:boolean("ur", "Use R", false)
				menu.combo.rs:dropdown("mode", "Choose Rift Walk Mode: ", 2, {"         R to MousePos", "            R with Pred"})
				menu.combo.rs:slider("rx", "R if X Enemys in Range", 1, 0, 5, 1)

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("w", "Use W", true)
		menu.harass:boolean("e", "Use E", true)
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
end

function Combo()
	if menu.keys.combo:get() then
		local target = ts.target
		if target and not target.isDead then
			if menu.combo.e:get() then
				CastE(target)
			end
			if menu.combo.q:get() then
				CastQ(target)
			end
			if menu.combo.w:get() and common.CanUseSpell(1) and common.GetDistance(player, target) <= 200 and not orb.core.can_attack() then
				game.cast("self", 1)
			end
			if menu.combo.rs.mode:get() == 1 and menu.combo.rs.ur:get() and CountEnemyHeroInRange(800) >= menu.combo.rs.rx:get() then
				if common.CanUseSpell(3) then
					game.cast("pos", 3, vec3(game.mousePos))
				end
			elseif menu.combo.rs.mode:get() == 2 and menu.combo.rs.ur:get() and player:spellslot(3).state == 0 and CountEnemyHeroInRange(800) >= menu.combo.rs.rx:get() and rDmg(target) + qDmg(target) + eDmg(target) > target.health then
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
				if menu.harass.e:get() then
					CastE(target)
				end
				if menu.harass.q:get() and common.GetDistance(player, target) <= 650 and common.CanUseSpell(0) then
					game.cast("obj", 0, target)
				end
				if menu.harass.w:get() and common.CanUseSpell(1) and common.GetDistance(player, target) <= 200 and not orb.core.can_attack() then
					game.cast("self", 1)
				end
			end
		end
	end
end

function CastE(target)
	if common.CanUseSpell(2) then
		local res = gpred.circular.get_prediction(ePred, target)
		if res and res.startPos:dist(res.endPos) < 665 then
			game.cast("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

function CastR(target)
	if common.CanUseSpell(3) then
		local res = gpred.circular.get_prediction(rPred, target)
		if res and res.startPos:dist(res.endPos) < 450 then
			game.cast("pos", 3, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

function CastQ(target)
	if common.CanUseSpell(0) and common.GetDistance(player, target) <= 650 then
		game.cast("obj", 0, target)
	end
end


function KillSteal()
	for i, enemy in pairs(enemies) do
 		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.auto.uks:get() then
 			local hp = enemy.health;
 			if hp == 0 then return end
  			if common.CanUseSpell(0) and hp < qDmg(enemy) then
	  			CastQ(enemy);
   			elseif common.CanUseSpell(2) and hp < eDmg(enemy) then 
   				CastE(enemy); 
   			elseif common.CanUseSpell(3) and hp < rDmg(enemy) and menu.auto.urks:get() then
   				CastR(enemy);
   			elseif common.CanUseSpell(0) and common.CanUseSpell(2) and hp < qDmg(enemy) + eDmg(enemy) then
   				CastQ(enemy);
   				CastE(enemy);
   			elseif common.CanUseSpell(0) and common.CanUseSpell(2) and common.CanUseSpell(3) and hp < qDmg(enemy) + eDmg(enemy) + rDmg(enemy) and menu.auto.urks:get() then
   				CastR(enemy);
   				CastQ(enemy);
   				CastE(enemy);
   			elseif common.CanUseSpell(0) and common.CanUseSpell(2) and common.CanUseSpell(3) and common.CanUseSpell(1) and hp < qDmg(enemy) + eDmg(enemy) + rDmg(enemy) + wDmg(enemy) and menu.auto.urks:get() then	
   				CastR(enemy);
   				CastQ(enemy);
   				CastE(enemy);
   				if common.GetDistance(player, enemy) <= 200 and not orb.core.can_attack() then
   					game.cast("self", 1)
   				end
   			end
  		end
 	end
end


function Run()
	if menu.keys.run:get() then
		game.issue("move", vec3(game.mousePos))
		if common.CanUseSpell(3) then
			game.cast("pos", 3, vec3(game.mousePos))
		end
	end
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


--[Spyk Credits]--
function qDmg(target)
	local qDamage = CalcMagicDmg(target, QlvlDmg[player:spellslot(0).level] + player.flatMagicDamageMod * .7, player)
	return qDamage
end

function wDmg(target)
	local wDamage = CalcMagicDmg(target, WlvlDmg[player:spellslot(1).level] + player.flatMagicDamageMod * .7, player)
	return wDamage
end

function eDmg(target)
	local eDamage = CalcMagicDmg(target, ElvlDmg[player:spellslot(2).level] + player.flatMagicDamageMod * .7, player)
	return eDamage
end

function rDmg(target)
	local rDamage = CalcMagicDmg(target, RlvlDmg[player:spellslot(3).level] + player.flatMagicDamageMod * .3 + player.maxPar * .2, player) --+ (stacksDmg[RSTACK] + player.flatMagicDamageMod * .1 + player.maxPar * .1, player))
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
	if menu.draws.q:get() then
		glx.world.circle(player.pos, 650, 2, draw.color.purple, 100)
	end
	if menu.draws.e:get() then
		glx.world.circle(player.pos, 450, 1, draw.color.blue, 50)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)

print("Cyrex Kassadin v"..version..": Loaded")