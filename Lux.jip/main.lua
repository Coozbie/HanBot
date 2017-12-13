local version = "1.0"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw

local orb = module.internal("orb/main")
local gpred = module.internal("pred/main")

local QlvlDmg = {50, 100, 150, 200, 250}
local ElvlDmg = {60, 105, 150, 195, 240}
local RlvlDmg = {300, 400, 500}
local Passive = {20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190}

local QT = nil
local EnemyCC = nil

local qPred = { delay = 0.25, width = 70, speed = 1200, boundingRadiusMod = 1, collision = { hero = false, minion = true } }
local ePred = { delay = 0.25, radius = 275, speed = 1300, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local rPred = { delay = 1, width = 170, speed = 1000, boundingRadiusMod = 1, collision = { hero = false, minion = false } }

local menu = menuconfig("lux", "Cyrex Lux")
	menu:header("script", "Cyrex Lux")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("StartQ", "Start Combo With Q", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)
		menu.combo:slider("wx", "Min HP% to Shield", 70, 0, 100, 5)
		menu.combo:header("xd", "E Settings")
		menu.combo:boolean("e", "Use E in Combo", true)
		menu.combo:header("xd", "R Settings")
		menu.combo:boolean("r", "Use R", true)
		menu.combo:boolean("rc", "Check if Enemy has CC?", true)
		menu.combo:boolean("rh", "Check if Enemy Dies?", false)

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("e", "Use E", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "KillSteal Settings")
		menu.auto:boolean("uks", "Use Smart Killsteal", true)

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
end

function Combo()
	if menu.keys.combo:get() then
		if menu.combo.q:get() and (gpred.collision.get_prediction(qPred, gpred.linear.get_prediction(qPred, target), target) == nil or table.getn(gpred.collision.get_prediction(qPred, gpred.linear.get_prediction(qPred, target), target)) == 1) then
			CastQ(target)
		end
		if menu.keys.StartQ:get() and common.CanUseSpell(0) then return end
		if menu.combo.w:get() and common.GetPercentHealth(player) <= menu.combo.wx:get() and CountEnemyHeroInRange(500) >= 1 then
			game.cast("pos", 1, vec3(game.mousePos))
		end
		if menu.combo.e:get() then
			CastE(target)
		end
		if menu.combo.r:get() then
			if menu.combo.rc:get() and menu.combo.rh:get() then
				if common.CanUseSpell(3) and rDmg(target) > target.health then
					if EnemyCC == true or QT then
						CastR(target)
					end
				end
			elseif menu.combo.rh:get() and not menu.combo.rc:get() then
				if common.CanUseSpell(3) and rDmg(target) > target.health then
					CastR(target)
				end
			end
		end
	end
end

function Harass()
	if menu.keys.harass:get() then
		if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
			if menu.harass.q:get() and (gpred.collision.get_prediction(qPred, gpred.linear.get_prediction(qPred, target), target) == nil or table.getn(gpred.collision.get_prediction(qPred, gpred.linear.get_prediction(qPred, target), target)) == 1) then
				CastQ(target)
			end
			if menu.harass.e:get() then
				CastE(target)
			end
		end
	end
end


function CastE(target)
	if common.CanUseSpell(2) then
		local res = gpred.circular.get_prediction(ePred, target)
		if res and res.startPos:dist(res.endPos) < 1100 then
			game.cast("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end


function CastR(target)
	if common.CanUseSpell(3) then
		local seg = gpred.linear.get_prediction(rPred, target)
		if seg and seg.startPos:dist(seg.endPos) < 2000 then
			if not gpred.collision.get_prediction(rPred, seg, target) then
				game.cast("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end

function CastQ(target)
	if common.CanUseSpell(0) then
		local seg = gpred.linear.get_prediction(qPred, target)
		if seg and seg.startPos:dist(seg.endPos) < 1180 then
			if not gpred.collision.get_prediction(qPred, seg, target) then
				game.cast("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			else
				if table.getn(gpred.collision.get_prediction(qPred, seg, target)) == 1 then
					game.cast("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y));
				end
			end
		end
	end
end

function KillSteal()
	for i, enemy in pairs(GetEnemy()) do
		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.auto.uks:get() then
			local hp = enemy.health;
			if hp == 0 then return end
			if player:spellslot(0).state == 0 and qDmg(enemy) > hp and GetDistance(enemy) <= 1180 then
				CastQ(enemy);
			elseif player:spellslot(2).state == 0 and eDmg(enemy) > hp and GetDistance(enemy) <= 1100 then
				CastE(enemy);
			elseif player:spellslot(3).state == 0 and GetDistance(enemy) >= 1300 and rDmg(enemy) > hp then
				CastR(enemy)
			elseif player:spellslot(3).state == 0 and player:spellslot(0).state == 0 and GetDistance(enemy) <= 1180 and rDmg(enemy) + qDmg(enemy) > hp then
				CastQ(enemy)
				CastR(enemy)
			elseif player:spellslot(2).state == 0 and player:spellslot(3).state == 0 and GetDistance(enemy) <= 1100 and rDmg(enemy) + eDmg(enemy) > hp then
				CastE(enemy)
				CastR(enemy)
			elseif player:spellslot(3).state == 0 and player:spellslot(0).state == 0 and player:spellslot(2).state == 0 and GetDistance(enemy) <= 1180 and qDmg(enemy) + eDmg(enemy) + rDmg(enemy) > hp then
				CastE(enemy)
				CastQ(enemy)
				CastR(enemy)
			end
		end
	end
end


function oncreateobj(obj)
    if obj and obj.name and obj.type then
        if obj.name:find("Lux_Base_Q") then
            QT = true
        end
    end
end

function ondeleteobj(obj)
    if obj and obj.name and obj.type then
    	if obj.name:find("Lux_Base_Q") then
            QT = false
        end
    end
end

function OnUpdateBuff(buff, causer)
	if buff and buff.valid and buff.owner and buff.owner.type == player.type and buff.owner.team == enum.team.enemy then
		if buff.name == "SummonerExhaust" or buff.type == 5 or buff.type == 8 or buff.type == 11 or buff.type == 22 or buff.type == 24 or buff.type == 29 then
			EnemyCC = true
		end
	end
end

function OnRemoveBuff(buff, causer)
	if buff and buff.valid and buff.owner and buff.owner.type == player.type and buff.owner.team == enum.team.enemy then
		if buff.name == "SummonerExhaust" or buff.type == 5 or buff.type == 8 or buff.type == 11 or buff.type == 22 or buff.type == 24 or buff.type == 29 then
			EnemyCC = false
		end
	end
end 

--[Spyk Credits]--
function qDmg(target)
	local qDamage = CalcMagicDmg(target, QlvlDmg[player:spellslot(0).level] + player.flatMagicDamageMod * .7, player)
	return qDamage
end

function eDmg(target)
	local eDamage = CalcMagicDmg(target, ElvlDmg[player:spellslot(2).level] + player.flatMagicDamageMod * .6, player)
	return eDamage
end

function rDmg(target)
	local rDamage = CalcMagicDmg(target, RlvlDmg[player:spellslot(3).level] + player.flatMagicDamageMod * .75 + (Passive[player.level] + player.flatMagicDamageMod * .20), player)
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

function CountEnemyHeroInRange(range)
	local range, count = range*range, 0 
	for i = 0, objmanager.enemies_n - 1 do
		if player.pos:distSqr(objmanager.enemies[i].pos) < range then 
	 		count = count + 1 
	 	end 
	end 
	return count 
end

function GetDistance(p1, p2)
	p2 = p2 or player;
	return p1.path.serverPos:dist(p2.path.serverPos)
end

function GetTarget(range)
	range = range or 1400;
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
		glx.world.circle(player.pos, 1170, 2, draw.color.white, 100)
	end
	if menu.draws.e:get() and common.CanUseSpell(2) then
		glx.world.circle(player.pos, 1100, 3, draw.color.cyan, 100)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)
callback.add(enum.callback.recv.createobj, oncreateobj)
callback.add(enum.callback.recv.deleteobj, ondeleteobj)
callback.add(enum.callback.recv.removebuff, OnRemoveBuff)
callback.add(enum.callback.recv.updatebuff, OnUpdateBuff)

print("Cyrex Lux v"..version..": Loaded")