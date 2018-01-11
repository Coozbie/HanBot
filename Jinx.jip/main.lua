local version = "1.1"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw

local orb = module.internal("orb/main")
local gpred = module.internal("pred/main")

local MiniGun = false
local EnemyCC = false
local QRange = {75, 100, 125, 150, 175}

local WlvlDmg = {10, 60, 110, 160, 210}
local RlvlDmg = {250, 350, 450}
local RB = {0.25, 0.3, 0.35}

local wPred = { delay = 0.6, width = 60, speed = 3200, boundingRadiusMod = 1, collision = { hero = true, minion = true } }
local ePred = { delay = 0.25, width = 30, speed = 1000, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local rPred = { delay = 0.6, width = 120, speed = 1700, boundingRadiusMod = 1, collision = { hero = true, minion = false } }

local menu = menuconfig("jinx", "Cyrex Jinx")
	menu:header("script", "Cyrex Jinx")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("me", "Cast E Manually", "S", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:boolean("qr", "Swap Q for Range?", true)
		menu.combo:boolean("qm", "Swap to Minigun on Low mana?", true)
		menu.combo:slider("Mana", "Min. Mana Percent: ", 20, 0, 100, 10)
		menu.combo:boolean("qe", "Swap to Minigun if no target?", true)

		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)

		menu.combo:header("xd", "R Settings")
		menu.combo:boolean("r", "Use R", true)
		menu.combo:slider("rr", "Min. R Range To Cast", 2000, 1000, 10000, 500)

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("qr", "Swap Q for Range?", true)
		menu.harass:boolean("w", "Use W", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "KillSteal Settings")
		menu.auto:boolean("uks", "Use Smart Killsteal", true)
		menu.auto:boolean("ukse", "Use R in Killsteal", false)
		menu.auto:header("xd", "Auto Spells")
		menu.auto:boolean("ae", "Auto E on CC'ed Enemys", true)

	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("r", "Draw R Range", true)
	menu:header("version", "Version: 1.1")
	menu:header("author", "Author: Coozbie")

function OnTick()
	target = GetTarget()
	if menu.keys.combo:get() and target then Combo() end
	if menu.keys.harass:get() and target then Harass() end
	if menu.auto.uks:get() then KillSteal() end
	if menu.keys.me:get() and target then Manual() end
	if menu.combo.qe:get() and player:spellslot(0).state == 0 and #common.GetEnemyHeroesInRange(1000, player) == 0 and not MiniGun then game.cast("self", 0) end
	if menu.auto.ae:get() then AutoE() end
	if not MiniGun and menu.combo.qm:get() then if common.CanUseSpell(0) and player.par / player.maxPar * 100 <= menu.combo.Mana:get() then game.cast("self", 0) end end
end

function Combo()
	if menu.keys.combo:get() then
		if menu.combo.q:get() and player:spellslot(0).state == 0 and player.par / player.maxPar * 100 >= menu.combo.Mana:get() then
			if MiniGun then
				if menu.combo.qr:get() and CountEnemyHeroInRange(525) == 0 and GetDistance(target) <= (QRange[player:spellslot(0).level] + 600) then
					if GetDistance(target) > 600 then
						game.cast("self", 0)
					end
				end
			elseif not MiniGun and menu.combo.qr:get() and GetDistance(target) <= 535 then
				game.cast("self", 0)
			end			
		end
		if menu.combo.w:get() and GetDistance(target) > common.GetAARange(player) then
			CastW(target)
		end
		if menu.combo.r:get() and player:spellslot(3).state == 0 and GetDistance(target) >= menu.combo.rr:get() and rDmg(target) > target.health then
			CastR(target)
		end
		WeirdR()
	end
end

function Harass()
	if menu.keys.harass:get() then
		if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
			if menu.harass.q:get() and common.CanUseSpell(0) then
			if MiniGun then
				if menu.harass.qr:get() and CountEnemyHeroInRange(525) == 0 and GetDistance(target) < (QRange[player:spellslot(0).level] + 600) then
					if GetDistance(target) > 600 then
						game.cast("self", 0)
					end
				end
			elseif not MiniGun and menu.harass.qr:get() and GetDistance(target) <= 525 then
				game.cast("self", 0)
			end			
		end
			if menu.harass.w:get() and GetDistance(target) > 650 then
				CastW(target)
			end
		end
	end
end


function CastW(target)
	if common.CanUseSpell(1) then
		local seg = gpred.linear.get_prediction(wPred, target)
		if seg and seg.startPos:dist(seg.endPos) < 1480 then
			if not gpred.collision.get_prediction(wPred, seg, target) then
				game.cast("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end


function CastR(target)
	if common.CanUseSpell(3) then
		local seg = gpred.linear.get_prediction(rPred, target)
		if seg then
			if not gpred.collision.get_prediction(rPred, seg, target) then
				game.cast("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end


function KillSteal()
	for i, enemy in pairs(GetEnemy()) do
		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.auto.uks:get() then
			local hp = enemy.health;
			if hp == 0 then return end
			if player:spellslot(1).state == 0 and wDmg(enemy) > hp and GetDistance(enemy) <= 1500 then
				CastW(enemy);
			elseif player:spellslot(3).state == 0 and rDmg(enemy) > hp and menu.auto.ukse:get() and GetDistance(enemy) <= 3000 and GetDistance(enemy) > 1200 then
				CastR(enemy);
			elseif player:spellslot(3).state == 0 and player:spellslot(1).state == 0 and (wDmg(enemy) + rDmg(enemy) > hp) and menu.auto.ukse:get() and GetDistance(enemy) <= 1500 then
				CastR(enemy)
				CastW(enemy)
			end
		end
	end
end


function Manual()
	if menu.keys.me:get() then
		game.issue("move", vec3(game.mousePos))
		if common.CanUseSpell(2) and GetDistance(target) < 850 then
			local seg = gpred.linear.get_prediction(ePred, target)
			if seg and seg.startPos:dist(seg.endPos) < 850 then
				if not gpred.collision.get_prediction(ePred, seg, target) then
					game.cast("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
				end
			end
		end
	end
end

function AutoE()
	for i, enemy in pairs(GetEnemy()) do
		if not enemy.isDead and enemy.isVisible and enemy.isTargetable then
			if EnemyCC == true and GetDistance(enemy) < 750 then
				if common.CanUseSpell(2) then
					local seg = gpred.linear.get_prediction(ePred, target)
					if seg and seg.startPos:dist(seg.endPos) < 850 then
						if not gpred.collision.get_prediction(ePred, seg, target) then
							game.cast("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
						end
					end
				end
			end
		end
	end
end

function OnUpdateBuff(buff, causer)
	if buff and buff.valid and buff.owner and buff.owner.type == player.type and buff.owner.team == enum.team.enemy then
		if buff.type == 5 or buff.type == 8 or buff.type == 11 or buff.type == 22 or buff.type == 24 or buff.type == 29 then
			EnemyCC = true
			common.DelayAction(function() AutoE() end, 0.5)
		end
	end
	if buff and buff.valid and buff.owner and buff.owner == player then
		if buff.name == "jinxqicon" then
			MiniGun = true
			print("MiniGun")
		end
	end
end

function OnRemoveBuff(buff, causer)
	if buff and buff.valid and buff.owner and buff.owner.type == player.type and buff.owner.team == enum.team.enemy then
		if buff.type == 5 or buff.type == 8 or buff.type == 11 or buff.type == 22 or buff.type == 24 or buff.type == 29 then
			EnemyCC = false
		end
	end
	if buff and buff.valid and buff.owner and buff.owner == player then
		if buff.name == "jinxqicon" then
			MiniGun = false
			print("Rocket")
		end
	end
end 

function WeirdR()
	if menu.combo.r:get() then
		for i, enemy in pairs(GetEnemy(10000)) do
			if not enemy.isDead and enemy.isVisible and enemy.isTargetable and enemy.isRecalling or EnemyCC == true then
				if GetDistance(enemy) > menu.combo.rr:get() then
					if player:spellslot(3).state == 0 and rDmg(target) > target.health then
						CastR(enemy)
					end
				end
			end
		end
	end
end


--[Spyk Credits]--
function wDmg(target)
	local wDamage = CalcADmg(target, WlvlDmg[player:spellslot(1).level] + player.flatPhysicalDamageMod * 1.4, player)
	return wDamage
end

function rDmg(target)
	local rDamage = CalcADmg(target, RlvlDmg[player:spellslot(3).level] + player.flatPhysicalDamageMod * 1.5 + RB[player:spellslot(3).level] * (target.maxHealth - target.health), player)
	return rDamage
end

--RB[player:spellslot(3).level] * (target.maxHealth - target.health) +
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
	local targetD = target.armor * math.ceil(from.percentBonusArmorPenetration);
	local dmgMul = 100 / (100 + targetD);
	amount = amount * dmgMul;
	return math.floor(amount)
end

function GetDistance(p1, p2)
	p2 = p2 or player;
	return p1.path.serverPos:dist(p2.path.serverPos)
end

function GetTarget(range)
	range = range or 1500;
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
		glx.world.circle(player.pos, common.GetAARange(player), 2, draw.color.purple, 100)
	end
	if menu.draws.r:get() and common.CanUseSpell(3) then
		glx.world.circle(player.pos, menu.combo.rr:get(), 3, draw.color.blue, 100)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)
callback.add(enum.callback.recv.removebuff, OnRemoveBuff)
callback.add(enum.callback.recv.updatebuff, OnUpdateBuff)

print("Cyrex Jinx v"..version..": Loaded")