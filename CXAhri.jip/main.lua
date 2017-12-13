local version = "1.4"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw

local _enemyHeroes
local orb = module.internal("orb/main")
local gpred = module.internal("pred/main")

local qPred = { delay = 0.25, width = 80, speed = 1500, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local ePred = { delay = 0.25, width = 55, speed = 1550, boundingRadiusMod = 1, collision = { hero = true, minion = true } }

local menu = menuconfig("ahrigod", "Cyrex Ahri")
	menu:header("xd", "Cyrex Ahri")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("StartE", "Start Combo With E", false)
		--menu.keys:keybind("getcd", "Get Player CD", "T", false)
	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Combo Settings")
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:boolean("w", "Use W", true)
		menu.combo:boolean("e", "Use E", true)
		menu.combo:boolean("r", "Use R [Mouse & Beta]", false)

		menu.combo:header("xd", "Item Settings")
			menu.combo:menu("items", "Item Settings")
				menu.combo.items:header("xd", "Zhonya Settings")
				menu.combo.items:boolean("zhonya", "Use Zhonya", true)
				menu.combo.items:slider("itemhp", "Use Zhonyas if HP % <=", 10, 0, 100, 10)

				menu.combo.items:header("xd", "Frost Queen Settings")
				menu.combo.items:boolean("frost", "Use Frost Queen", true)
				menu.combo.items:slider("frostx", "Enemys Near: ", 1, 0, 5, 1)

				menu.combo.items:header("xd", "Seraphs Embrace Settings")
				menu.combo.items:boolean("seraph", "Use Seraphs Embrace", true)
				menu.combo.items:slider("seraphx", "Use Seraph if HP % <=", 10, 0, 100, 10)

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("w", "Use W", true)
		menu.harass:boolean("e", "Use E", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)
	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("e", "Draw R Range", true)
	menu:header("version", "Version: 1.4")
	menu:header("author", "Author: Coozbie")

function OnTick()
	target = GetTarget()
	if menu.keys.combo:get() and target then Combo() end
	if menu.keys.harass:get() and target then Harass() end
end

function Combo()
	if menu.keys.combo:get() then
		if menu.combo.e:get() and common.CanUseSpell(2) then
			local seg = gpred.linear.get_prediction(ePred, target)
			if seg and seg.startPos:dist(seg.endPos) < 935 then
				if not gpred.collision.get_prediction(ePred, seg, target) then
					game.cast("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
				end
			end
		end
		if menu.keys.StartE:get() and common.CanUseSpell(2) then return end
		if common.GetDistance(player, target) <= 530 and menu.combo.w:get() and common.CanUseSpell(1) then
			if Charm == true then
				game.cast("self", 1)
			elseif common.GetPercentHealth(target) <= 60 then
				game.cast("self", 1)
			end
		end
		if menu.combo.q:get() and common.CanUseSpell(0) then
			local seg = gpred.linear.get_prediction(qPred, target)
			if seg and seg.startPos:dist(seg.endPos) < 850 then
				if not gpred.collision.get_prediction(qPred, seg, target) then
					game.cast("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
				end
			end
		end
		common.DelayAction(function() CastR() end, 1)
	end
	--[Items]--
	if menu.combo.items.zhonya:get() and common.GetPercentHealth(player) <= menu.combo.items.itemhp:get() and CountEnemyHeroInRange(600) >= 1 then
		for i = 6, 11 do
	    	local item = player:spellslot(i).name
	    	if item and item == "ZhonyasHourglass" then
	    		game.cast("self", i)
	    	end
        end
	end
	if menu.combo.items.frost:get() and CountEnemyHeroInRange(1000) >= menu.combo.items.frostx:get() and common.GetDistance(player, target) > 700 then
		for i = 6, 11 do
			local item = player:spellslot(i).name
			if item and item == "ItemGlacialSpikeCast" or item == "ItemWraithCollar" then
				game.cast("self", i)
			end
		end
	end
	if menu.combo.items.seraph:get() and common.GetPercentHealth(player) <=  menu.combo.items.seraphx:get() and CountEnemyHeroInRange(600) >= 1 then
		for i = 6, 11 do
			local item = player:spellslot(i).name
			if item and item == "ItemSeraphsEmbrace" then
				game.cast("self", i)
			end
		end
	end
end

function Harass()
	if menu.keys.harass:get() then
		if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
			if menu.harass.e:get() and common.CanUseSpell(2) then
				local seg = gpred.linear.get_prediction(ePred, target)
				if seg and seg.startPos:dist(seg.endPos) < 950 then
					if not gpred.collision.get_prediction(ePred, seg, target) then
						game.cast("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
					end
				end
			end
			if common.GetDistance(player, target) <= 500 then
				if menu.harass.w:get() and common.CanUseSpell(1) then
					game.cast("self", 1)
				end
			end
			if menu.harass.q:get() and common.CanUseSpell(0) then
				local seg = gpred.linear.get_prediction(qPred, target)
				if seg and seg.startPos:dist(seg.endPos) < 850 then
					if not gpred.collision.get_prediction(qPred, seg, target) then
						game.cast("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
					end
				end
			end
		end
	end
end

function CastR()
	if menu.combo.r:get() and common.CanUseSpell(3) then
		game.cast("pos", 3, vec3(game.mousePos))
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


--[[function CD()
	if menu.keys.getcd:get() then
		print(player:spellslot(4).name)
	end
end
]]--

function OnUpdateBuff(buff, causer)
	if buff and buff.valid and buff.owner and buff.owner.type == player.type and buff.owner.team == enum.team.enemy then
		if buff.type == 22 or buff.name == "AhriSeduce" then
			Charm = true
		end
	end
end

function OnRemoveBuff(buff, causer)
	if buff and buff.valid and buff.owner and buff.owner.type == player.type and buff.owner.team == enum.team.enemy then
		if buff.type == 22 or buff.name == "AhriSeduce" then
			Charm = false
		end
	end
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

function OnDraw()
	if menu.draws.q:get() and common.CanUseSpell(0) then
		glx.world.circle(player.pos, 880, 1, draw.color.cyan, 500)
	end
	if menu.draws.e:get() and common.CanUseSpell(2) then
		glx.world.circle(player.pos, 975, 2, draw.color.purple, 500)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)
callback.add(enum.callback.recv.removebuff, OnRemoveBuff)
callback.add(enum.callback.recv.updatebuff, OnUpdateBuff)

print("Cyrex Ahri v"..version..": Loaded")