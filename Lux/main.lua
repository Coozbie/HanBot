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
local common = avada_lib.common
local draw = avada_lib.draw
local ts = avada_lib.targetSelector
local orb = module.internal("orb")
local gpred = module.internal("pred")

local version = "1.4"

local Passive = { 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190}
local QlvlDmg = { 50, 100, 150, 200, 250 }
local ElvlDmg = { 60, 105, 150, 195, 240 }
local RlvlDmg = { 300, 400, 500 }

local qPred = { delay = 0.25, width = 70, speed = 1200, boundingRadiusMod = 1, collision = { hero = false, minion = true } }
local ePred = { delay = 0.25, radius = 275, speed = 1300, boundingRadiusMod = 0, collision = { hero = false, minion = false } }
local rPred = { delay = 1, width = 150, speed = 1000, boundingRadiusMod = 1, collision = { hero = false, minion = false } }

local menu = menu("lux", "Cyrex Lux")
	ts = ts(menu, 1200, 2)
	menu:header("script", "Cyrex Lux")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("StartQ", "Start Combo With Q", false, "K")

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)
		menu.combo:slider("wx", "Min HP% to Shield", 70, 0, 100, 5)
		menu.combo:header("xd", "E Settings")
		menu.combo:boolean("e", "Use E in Combo", true)

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
	ts:addToMenu()
	menu:header("version", "Version: 1.4")
	menu:header("author", "Author: Coozbie")
  
local function qDmg(target)
	local qDamage = QlvlDmg[player:spellSlot(0).level] + (common.GetTotalAP() * .7)
	return common.CalculateMagicDamage(target, qDamage)
end

local function eDmg(target)
	local eDamage = ElvlDmg[player:spellSlot(2).level] + (common.GetTotalAP() * .6)
	return common.CalculateMagicDamage(target, eDamage)
end

local function rDmg(target)
    local rDamage = RlvlDmg[player:spellSlot(3).level] + (common.GetTotalAP() * .75) + (Passive[player.levelRef] + (common.GetTotalAP() * .2))
    return common.CalculateMagicDamage(target, rDamage)
end

local function CastQ(target)
	if player:spellSlot(0).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1200 * 1200) then
		local seg = gpred.linear.get_prediction(qPred, target)
		if seg and seg.startPos:distSqr(seg.endPos) < (1170 * 1170) then
			if not gpred.collision.get_prediction(qPred, seg, target) then
				player:castSpell("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			else
				if table.getn(gpred.collision.get_prediction(qPred, seg, target)) == 1 then
					player:castSpell("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y));
				end
			end
		end
	end
end

local function CastE(target)
	if player:spellSlot(2).state == 0 and player.path.serverPos:distSqr(target.path.serverPos) < (1100 * 1100) then
		local res = gpred.circular.get_prediction(ePred, target)
		if res and res.startPos:distSqr(res.endPos) < (1090 * 1090) then
			player:castSpell("pos", 2, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end

local function CastR(target)
	if player:spellSlot(3).state == 0 then
		ts:update(2000)
		local seg = gpred.linear.get_prediction(rPred, target)
		if seg and seg.startPos:distSqr(seg.endPos) < (2000 * 2000) then
			if not gpred.collision.get_prediction(rPred, seg, target) and #common.GetAllyHeroesInRange(500, target.pos) < 1 then
				player:castSpell("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
			end
		end
	end
end

local function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) and menu.auto.uks:get() then
		local hp = enemy.health
      	local dist = player.path.serverPos:distSqr(enemy.path.serverPos)
			if player:spellSlot(0).state == 0 and dist <= (1180 * 1180) and qDmg(enemy) > hp then
				CastQ(enemy)
			elseif player:spellSlot(2).state == 0 and dist <= (1100 * 1100) and eDmg(enemy) > hp then
				CastE(enemy)
			elseif player:spellSlot(3).state == 0 and dist <= (2000 * 2000) and player.pos:dist(enemy.pos) >= 600 and rDmg(enemy) > hp then
				CastR(enemy)
			end
		end
	end
end

local function Combo()
	local target = ts.target
	if target and common.IsValidTarget(target) then
    local col = gpred.collision.get_prediction(qPred, gpred.linear.get_prediction(qPred, target), target)
		if menu.combo.q:get() and (col == nil or table.getn(col) == 1) then
			CastQ(target)
		end
		if menu.keys.StartQ:get() and player:spellSlot(0).state == 0 then return end
		if menu.combo.w:get() and common.GetPercentHealth(player) <= menu.combo.wx:get() and #common.GetEnemyHeroesInRange(600) >= 1 and player:spellSlot(1).state == 0 then
			player:castSpell("pos", 1, game.mousePos)
		end
		if menu.combo.e:get() and player:spellSlot(2).state == 0 then
			CastE(target)
		end
	end
end

local function Harass()
	if menu.keys.harass:get() then
		if common.GetPercentPar() >= menu.harass.Mana:get() then
      local col = gpred.collision.get_prediction(qPred, gpred.linear.get_prediction(qPred, target), target)
			if menu.harass.q:get() and (col == nil or table.getn(col) == 1) then
				CastQ(target)
			end
			if menu.harass.e:get() and player:spellSlot(2).state == 0 then
				CastE(target)
			end
		end
	end
end

local function OnTick()
	if orb.combat.is_active() then Combo() end
	if orb.menu.hybrid:get() then Harass() end
	if menu.auto.uks:get() then KillSteal() end
end

local function OnDraw()
  if not player.isDead and player.isOnScreen then
    if menu.draws.q:get() and player:spellSlot(0).state == 0 then
      graphics.draw_circle(player.pos, 1170, 2, graphics.argb(255, 255, 255, 255), 50)
    end
    if menu.draws.e:get() and player:spellSlot(2).state == 0 then
      graphics.draw_circle(player.pos, 1100, 2, graphics.argb(255, 255, 255, 255), 50)
    end
  end
end

orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.draw, OnDraw)

print("Cyrex Lux v"..version..": Loaded")