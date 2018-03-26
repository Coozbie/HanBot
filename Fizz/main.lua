local avada_lib = module.lib('avada_lib')
if not avada_lib then
	console.set_color(12)
	print("You need to have Avada Lib in your community_libs folder to run Lux!")
	print("You can find it here:")
	console.set_color(11)
	print("https://gitlab.soontm.net/get_clear_zip.php?fn=avada_lib")
	console.set_color(15)
	return
elseif avada_lib.version < 1.07 then
	console.set_color(12)
	print("Your need to have Avada Lib updated to run to run Lux!")
	print("You can find it here:")
	console.set_color(11)
	print("https://gitlab.soontm.net/get_clear_zip.php?fn=avada_lib")
	console.set_color(15)
	return
end
local version = "1.0"

local common = avada_lib.common
local draw = avada_lib.draw
local ts = avada_lib.targetSelector
local WP, WCheck = nil, nil
local onE = false
local enemies = common.GetEnemyHeroes()

local orb = module.internal("orb")
local gpred = module.internal("pred")

local QlvlDmg = {10, 25, 40, 55, 70}
local WlvlDmg = {20, 30, 40, 50, 60}
local ElvlDmg = {70, 120, 170, 220, 270}
local RlvlDmg = {225, 325, 425}

local ePred = { delay = 0.25, radius = 270, speed = 1000, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local rPred = { delay = 0.25, width = 120, speed = 1350, boundingRadiusMod = 1, collision = { hero = true, minion = false } }

local menu = menu("fizz", "Cyrex Fizz")
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

local function qDmg(target)
	local qDamage = QlvlDmg[player:spellSlot(0).level] + (common.GetTotalAP() * .55)
	return qDamage
end

local function wDmg(target)
	local wDamage = WlvlDmg[player:spellSlot(1).level] + (common.GetTotalAP() * .4)
	return wDamage
end

local function eDmg(target)
	local eDamage = ElvlDmg[player:spellSlot(2).level] + (common.GetTotalAP() * .75)
	return eDamage
end

local function rDmg(target)
	local rDamage = RlvlDmg[player:spellSlot(3).level] + (common.GetTotalAP() * .8)
	return rDamage
end

local function CastE(target)
	if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (700 * 700) then
		local res = gpred.circular.get_prediction(ePred, target)
		if res and res.startPos:dist(res.endPos) < 700 then
			player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

local function CastR(target)
    if player:spellSlot(3).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1280 * 1280) then
        local seg = gpred.linear.get_prediction(rPred, target)
        if seg and seg.startPos:dist(seg.endPos) > 910 and seg.startPos:dist(seg.endPos) < 1280 then
            if not gpred.collision.get_prediction(rPred, seg, target) then
                player:castSpell("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
            end
        end
    end
end

local function CastQ(target)
	if player:spellSlot(0).state == 0 and target.pos:dist(player.pos) <= menu.combo.qr:get() then
		player:castSpell("obj", 0, target)
	end
end


local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) and menu.auto.uks:get() then
			local hp = enemy.health
			local dist = player.path.serverPos:distSqr(enemy.path.serverPos)
			if hp == 0 then return end
			if player:spellSlot(0).state == 0 and qDmg(enemy) > hp and dist < (400 * 400) then
				CastQ(enemy);
			elseif player:spellSlot(3).state == 0 and rDmg(enemy) > hp and menu.auto.urks:get() and dist < (1280 * 1280) then
				local seg = gpred.linear.get_prediction(rPred, enemy)
		        if seg and seg.startPos:dist(seg.endPos) > 600 and seg.startPos:dist(seg.endPos) < 1280 then
		            if not gpred.collision.get_prediction(rPred, seg, enemy) then
		                player:castSpell("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
		            end
		        end
			end
		end
	end
end

local function Combo()
	local target = ts.target
	if target and common.IsValidTarget(target) and not target.buff["sionpassivezombie"] then
		if menu.combo.e:get() then
			if menu.combo.ed:get() == 1 then
				if player:spellSlot(2).state == 0 and target.pos:dist(player.pos) <= 600 then
					common.DelayAction(function()player:castSpell("pos", 2, (game.mousePos)) end, 0.5)
				end
			elseif menu.combo.ed:get() == 2 then
				common.DelayAction(function()CastE(target)end, 0.5)
			end
		end
		if menu.combo.q:get() then
			CastQ(target)
		end
		if menu.combo.w:get() and player:spellSlot(1).state == 0 and WP and target.pos:dist(player.pos) < 275 then
			player:castSpell("self", 1)
		elseif menu.combo.w:get() and player:spellSlot(1).state == 0 and wDmg(target) > target.health and target.pos:dist(player.pos) < 275 then
			player:castSpell("self", 1)
		end
		if menu.combo.r:get() and target.pos:dist(player.pos) >= menu.combo.rr:get() then
			if player:spellSlot(3).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1280 * 1290) then
        		local seg = gpred.linear.get_prediction(rPred, target)
    			if seg and seg.startPos:dist(seg.endPos) > menu.combo.rr:get() and seg.startPos:dist(seg.endPos) < 1280 then
        			if not gpred.collision.get_prediction(rPred, seg, target) then
            			player:castSpell("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
        			end
    			end
    		end
		end
	end
end

local function Harass()
	if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
		local target = ts.target
		if target and common.IsValidTarget(target) and not target.buff["sionpassivezombie"] then
			if menu.harass.q:get() and player:spellSlot(0).state == 0 then
				CastQ(target)
			end
			if menu.harass.w:get() and player:spellSlot(1).state == 0 and target.pos:dist(player.pos) < 275 and not orb.core.can_attack() then
				player:castSpell("self", 1)
			end
		end
	end
end

local function oncreateobj(obj)
    if obj.type then
        if obj.name:find("Fizz_Base_W_DmgMarkerMaintain") then
            WP = true
        end
        if obj.name:find("Fizz_Base_W_DmgMarker_champion") then
            WCheck = true
        end
        --if obj and obj.name and obj.name:lower():find("fizz") then print("Created "..obj.name) end
    end
end

local function ondeleteobj(obj)
    if obj.type then
        if obj.name:find("Fizz_Base_W_DmgMarkerMaintain") then
            WP = false
        end
        if obj.name:find("Fizz_Base_W_DmgMarker_champion") then
            WCheck = false
        end
    end
end

--[[local function processSpell(unit, spellProc)
	if unit == player and player:spellSlot(2).name == "FizzE" then
		onE = true print("E ON")
	elseif player:spellSlot(2).name == "FizzETwo" then 
		onE = false print("E OFF")
	end
end]]--

local function Run()
	if menu.keys.run:get() then
		player:move((game.mousePos))
		if player:spellSlot(2).state == 0 then
			player:castSpell("pos", 2, (game.mousePos))
		end
	end
end

local function AimR()
	if menu.keys.manual:get() then
		local target = ts.target
		player:move((game.mousePos))
		if target and target.pos:dist(player.pos) <= 1200 then
			CastR(target)
		end
	end
end


local function OnTick()
	if orb.combat.is_active() then Combo() end
	if orb.menu.hybrid:get() then Harass() end
	if menu.auto.uks:get() then KillSteal() end
	if menu.keys.run:get() then Run() end
	if menu.keys.manual:get() then AimR() end
end

local function OnDraw()
	if not player.isDead and player.isOnScreen then
		if menu.draws.q:get() and player:spellSlot(0).state == 0 then
			graphics.draw_circle(player.pos, menu.combo.qr:get(), 2, graphics.argb(255, 255, 255, 255), 50)
		end
		if menu.draws.e:get() and player:spellSlot(3).state == 0 then
			graphics.draw_circle(player.pos, menu.combo.rr:get(), 2, graphics.argb(255, 255, 255, 255), 50)
		end
	end
end

orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.createobj, oncreateobj)
cb.add(cb.deleteobj, ondeleteobj)

print("Cyrex Fizz v"..version..": Loaded")