local version = "1.2"

local avada_lib = module.lib("avada_lib")
if not avada_lib then
	console.set_color(12)
	print("You need to have Avada Lib in your community_libs folder to run 'Cyrex Jinx'!")
	print("You can find it here:")
	console.set_color(11)
	print("https://gitlab.soontm.net/get_clear_zip.php?fn=avada_lib")
	console.set_color(15)
	return
elseif avada_lib.version < 1 then
	console.set_color(12)
	print("Your need to have Avada Lib updated to run 'Cyrex Jinx'!")
	print("You can find it here:")
	console.set_color(11)
	print("https://gitlab.soontm.net/get_clear_zip.php?fn=avada_lib")
	console.set_color(15)
	return
end
local common = avada_lib.common
local ts = avada_lib.targetSelector

local orb = module.internal("orb")
local gpred = module.internal("pred")

local enemies = common.GetEnemyHeroes()

local ePred = { delay = 0.4, radius = 250, speed = math.huge, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local rPred = { delay = 0.25, radius = 270, speed = math.huge, boundingRadiusMod = 0, collision = { hero = false, minion = false } }

local QlvlDmg = {65, 95, 125, 135, 185}
local WlvlDmg = {40, 65, 90, 115, 140}
local ElvlDmg = {80, 105, 130, 155, 180}
local RlvlDmg = {80, 100, 120}

local menu = menu("kassadin", "Cyrex Kassadin")
	ts = ts(menu, 700, 2)
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
	menu:header("version", "Version: 1.2")
	menu:header("author", "Author: Coozbie")

local function qDmg(target)
	local qDamage = QlvlDmg[player:spellSlot(0).level] + (common.GetTotalAP() * .7)
	return common.CalculateMagicDamage(target, qDamage)
end

local function wDmg(target)
	local wDamage = WlvlDmg[player:spellSlot(1).level] + (common.GetTotalAP() * .7)
	return common.CalculateMagicDamage(target, wDamage)
end

local function eDmg(target)
	local eDamage = ElvlDmg[player:spellSlot(2).level] + (common.GetTotalAP() * .7)
	return common.CalculateMagicDamage(target, eDamage)
end

local function rDmg(target)
	local rDamage = RlvlDmg[player:spellSlot(3).level] + (common.GetTotalAP() * .3) + (player.maxPar * .2) --+ (stacksDmg[RSTACK] + player.flatMagicDamageMod * .1 + player.maxPar * .1, player))
	return common.CalculateMagicDamage(target, rDamage)
end

local function CastE(target)
	if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (665 * 665) then
		local res = gpred.circular.get_prediction(ePred, target)
		if res and res.startPos:distSqr(res.endPos) < (665 * 665) then
			player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

local function CastR(target)
	if player:spellSlot(3).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (450 * 450) then
		local res = gpred.circular.get_prediction(rPred, target)
		if res and res.startPos:distSqr(res.endPos) < (450 * 450) then
			player:castSpell("pos", 3, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

local function CastQ(target)
	if player:spellSlot(0).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (650 * 650) then
		player:castSpell("obj", 0, target)
	end
end


local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
 		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.auto.uks:get() then
 			local hp = enemy.health;
 			if hp == 0 then return end
  			if player:spellSlot(0).state == 0 and hp < qDmg(enemy) and player.path.serverPos:distSqr(enemy.path.serverPos) < (650 * 650) then
	  			CastQ(enemy);
   			elseif player:spellSlot(2).state == 0 and hp < eDmg(enemy) and player.path.serverPos:distSqr(enemy.path.serverPos) < (665 * 665) then 
   				CastE(enemy); 
   			elseif player:spellSlot(3).state == 0 and hp < rDmg(enemy) and menu.auto.urks:get() and player.path.serverPos:distSqr(enemy.path.serverPos) < (450 * 450) then
   				CastR(enemy);
   			elseif player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and hp < qDmg(enemy) + eDmg(enemy) and player.path.serverPos:distSqr(enemy.path.serverPos) < (665 * 665) then
   				CastQ(enemy);
   				CastE(enemy);
   			elseif player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and player:spellSlot(3).state == 0 and hp < qDmg(enemy) + eDmg(enemy) + rDmg(enemy) and menu.auto.urks:get() and player.path.serverPos:distSqr(enemy.path.serverPos) < (665 * 665) then
   				CastR(enemy);
   				CastQ(enemy);
   				CastE(enemy);
   			elseif player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and player:spellSlot(3).state == 0 and player:spellSlot(1).state == 0 and hp < qDmg(enemy) + eDmg(enemy) + rDmg(enemy) + wDmg(enemy) and menu.auto.urks:get() and player.path.serverPos:distSqr(enemy.path.serverPos) < (665 * 665) then	
   				CastR(enemy);
   				CastQ(enemy);
   				CastE(enemy);
   				if player.path.serverPos:distSqr(enemy.path.serverPos) < (200 * 200) and not orb.core.can_attack() then
   					player:castSpell("self", 1)
   				end
   			end
  		end
 	end
end

local function Combo()
	if menu.keys.combo:get() then
		local target = ts.target
		if target and not target.isDead then
			if menu.combo.e:get() then
				CastE(target)
			end
			if menu.combo.q:get() then
				CastQ(target)
			end
			if menu.combo.w:get() and player:spellSlot(1).state == 0 and target.pos:dist(player.pos) <= common.GetAARange(player) then
				player:castSpell("self", 1)
			end
			if menu.combo.rs.mode:get() == 1 and menu.combo.rs.ur:get() and CountEnemyHeroInRange(800) >= menu.combo.rs.rx:get() then
				if player:spellSlot(3).state == 0 then
					player:castSpell("pos", 3, vec3(game.mousePos))
				end
			elseif menu.combo.rs.mode:get() == 2 and menu.combo.rs.ur:get() and player:spellSlot(3).state == 0 and CountEnemyHeroInRange(800) >= menu.combo.rs.rx:get() and rDmg(target) + qDmg(target) + eDmg(target) > target.health then
				CastR(target)
			end
		end
	end
end

local function Harass()
	if menu.keys.harass:get() then
		if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
			local target = ts.target
			if target and not target.isDead then
				if menu.harass.e:get() then
					CastE(target)
				end
				if menu.harass.q:get() and target.pos:dist(player.pos) <= 650 and player:spellSlot(0).state == 0 then
					player:castSpell("obj", 0, target)
				end
				if menu.harass.w:get() and player:spellSlot(1).state == 0 and target.pos:dist(player.pos) <= 200 and not orb.core.can_attack() then
					player:castSpell("self", 1)
				end
			end
		end
	end
end

local function Run()
	if menu.keys.run:get() then
		player:move((game.mousePos))
		if player:spellSlot(3).state == 0 then
			player:castSpell("pos", 3, (game.mousePos))
		end
	end
end


local function CountEnemyHeroInRange(range)
	local range, count = range*range, 0 
	for i = 0, objManager.enemies_n - 1 do
		if player.pos:distSqr(objManager.enemies[i].pos) < range then 
	 		count = count + 1 
	 	end 
	end 
	return count 
end

local function OnTick()
	if orb.combat.is_active() then Combo() end
	if orb.menu.hybrid:get() then Harass() end
	if menu.auto.uks:get() then KillSteal() end
	if menu.keys.run:get() then Run() end
end

local function OnDraw()
	if menu.draws.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, 650, 2, graphics.argb(255, 168, 0, 157), 80)
	end
	if menu.draws.e:get() and player:spellSlot(3).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, 500, 2, graphics.argb(255, 0, 21, 255), 80)
	end
end

orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.draw, OnDraw)

print("Cyrex Kassadin v"..version..": Loaded")