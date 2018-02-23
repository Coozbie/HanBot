local version = "1.3"

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
local draw = avada_lib.draw
local tselect = avada_lib.targetSelector
local minionmanager = objManager.minions

local orb = module.internal("orb")
local gpred = module.internal("pred")

local MiniGun = true
local EnemyCC = false
local QRange = {75, 100, 125, 150, 175}

local WlvlDmg = {10, 60, 110, 160, 210}
local RlvlDmg = {250, 350, 450}
local RB = {0.25, 0.3, 0.35}

local wPred = { delay = 0.7, width = 55, speed = 3300, boundingRadiusMod = 1, collision = { hero = true, minion = true } }
local ePred = { delay = 0.25, width = 60, speed = 1750, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local rPred = { delay = 0.6, width = 145, speed = 1700, boundingRadiusMod = 1, collision = { hero = true, minion = false } }

local menu = menu("jinx", "Cyrex Jinx")
	ts = tselect(menu, 1480)
	menu:header("script", "Cyrex Jinx")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("me", "Cast E Manually", "S", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:boolean("qr", "Swap Q for Range?", true)
		menu.combo:boolean("qe", "Swap to Minigun if no target?", true)
		menu.combo:boolean("qm", "Swap to Minigun on Low mana?", true)
		menu.combo:slider("Mana", "Min. Mana Percent: ", 20, 0, 100, 10)

		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)

		menu.combo:header("xd", "R Settings")
		menu.combo:boolean("r", "Use R", true)
		menu.combo:slider("rr", "Min. R Range To Cast", 1500, 1000, 3000, 100)

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("qr", "Swap Q for Range?", true)
		menu.harass:boolean("qe", "Swap to Minigun if no target?", true)
		menu.harass:boolean("w", "Use W", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "KillSteal Settings")
		menu.auto:boolean("uks", "Use Smart Killsteal", true)
		menu.auto:boolean("ukse", "Use R in Killsteal", true)
		menu.auto:header("xd", "Auto Spells")
		menu.auto:boolean("ae", "Auto E on CC'ed Enemys", true)

	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("r", "Draw R Range", true)

	ts:addToMenu()
	menu:header("version", "Version: 1.3")
	menu:header("author", "Author: Coozbie")

local function OnTick()
	if orb.combat.is_active() then Combo() end
	if orb.menu.hybrid:get() then Harass() end
	if menu.auto.uks:get() then KillSteal() end
	if menu.keys.me:get() then Manual() end
	--if menu.auto.ae:get() then AutoE() end
	if orb.menu.last_hit:get() and player:spellSlot(0).state == 0 and not MiniGun then player:castSpell("self", 0) end
	if not MiniGun and menu.combo.qm:get() then if player:spellSlot(0).state == 0 and (player.par / player.maxPar) * 100 <= menu.combo.Mana:get() then player:castSpell("self", 0) end end
    if orb.menu.lane_clear:get() and not MiniGun and player:spellSlot(0).state == 0 then
    	for i = 0, minionmanager.size[TEAM_ENEMY] - 1 do
			local minion = minionmanager[TEAM_ENEMY][i]
			local minions = common.GetMinionsInRange(300, TEAM_ENEMY, minion.pos)
      		if minion and minions and #minions < 4 and player.pos:dist(minion.pos) < 700 then
      			player:castSpell("self", 0)
      		end
    	end
	end
end


function Combo()
	if menu.combo.q:get() then
		ts:update((QRange[player:spellSlot(0).level] + 600))
		local target = ts.target
		if target and common.IsValidTarget(target) and player:spellSlot(0).state == 0 and (player.par / player.maxPar) * 100 >= menu.combo.Mana:get() then
			if MiniGun then
				if menu.combo.qr:get() then
					if CountEnemyHeroInRange(525) == 0 and target.pos:dist(player.pos) > 590 then
						player:castSpell("self", 0)
					elseif CountEnemyHeroInRange(525) >= 3 then
						player:castSpell("self", 0)
					end
				end
			elseif not MiniGun and menu.combo.qr:get() and target.pos:dist(player.pos) <= 525 then
				player:castSpell("self", 0)
			end
		elseif player:spellSlot(0).state == 0 and (player.par / player.maxPar) * 100 >= menu.combo.Mana:get() and CountEnemyHeroInRange(800) == 0 and menu.combo.qe:get() and not MiniGun then
			player:castSpell("self", 0)
		end
	end
	if menu.combo.w:get() and player:spellSlot(1).state == 0 then
		CastW()
	end
	if menu.combo.r:get() and player:spellSlot(3).state == 0 then
		ts:update(2500)
		local target = ts.target
		if target and common.IsValidTarget(target) and target.pos:dist(player.pos) > menu.combo.rr:get() and rDmg(target) > target.health then
			CastR(target)
		end
	end -- here
end

function Harass()
	if (player.par / player.maxPar) * 100 >= menu.harass.Mana:get() and not orb.combat.is_active() then
		if menu.harass.q:get() and player:spellSlot(0).state == 0 then
			ts:update((QRange[player:spellSlot(0).level] + 600))
			local target = ts.target
			if target and common.IsValidTarget(target) then
				if MiniGun then
					if menu.harass.qr:get() and CountEnemyHeroInRange(525) == 0 then
						if target.pos:dist(player.pos) > 595 then
							player:castSpell("self", 0)
						end
					end
				elseif not MiniGun and menu.harass.qr:get() and target.pos:dist(player.pos) <= 525 then
					player:castSpell("self", 0)
				end
			elseif menu.harass.qe:get() and CountEnemyHeroInRange(800) == 0 and not MiniGun then
				player:castSpell("self", 0)
			end
		end
		if menu.harass.w:get() and player:spellSlot(1).state == 0 then
			CastW()
		end
	end
end


function CastW() -- target was original param
    ts:update(1480)
    local target = ts.target
    if target and common.IsValidTarget(target) and target.pos:dist(player.pos) > (QRange[player:spellSlot(0).level] + 600) then
        local seg = gpred.linear.get_prediction(wPred, target)
        if seg and seg.startPos:dist(seg.endPos) <= 1500 then
            if common.IsValidTarget(target) and not gpred.collision.get_prediction(wPred, seg, target) and player:spellSlot(1).state == 0 then
                player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
            end
        end
    end
end

function CastR(target)
	local seg = gpred.linear.get_prediction(rPred, target)
    if seg and seg.startPos:dist(seg.endPos) <= 2500 then
        if not gpred.collision.get_prediction(rPred, seg, target) and #common.GetAllyHeroesInRange(500, target.pos) < 1 then
            player:castSpell("pos", 3, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
        end
    end
end

function KillSteal()
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) and enemy.isVisible and menu.auto.uks:get() and not enemy.isDead then
			if player:spellSlot(1).state == 0 and player.pos:dist(enemy.pos) <= 1480 and wDmg(enemy) > enemy.health and player.pos:dist(enemy.pos) > (QRange[player:spellSlot(0).level] + 600) then
				local seg = gpred.linear.get_prediction(wPred, enemy)
		        if seg and seg.startPos:dist(seg.endPos) <= 1500 then
		            if common.IsValidTarget(enemy) and not gpred.collision.get_prediction(wPred, seg, enemy) and player:spellSlot(1).state == 0 then
		                player:castSpell("pos", 1, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
		            end
		        end
			elseif player:spellSlot(3).state == 0 and rDmg(enemy) > enemy.health and menu.auto.ukse:get() and enemy.pos:dist(player.pos) > 1000 and enemy.pos:dist(player.pos) <= 2500 then
				common.DelayAction(function()CastR(enemy)end, 0.3)
			end
		end
	end
end


function Manual()
	if menu.keys.me:get() then
		local target = ts.target
		if target and common.IsValidTarget(target) then
			player:move(game.mousePos)
			if player:spellSlot(2).state == 0 and target.pos:dist(player.pos) < 850 then
				local seg = gpred.linear.get_prediction(ePred, target)
				if seg and seg.startPos:dist(seg.endPos) < 850 then
					player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
				end
			end
		end
	end
end


function launchE(pos)
	if pos then
		player:castSpell("pos", 2, vec3(pos.x, pos.y, pos.z));
		orb.core.set_server_pause();
	end
end

local function OnUpdateBuff(buff, causer)
	if buff and buff.valid and buff.owner and buff.owner.type == player.type and buff.owner.team == TEAM_ENEMY then
		if buff.type == 5 or buff.type == 11 or buff.type == 24 or buff.type == 29 then
			if buff.owner.pos:dist(player.pos) < 870 then
				common.DelayAction(function()launchE(buff.owner)end, 0.5)
			end
		end
	end
	if buff and buff.valid and buff.owner and buff.owner == player then
		if buff.name == "jinxqicon" then
			MiniGun = true
			print("MiniGun")
		end
	end
end


local function OnRemoveBuff(buff, causer)
	if buff and buff.valid and buff.owner and buff.owner == player then
		if buff.name == "jinxqicon" then
			MiniGun = false
			print("Rocket")
		end
	end
end 



function wDmg(target)
	local wDamage = common.CalculatePhysicalDamage(target, ({10, 60, 110, 160, 210})[player:spellSlot(1).level] + 1.4 * ((player.baseAttackDamage + player.flatPhysicalDamageMod)*(1 + player.percentPhysicalDamageMod)), player)
	--local wDamage = CalcADmg(target, WlvlDmg[player:spellSlot(1).level] + player.flatPhysicalDamageMod * 1.4, player)
	return wDamage
end

function rDmg(target)
	local rDamage = CalcADmg(target, RlvlDmg[player:spellSlot(3).level] + player.flatPhysicalDamageMod * 1.35 + RB[player:spellSlot(3).level] * (target.maxHealth - target.health), player)
	return rDamage
end


--RB[player:spellSlot(3).level] * (target.maxHealth - target.health) +
function CountEnemyHeroInRange(range)
	local range, count = range, 0 
	for i = 0, objManager.enemies_n - 1 do
		local enemy = objManager.enemies[i]
		if enemy and common.IsValidTarget(enemy) and player.pos:dist(enemy.pos) <= range then 
	 		count = count + 1
	 	end 
	end
	return count
end

function CountMinionsHeroInRange(range, pos)
	local pos = pos or player
	local range, count = range, 0 
	for i = 0, minionmanager.size[TEAM_ENEMY] - 1 do
		local minion = minionmanager[TEAM_ENEMY][i]
		if minion and not minion.isDead and minion.isVisible and player.pos:dist(minion.pos) <= range then 
	 		count = count + 1
	 	end 
	end
	return count, pos
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


local function OnDraw()
	if menu.draws.q:get() and player.isOnScreen then
		graphics.draw_circle(player.pos, common.GetAARange(player)-70, 2, graphics.argb(200, 214, 50, 212), 100)
	end
	if menu.draws.r:get() and player:spellSlot(3).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, menu.combo.rr:get(), 2, graphics.argb(255, 127, 122, 255), 100)
	end
end

orb.combat.register_f_pre_tick(function()
        if ts.target and ts.target.pos:dist(player.pos) < player.attackRange + player.boundingRadius + ts.target.boundingRadius then
            orb.combat.target = ts.target
        end
        OnTick()
        return false
    end)
cb.add(cb.draw, OnDraw)
cb.add(cb.removebuff, OnRemoveBuff)
cb.add(cb.updatebuff, OnUpdateBuff)

print("Cyrex Jinx v"..version..": Loaded")

--print(player:spellSlot(0).name)