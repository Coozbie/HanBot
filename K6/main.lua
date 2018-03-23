local version = "1.03"

local avada_lib = module.lib('avada_lib')
if not avada_lib then
	console.set_color(12)
	print("You need to have Avada Lib in your community_libs folder to run Activator!")
	print("You can find it here:")
	console.set_color(11)
	print("https://gitlab.soontm.net/get_clear_zip.php?fn=avada_lib")
	console.set_color(15)
	return
elseif avada_lib.version < 1 then
	console.set_color(12)
	print("Your need to have Avada Lib updated to run to run Activator!")
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
local minionmanager = objManager.minions

local QlvlDmg = {50, 75, 100, 125, 150}
local WlvlDmg = {85, 115, 145, 165, 205}
local ElvlDmg = {65, 100, 135, 170, 205}
local IsoDmg = {14, 22, 30, 38, 46, 54, 62, 70, 78, 86, 94, 102, 110, 118, 126, 134, 142, 150}
local QRange, ERange = 0, 0
local Isolated = false

local ePred = { delay = 0.25, radius = 300, speed = 1500, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local wPred = { delay = 0.25, width = 70, speed = 1700, boundingRadiusMod = 1, collision = { hero = true, minion = true } }

local menu = menu("k6", "Khantum Phyzix")
	ts = ts(menu, 1000)
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

	menu:menu("jg", "Jungle Clear Settings")
		menu.jg:header("xd", "Jungle Settings")
		menu.jg:boolean("q", "Use Q", true)
		menu.jg:boolean("w", "Use W", true)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "KillSteal Settings")
		menu.auto:boolean("uks", "Use Smart Killsteal", true)
		menu.auto:boolean("ukse", "Use E in Killsteal", false)
		menu.auto:slider("mhp", "Min. HP to E: ", 30, 0, 100, 10)

	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("e", "Draw E Range", true)
	ts:addToMenu()
	menu:header("version", "Version: 1.03")
	menu:header("author", "Author: Coozbie")

local function OnTick()
	if orb.combat.is_active() then Combo() end
	if orb.menu.hybrid:get() then Harass() end
	if menu.auto.uks:get() then KillSteal() end
	if menu.keys.run:get() then Run() end
	if menu.draws.q:get() or menu.draws.e:get() then EvolutionCheck() end
	if orb.menu.lane_clear:get() then
		Clear()
	end
end

function Combo()
	local target = ts.target
	if target and common.IsValidTarget(target) then
		if menu.combo.e:get() then
			if menu.combo.ed:get() == 1 then
				if player:spellSlot(2).state == 0 and target.pos:dist(player.pos) <= 700 then
					common.DelayAction(function()player:castSpell("pos", 2, (game.mousePos)) end, 0.2)
				end
			elseif menu.combo.ed:get() == 2 then
				CastE(target)
			end
		end
		if menu.combo.q:get() then
			CastQ(target)
		end
		if menu.combo.w:get() and target.pos:dist(player.pos) >= 470 then
			CastW(target)
		elseif menu.combo.w:get() and Isolated == true or player:spellSlot(0).state ~= 0 then
			CastW(target)
		end
		if menu.combo.r:get() and player:spellSlot(3).state == 0 then
			if menu.combo.rm:get() == 2 then
				if player:spellSlot(1).state == 0 and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and target.health <= ((qDmg(target)*2) + wDmg(target) + eDmg(target)) and target.health > (wDmg(target) + eDmg(target)) then
	                if target.pos:dist(player.pos) <= 900 then
	                    if player:spellSlot(2).state == 0 then CastR(target) end
	                end
	            end
	        elseif menu.combo.rm:get() == 1 then
	            if target.pos:dist(player.pos) <= 500 then 
	                if player:spellSlot(2).state == 0 then CastR(target) end
	            end
	        end
		end
	end
end

function Harass()
	local target = ts.target
	if target and common.IsValidTarget(target) then
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
end

function Clear()
	local target = { obj = nil, health = 0, mode = "jungleclear" }
	local aaRange = player.attackRange + player.boundingRadius + 200
	for i = 0, minionmanager.size[TEAM_NEUTRAL] - 1 do
		local obj = minionmanager[TEAM_NEUTRAL][i]
		if player.pos:dist(obj.pos) <= aaRange and obj.maxHealth > target.health then
			target.obj = obj
			target.health = obj.maxHealth
		end
	end
	if target.obj then
		if target.mode == "jungleclear" then
			if menu.jg.q:get() and player:spellSlot(0).state == 0 then
				player:castSpell("obj", 0, target.obj)
			end
			if menu.jg.w:get() and player:spellSlot(1).state == 0 then
				CastW(target.obj)
			end
		end
	end
end


function CastE(target)
	if player:spellSlot(2).state == 0 then
		if player:spellSlot(2).name == "KhazixE" then
			local res = gpred.circular.get_prediction(ePred, target)
			if res and res.startPos:dist(res.endPos) < 600 and res.startPos:dist(res.endPos) > 325  then
				player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
			end
		elseif player:spellSlot(2).name == "KhazixELong" then
			local res = gpred.circular.get_prediction(ePred, target)
			if res and res.startPos:dist(res.endPos) < 900 and res.startPos:dist(res.endPos) > 400 then
				player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
			end
		end
	end
end

function CastW(target)
	if player:spellSlot(1).state == 0 then
		local seg = gpred.linear.get_prediction(wPred, target)
		if seg and seg.startPos:dist(seg.endPos) < 970 then
			if not gpred.collision.get_prediction(wPred, seg, target) then
				player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end

function CastR(target)
	if player:spellSlot(3).state == 0 then
		player:castSpell("self", 3)
	end
end

function CastQ(target)
	if player:spellSlot(0).state == 0 then
		if player:spellSlot(0).name == "KhazixQ" then
			if target.pos:dist(player.pos) <= 325 then
				player:castSpell("obj", 0, target)
			end
		elseif player:spellSlot(0).name == "KhazixQLong" then
			if target.pos:dist(player.pos) then
				player:castSpell("obj", 0, target)
			end
		end
	end
end


function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.auto.uks:get() then
			local hp = enemy.health;
			if hp == 0 then return end
			if player:spellSlot(0).state == 0 and qDmg(enemy) + PlayerAD() > hp and enemy.pos:dist(player.pos) < 325 then
				CastQ(enemy);
			elseif player:spellSlot(1).state == 0 and wDmg(enemy) > hp and enemy.pos:dist(player.pos) < 970 then
				CastW(enemy);
			elseif player:spellSlot(1).state == 0 and player:spellSlot(0).state == 0 and wDmg(enemy) + qDmg(enemy) > hp and enemy.pos:dist(player.pos) < 500 then
				CastQ(enemy)
				CastW(enemy)
			elseif player:spellSlot(2).state == 0 and player:spellSlot(0).state == 0 and qDmg(enemy) + eDmg(enemy) + PlayerAD() > hp and menu.auto.ukse:get() and common.GetPercentHealth(player) >= menu.auto.mhp:get() and enemy.pos:dist(player.pos) < 990 then
				CastE(enemy)
				CastQ(enemy)
			elseif player:spellSlot(1).state == 0 and player:spellSlot(0).state == 0 and player:spellSlot(2).state == 0 and qDmg(enemy) + eDmg(enemy) + wDmg(enemy) + PlayerAD() > hp and menu.auto.ukse:get() and common.GetPercentHealth(player) >= menu.auto.mhp:get() and enemy.pos:dist(player.pos) < 990 then
				CastE(enemy)
				CastQ(enemy)
				if enemy.pos:dist(player.pos) <= 700 then
					CastW(enemy)
				end
			end
		end
	end
end


function Run()
	if menu.keys.run:get() then
		player:move((game.mousePos))
		if player:spellSlot(2).state == 0 then
			player:castSpell("pos", 2, (game.mousePos))
		end
	end
end

function EvolutionCheck()
    if player:spellSlot(0).name == "KhazixQ" then
        QRange = 325
    elseif player:spellSlot(0).name == "KhazixQLong" then
    	QRange = 375
    end 
    if player:spellSlot(2).name == "KhazixE" then
        ERange = 700
    elseif player:spellSlot(2).name == "KhazixELong" then
    	ERange = 900
    end 
end

local function oncreateobj(obj)
    if obj and obj.name and obj.type then
        --if obj and obj.name and obj.name:lower():find("indicator") then print("Created "..obj.name) end
        if obj.name:find("SingleEnemy_Indicator") then
            Isolated = true
        end
    end
end

local function ondeleteobj(obj)
    if obj and obj.name and obj.type then
    	if obj.name:find("SingleEnemy_Indicator") then
            Isolated = false
        end
    end
end



--[Spyk Credits]--
function qDmg(target)
	if Isolated == false then
		local qDamage = CalcADmg(target, QlvlDmg[player:spellSlot(0).level] + player.flatPhysicalDamageMod * 1.3, player)
		return qDamage
	else
		local qDamage = CalcADmg(target, (QlvlDmg[player:spellSlot(0).level] + player.flatPhysicalDamageMod * 1.3) * 1, player)
		return qDamage
	end
end

function wDmg(target)
	local wDamage = CalcADmg(target, WlvlDmg[player:spellSlot(1).level] + player.flatPhysicalDamageMod * 1, player)
	return wDamage
end

function eDmg(target)
	local eDamage = CalcADmg(target, ElvlDmg[player:spellSlot(2).level] + player.flatPhysicalDamageMod * .2, player)
	return eDamage
end

function PlayerAD()
	if Isolated == false then
    	return player.flatPhysicalDamageMod + player.baseAttackDamage
    else
    	return player.flatPhysicalDamageMod + player.baseAttackDamage + (IsoDmg[player.levelRef] + player.flatPhysicalDamageMod * .2 )
    end
end

function CountEnemyHeroInRange(range)
	local range, count = range*range, 0 
	for i = 0, objManager.enemies_n - 1 do
		if player.pos:distSqr(objManager.enemies[i].pos) < range then 
	 		count = count + 1 
	 	end 
	end 
	return count 
end

function CalcADmg(target, amount, from)
	local from = from or player or objManager.player;
	local target = target or orb.combat.target;
	local amount = amount or 0;
	local targetD = target.armor * math.ceil(from.percentBonusArmorPenetration);
	local dmgMul = 100 / (100 + targetD);
	amount = amount * dmgMul;
	return math.floor(amount)
end

function OnDraw()
	if menu.draws.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, QRange, 2, graphics.argb(255, 168, 0, 157), 50)
	end
	if menu.draws.e:get() and player:spellSlot(2).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, ERange, 2, graphics.argb(255, 0, 21, 255), 50)
	end
end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.createobj, oncreateobj)
cb.add(cb.deleteobj, ondeleteobj)

print("Khantum Phyzix v"..version..": Loaded")