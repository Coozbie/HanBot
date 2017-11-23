local version = "1.0"

local alib = module.load("avada_lib")
local common = alib.common
local draw = alib.draw
local ts = alib.targetSelector

local orb = module.internal("orb")
local gpred = module.internal("pred")

local enemies = common.GetEnemyHeroes()
local ally = common.GetAllyHeroes()

local qPred = { delay = 0.7, radius = 140, speed = math.huge, boundingRadiusMod = 0, collision = { hero = false, minion = false } }

local igniteDmg = { 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410 } --"50 + (20 * myHero.level)"
local QlvlDmg = {75, 115, 165, 230, 300}
local igniteSlot = nil
if player:spellslot(4).name == "SummonerDot" then
	igniteSlot = 4
elseif player:spellslot(5).name == "SummonerDot" then
	igniteSlot = 5
end

local menu = menuconfig("zilean", "Cyrex Zilean")
	ts = ts(menu, 1300)
	menu:header("script", "Cyrex Zilean")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("combo", "Combo Key", "Space", false)
		menu.keys:keybind("harass", "Harass Key", "C", false)
		menu.keys:keybind("clear", "Clear Key", "V", false)
		menu.keys:keybind("run", "Marathon Mode", "S", false)
		menu.keys:keybind("ultself", "Manual Self Ult", "A", false)

	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Combo Settings")
		menu.combo:dropdown("mode", "Choose Mode: ", 2, {"               AP Mid", "               Support"})
		menu.combo:boolean("q", "Use Q", true)
		menu.combo:boolean("w", "Use W for Double Q", true)
		menu.combo:boolean("e", "Smart E", true)

		menu.combo:header("xd", "R Settings")
			menu.combo:menu("rs", "R Settings")
					menu.combo.rs:header("xd", "Player Settings")
					menu.combo.rs:boolean("r", "Use Smart R", true)
					menu.combo.rs:slider("rx", "R on X Enemys in Range", 1, 0, 5, 1)
					menu.combo.rs:slider("rhp", "What HP% to Ult", 10, 0, 100, 10)

					menu.combo.rs:header("xd", "Ally Settings")
					menu.combo.rs:menu("x", "Ally Selection")
						for i, allies in ipairs(ally) do
							menu.combo.rs.x:boolean(allies.charName, "Revive: "..allies.charName, false) 
						end
					menu.combo.rs:slider("ahp", "HP% To Revive Ally", 10, 0, 100, 10)

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
		menu.harass:boolean("w", "Use W for Double Q", true)
		menu.harass:boolean("e", "Use E", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)

	menu:menu("auto", "Automatic Settings")
		menu.auto:header("xd", "Automatic and KillSteal Settings")
		menu.auto:boolean("Ignite", "Auto Ignite", true)
		menu.auto:menu("ks", "KillSteal")
			menu.auto.ks:header("xd", "Killsteal Settings")
			menu.auto.ks:boolean("uks", "Use Killsteal", true)
			menu.auto.ks:boolean("ksq", "Use Q in Killsteal", true)
			menu.auto.ks:boolean("ksqwq", "Use QWQ in Killsteal", true)



	ts:addToMenu()

	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("e", "Draw R Range", true)
	menu:header("version", "Version: 1.0")
	menu:header("author", "Author: Coozbie")

function OnTick()
	if menu.keys.combo:get() then Combo() end
	if menu.keys.harass:get() then Harass() end
	if menu.auto.Ignite:get() then AutoIgnite() end
	if menu.auto.ks.uks:get() then KillSteal() end
	if menu.combo.rs.r:get() then autoUlt() end
	if menu.keys.run:get() then Run() end
	if menu.keys.ultself:get() and common.CanUseSpell(3) then game.cast("obj", 3, player) end
end

function Combo()
	if menu.keys.combo:get() then
		local target = ts.target
		if target and not target.isDead then
			if menu.combo.mode:get() == 2 then
				if menu.combo.q:get() and not menu.combo.w:get() then
					CastQ(taret)
				end
				if menu.combo.q:get() and menu.combo.w:get() then
					QWQ(target)
				end
				if menu.combo.e:get() and CountAllysInRange(600) >= 1 and common.GetDistance(player, target) <= 600 and common.CanUseSpell(2) then
					game.cast("obj", 2, target)
				end
			elseif menu.combo.mode:get() == 1 then
				if menu.combo.q:get() and not menu.combo.w:get() then
					CastQ(target)
				elseif menu.combo.q:get() and menu.combo.w:get() then
					QWQ(target)
				end
				if menu.combo.e:get() then
					if common.GetDistance(player, target) > 900 and common.GetDistance(player, target) < 1100 then
						game.cast("obj", 2, player)
					elseif common.GetDistance(player, target) <= 880 then
						game.cast("obj", 2, target)
					end
					for i, enemy in pairs (enemies) do
		    			if enemy ~= target and common.GetDistance(player, enemy) < 400 then
			    			CastSpell(_E, enemy)
		    			end
					end
				end
			end
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
				if menu.harass.q:get() and not menu.harass.w:get() then
					CastQ(taret)
				elseif menu.harass.q:get() and menu.harass.w:get() then
					QWQ(target)
				end
				if menu.harass.e:get() and CountAllysInRange(600) >= 1 and common.GetDistance(player, target) <= 600 and common.CanUseSpell(2) then
					game.cast("obj", 2, target)
				end
			end
		end
	end
end

function CastQ(target)
	if common.CanUseSpell(0) then
		local res = gpred.circular.get_prediction(qPred, target)
		if res and res.startPos:dist(res.endPos) < 880 then
			game.cast("pos", 0, vec3(res.endPos.x, game.mousePos.y, res.endPos.y))
		end
	end
end


function autoUlt()
	if not common.CanUseSpell(3) then return end
	if menu.combo.rs.r:get() and CountEnemyHeroInRange(600) >= menu.combo.rs.rx:get() and common.GetPercentHealth(player) <=  menu.combo.rs.rhp:get() then
		game.cast("obj", 3, player)
	end
	for _, allies in ipairs(ally) do
		if menu.combo.rs.x[allies.charName]:get() and common.GetPercentHealth(allies) <= menu.combo.rs.ahp:get() and common.GetDistance(allies) <= 600 and CountEnemyHeroInRange(800) >= 1 then
			game.cast("obj", 3, allies)
		end
	end
end


local QWQCast = false
function QWQ(target)
	if QWQCast == false then
	    if player.par >= player.manaCost0 * 2 + player.manaCost1 then
	    	CastQ(target)
			if not common.CanUseSpell(0) then
			    game.cast("self", 1)
			end
			if not common.CanUseSpell(1) then
				for i, enemy in ipairs (enemies) do
			    	if enemy and not enemy.isDead and common.IsValidTarget(enemy) and common.HasBuff(enemy, "ZileanQEnemyBomb") then
				    	CastQ(target)
				    	QWQCast = true
					end
				end
			end
		else
			CastQ(target)
		end
	elseif common.CanUseSpell(0) and common.CanUseSpell(1) then
		QWQCast = false
	end
end



--[[function AutoIgnite()
	local target = ts.target
	if target and not target.isDead and menu.KillSteal.Ignite2:get() and common.IsValidTarget(target) and common.GetDistance(player, target) <= 600 and target.health <= igniteDmg[player.level] then
		game.cast("obj", igniteSlot, target)
	end
end--]]

function KillSteal()
	for i, enemy in ipairs(enemies) do
 		if not enemy.isDead and enemy.isVisible and enemy.isTargetable and menu.auto.ks.uks:get() then
  			if menu.auto.ks.ksq:get() and enemy.health < qDmg(enemy) then
	  			CastQ(enemy)
	  		end
   			if menu.auto.ks.ksqwq:get() and enemy.health < 2 * qDmg(enemy) then 
   				QWQ(enemy) 
   			end
  		end
 	end
end

function AutoIgnite()
	for i, enemy in ipairs(enemies) do
        if common.IsValidTarget(enemy) and common.GetDistance(player, enemy) <= 600 then
            if menu.auto.Ignite:get() and common.CanUseSpell(igniteSlot) and igniteDmg[player.level] > enemy.health then game.cast("obj", igniteSlot, enemy) end
        end
    end
end


--[[function AutoZhonya()
	if menu.auto.zhonya:get() and common.GetPercentHealth(player) <= menu.combo.itemhp:get() then
		for i = 6, 11 do
	    	local item = player:spellslot(i).name
	    	if item and item == "ZhonyasHourglass" then
	    		game.cast("self", i)
	    		player:spellslot(1).cooldown > 0
	    	end
        end
	end
end--]]

function Run()
	if menu.keys.run:get() then
		game.issue("move", vec3(game.mousePos))
		if common.CanUseSpell(2) then
			game.cast("obj", 2, player)
		end
		if common.CanUseSpell(1) and not common.CanUseSpell(2) then
			game.cast("self", 1)
		end
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

function CountAllysInRange(range)
	local range, count = range*range, 0 
	for i = 0, objmanager.allies_n - 1 do
		if player.pos:distSqr(objmanager.allies[i].pos) < range then 
	 		count = count + 1 
	 	end 
	end 
	return count 
end

--[Spyk Credits]--
function qDmg(target)
	local qDamage = CalcMagicDmg(target, 0.9 * QlvlDmg[player:spellslot(0).level] + player.flatMagicDamageMod * .5 + player.flatPhysicalDamageMod * .5, player)
	return qDamage
end


function CalcMagicDmg(target, amount, from)
	local from = from or player or objmanager.player;
	local target = target or orb.combat.target;
	local amount = amount or 0;
	local targetMR = target.magicResist * math.ceil(from.percentMagicPenetration) - from.flatMagicPenetration;
	local dmgMul = 100 / (100 + targetMR);
	if dmgMul < 0 then
		dmgMul = 2 - (100 / (100 - magicResist));
	end
	amount = amount * dmgMul;
	return math.floor(amount)
end
--[End Spyk Credits]--


function OnDraw()
	if menu.draws.q:get() then
		glx.world.circle(player.pos, 900, 1, draw.color.gold, 50)
	end
	if menu.draws.e:get() then
		glx.world.circle(player.pos, 600, 1, draw.color.golden_rod, 50)
	end
end

callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.draw, function() OnDraw() end)

print("Cyrex Ahri v"..version..": Loaded")