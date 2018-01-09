local version = "1.0"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw

local orb = module.internal("orb/main")
local gpred = module.internal("pred/main")

local QlvlDmg = {65, 90, 115, 140, 165}
local WlvlDmg = {85, 115, 145, 165, 205}
local RlvlDmg = {150, 250, 350}
local RP, Darkin, KaynP = nil, nil, nil
local AS = false

local qPred = { delay = 0.25, radius = 270, speed = math.huge, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local wPred = { delay = 0.3, width = 100, speed = 1700, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local w2Pred = { delay = 0.6, width = 100, speed = 500, boundingRadiusMod = 1, collision = { hero = false, minion = false } }

local menu = menuconfig("kayn", "Cyrex Kayn")
	menu:header("script", "Cyrex Kayn")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("run", "Marathon Mode", "S", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:dropdown("qm", "Q Mode: ", 2, {"Never", "With Prediction", "MousePosition"})
		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)
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
		if menu.combo.q:get() and CountEnemyHeroInRange(900) < 2 then
			if menu.combo.qm:get() > 1 then
				if menu.combo.qm:get() == 3 then
					if common.CanUseSpell(0) and common.GetDistance(player, target) <= 560 then
						game.cast("pos", 0, vec3(game.mousePos))
					end
				elseif menu.combo.qm:get() == 2 then
					CastQ(target)
				end
			end
		end
		if menu.combo.w:get() then
			CastW(target)
		end
		if menu.combo.r:get() and common.CanUseSpell(3) then
			if menu.combo.rm:get() == 2 then
				if target.health <= (qDmg(target) + wDmg(target) + rDmg(target)) and CountEnemyHeroInRange(900) < 3 then
	                CastR(target)
	            end
	        elseif menu.combo.rm:get() == 1 then
	            if CountEnemyHeroInRange(900) < 3 then 
	                CastR(target)
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


function CastQ(target)
	if common.CanUseSpell(0) then
		local res = gpred.circular.get_prediction(qPred, target)
		if res and res.startPos:dist(res.endPos) < 460 then
			game.cast("pos", 0, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

function CastW(target)
	if common.CanUseSpell(1) then
		if AS == false then
			local seg = gpred.linear.get_prediction(wPred, target)
			if seg and seg.startPos:dist(seg.endPos) < 700 then
				if not gpred.collision.get_prediction(wPred, seg, target) then
					game.cast("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
				end
			end
		elseif AS == true then
			local seg = gpred.linear.get_prediction(w2Pred, target)
			if seg and seg.startPos:dist(seg.endPos) < 900 then
				if not gpred.collision.get_prediction(w2Pred, seg, target) then
					game.cast("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
				end
			end
		end
	end
end


function CastR(target)
	if common.CanUseSpell(3) then
		if AS == false and GetDistance(target) <= 550 then
			game.cast("obj", 3, target)
		elseif AS == true and GetDistance(target) <= 750 then
			game.cast("obj", 3, target)
		end
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
			elseif player:spellslot(1).state == 0 and player:spellslot(0).state == 0 and wDmg(enemy) + qDmg(enemy) > hp then
				CastQ(enemy)
				CastW(enemy)
			elseif player:spellslot(3).state == 0 and player:spellslot(0).state == 0 and qDmg(enemy) + rDmg(enemy) > hp and menu.auto.ukse:get() then
				CastR(enemy)
				CastQ(enemy)
			elseif player:spellslot(1).state == 0 and player:spellslot(0).state == 0 and player:spellslot(3).state == 0 and qDmg(enemy) + rDmg(enemy) + wDmg(enemy) > hp and menu.auto.ukse:get() then
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
		if common.CanUseSpell(0) then
			game.cast("pos", 0, vec3(game.mousePos))
		end
	end
end

function oncreateobj(obj)
    if obj and obj.name and obj.type then
        if obj.name:find("Kayn_Base_R_marker_beam") then
            RP = true
        end
        if obj.name:find("Kayn_Base_Primary_R_Mark") then
            KaynP = true
        end
        if obj.name:find("Kayn_Base_Slayer") then
            Darkin = true
        end
        if obj.name:find("Kayn_Base_Assassin") then
            AS = true
        end
        --if obj and obj.name and obj.name:lower():find("kayn") then print("Created "..obj.name) end
    end
end

function ondeleteobj(obj)
    if obj and obj.name and obj.type then
    	if obj.name:find("Kayn_Base_R_marker_beam") then
            RP = false
        end
        if obj.name:find("Kayn_Base_Primary_R_Mark") then
            KaynP = false
        end
        if obj.name:find("Kayn_Base_Slayer") then
            Darkin = false
        end
    end
end


--[Spyk Credits]--
function qDmg(target)
	local qDamage = CalcADmg(target, QlvlDmg[player:spellslot(0).level] + player.flatPhysicalDamageMod * 0.95, player)
	return qDamage
end

function wDmg(target)
	local wDamage = CalcADmg(target, WlvlDmg[player:spellslot(1).level] + player.flatPhysicalDamageMod * 1.5, player)
	return wDamage
end

function rDmg(target)
	local rDamage = CalcADmg(target, RlvlDmg[player:spellslot(3).level] + player.flatPhysicalDamageMod * 1.85, player)
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
		glx.world.circle(player.pos, 350, 2, draw.color.purple, 100)
	end
	if menu.draws.r:get() and common.CanUseSpell(3) and AS == false then
		glx.world.circle(player.pos, 550, 3, draw.color.blue, 100)
	elseif menu.draws.r:get() and common.CanUseSpell(3) and AS then
		glx.world.circle(player.pos, 750, 3, draw.color.blue, 100)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)
callback.add(enum.callback.recv.createobj, oncreateobj)
callback.add(enum.callback.recv.deleteobj, ondeleteobj)

print("Khantum Phyzix v"..version..": Loaded")