local version = "1.0"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw
local ts = alib.targetSelector

local orb = module.internal("orb/main")
local enemies = common.GetEnemyHeroes()
local ally = common.GetAllyHeroes()

local QlvlDmg = {60, 110, 160, 210, 260}

local menu = menuconfig("kayle", "Cyrex Kayle")
	ts = ts(menu, 800)
	menu:header("script", "Cyrex Kayle")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("run", "Marathon Mode", "S", false)
		menu.keys:keybind("ultself", "Manual Self Ult", "A", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)
		menu.combo:slider("wm", "Min. Mana % for W: ", 60, 0, 100, 5)
		menu.combo:slider("whp", "Min. HP % for W: ", 70, 0, 100, 5)
		menu.combo:header("xd", "E Settings")
		menu.combo:boolean("e", "Use E", true)
		menu.combo:header("xd", "R Settings")
		menu.combo:boolean("r", "Use R", true)
		menu.combo:slider("rhp", "Min. HP% for R: ", 25, 0, 100, 5)
		menu.combo:slider("rx", "Enemys Near: ", 1, 0, 5, 1)
		menu.combo:header("xd", "Ally Settings")
		menu.combo:menu("x", "Ally Selection")
			 for i = 0, objmanager.allies_n - 1 do
				local ally = objmanager.allies[i]
				if ally ~= player then
					menu.combo.x:boolean(ally.charName, "Revive: "..ally.charName, false) 
				end
			end
		menu.combo:slider("ahp", "HP% To Revive Ally", 10, 0, 100, 10)

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("e", "Use E", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "KillSteal Settings")
		menu.auto:boolean("uks", "Use Q Killsteal", true)
		menu.auto:header("xd", "Healing Settings")
		menu.auto:boolean("heal", "Use W to Heal", true)
		menu.auto:slider("healx", "Min HP% to Heal", 70, 0, 100, 5)

	ts:addToMenu()

	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("e", "Draw E Range", true)
	menu:header("version", "Version: 1.0")
	menu:header("author", "Author: Coozbie")

function OnTick()
	if menu.keys.combo:get() then Combo() end
	if menu.keys.harass:get() then Harass() end
	if menu.auto.uks:get() then KillSteal() end
	if menu.keys.run:get() then Run() end
	if menu.keys.ultself:get() and common.CanUseSpell(3) and common.GetPercentHealth() <= 50 then game.cast("obj", 3, player) end
	Auto()
end

function Combo()
	if menu.keys.combo:get() then
		local target = ts.target
		if target and not target.isDead and not common.HasBuffType(target, 17) then
			if menu.combo.q:get() then
				CastQ(target)
			end
			if menu.combo.w:get() and selector.get_dist(target) >= 550 then
				if common.GetPercentPar() >= menu.combo.wm:get() and common.GetPercentHealth() >= menu.combo.whp:get() then
					CastW()
				end
			end
			if menu.combo.e:get() and selector.get_dist(target) <= 510 then
				CastE(target)
			end
		end
	end
end

function Harass()
	if menu.keys.harass:get() then
		local target = ts.target
		if target and not target.isDead and not common.HasBuffType(target, 17) then
			if common.GetPercentPar() >= menu.harass.Mana:get() then
				if menu.harass.q:get() then
					CastQ(target)
				end
				if menu.harass.e:get() then
					CastE(target)
				end
			end
		end
	end
end


function CastE(target)
	if common.CanUseSpell(2) then
		game.cast("self", 2)
	end
end

function CastW()
	if common.CanUseSpell(1) then
		game.cast("obj", 1, player)
	end
end

function CastR()
	if common.CanUseSpell(3) then
		game.cast("obj", 3, player)
	end
end

function CastQ(target)
	if common.CanUseSpell(0) then
		if selector.get_dist(target) <= 650 then
			game.cast("obj", 0, target)
		end
	end
end

--add Q range check so kayle doesnt walk across the map
--.isDead already has hp check so no need for if hp == 0 then return end (alternative just use selector.valid_target(enemy) instead of 50 diff checks xd
function KillSteal()
	for i, enemy in pairs(enemies) do
		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.auto.uks:get() then
			local hp = enemy.health;
			if hp == 0 then return end
			if player:spellslot(0).state == 0 and qDmg(enemy) > hp then
				CastQ(enemy);
			end
		end
	end
end

function Auto()
	if menu.auto.heal:get() and common.GetPercentHealth() <= menu.auto.healx:get() and CountEnemyHeroInRange(600) >= 1 then
		CastW()
	end
	if menu.combo.r:get() and #common.GetEnemyHeroesInRange(800, player) >= menu.combo.rx:get() and common.GetPercentHealth() < menu.combo.rhp:get() then
		CastR()
	end
	if common.CanUseSpell(3) then
		for i = 0, objmanager.allies_n - 1 do
			local ally = objmanager.allies[i]
			if selector.is_valid(ally) and menu.combo.x[ally.charName]:get() and common.GetPercentHealth(ally) <= menu.combo.ahp:get() and selector.get_dist(ally) < 900 and #common.GetEnemyHeroesInRange(800, player) >= 1 then
				game.cast("obj", 3, ally)
			end
		end
	end
end

function Run()
	if menu.keys.run:get() then
		game.issue("move", vec3(game.mousePos))
		if common.CanUseSpell(1) then
			game.cast("self", 1)
		end
	end
end

--[Spyk Credits]--
function qDmg(target)
	local qDamage = CalcMagicDmg(target, QlvlDmg[player:spellslot(0).level] + (player.flatMagicDamageMod * 0.6) + (player.flatPhysicalDamageMod * 1) , player)
	return qDamage
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

function OnDraw()
	if menu.draws.q:get() and common.CanUseSpell(0) then
		glx.world.circle(player.pos, 650, 2, draw.color.cyan, 100)
	end
	if menu.draws.e:get() then
		glx.world.circle(player.pos, common.GetAARange(player), 2, draw.color.green, 100)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)

print("Cyrex Kayle v"..version..": Loaded")