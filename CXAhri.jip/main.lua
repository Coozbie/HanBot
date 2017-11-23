local version = "1.4"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw
local ts = alib.targetSelector

local orb = module.internal("orb")
local gpred = module.internal("pred")

local enemies = common.GetEnemyHeroes()

local qPred = { delay = 0.25, width = 80, speed = 1500, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local ePred = { delay = 0.25, width = 50, speed = 1550, boundingRadiusMod = 1, collision = { hero = true, minion = true } }

local igniteDmg = { 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410 } --"50 + (20 * myHero.level)"
local igniteSlot = nil
if player:spellslot(4).name == "SummonerDot" then
	igniteSlot = 4
elseif player:spellslot(5).name == "SummonerDot" then
	igniteSlot = 5
end

local menu = menuconfig("ahrigod", "Cyrex Ahri")
	ts = ts(menu, 1500)
	menu:header("xd", "Cyrex Ahri")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("StartE", "Start Combo With E", false)
		menu.keys:keybind("getcd", "Get Player CD", "T", false)
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
	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "Automatic Settings")
		menu.auto:boolean("Ignite", "Auto Ignite", true)
	ts:addToMenu()
	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("e", "Draw R Range", true)
	menu:header("version", "Version: 1.3")
	menu:header("author", "Author: Coozbie")

function OnTick()
	if menu.keys.combo:get() then Combo() end
	if menu.keys.harass:get() then Harass() end
	if menu.auto.Ignite:get() then AutoIgnite() end
end

function Combo()
	if menu.keys.combo:get() then
		local target = ts.target
		if target and not target.isDead then
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
				if common.HasBuff(target, "AhriSeduce") then
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
			local target = ts.target
			if target and not target.isDead then
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
end

function CastR()
	if menu.combo.r:get() and common.CanUseSpell(3) then
		game.cast("pos", 3, vec3(game.mousePos))
	end
end



--[[function AutoIgnite()
	local target = ts.target
	if target and not target.isDead and menu.KillSteal.Ignite2:get() and common.IsValidTarget(target) and common.GetDistance(player, target) <= 600 and target.health <= igniteDmg[player.level] then
		game.cast("obj", igniteSlot, target)
	end
end--]]

function AutoIgnite()
	for i, enemy in ipairs(enemies) do
        if common.IsValidTarget(enemy) and common.GetDistance(player, enemy) <= 600 then
            if not player.isDead and igniteSlot and menu.auto.Ignite:get() and common.CanUseSpell(igniteSlot) and igniteDmg[player.level] > enemy.health then game.cast("obj", igniteSlot, enemy) end
        end
    end
end

--[[function AutoZhonya()
	if menu.auto.zhonya:get() and common.GetPercentHealth(player) <= menu.combo.itemhp:get() then
		for i = 6, 11 do
	    	local item = player:spellslot(i).name
	    	if item and item == "ZhonyasHourglass" then
	    		game.cast("self", i)
	    	end
        end
	end
end--]]

function CountEnemyHeroInRange(range)
	local range, count = range*range, 0 
	for i = 0, objmanager.enemies_n - 1 do
		if player.pos:distSqr(objmanager.enemies[i].pos) < range then 
	 		count = count + 1 
	 	end 
	end 
	return count 
end


function CD()
	if menu.keys.getcd:get() then
		print(player:spellslot(4).name)
	end
end

function CooldownReduction(damageSource)
    local damageSource = damageSource or player
    return damageSource.CooldownMod
end


function OnDraw()
	if menu.draws.q:get() then
		glx.world.circle(player.pos, 880, 1, draw.color.gold, 50)
	end
	if menu.draws.e:get() then
		glx.world.circle(player.pos, 975, 1, draw.color.golden_rod, 50)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)

print("Cyrex Ahri v"..version..": Loaded")
