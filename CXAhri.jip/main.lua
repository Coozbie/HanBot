local version = "1.4"

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
local draw = avada_lib.draw

local ts = avada_lib.targetSelector
local orb = module.internal("orb")
local gpred = module.internal("pred")

local qPred = { delay = 0.25, width = 80, speed = 1500, boundingRadiusMod = 1, collision = { hero = false, minion = false } }
local ePred = { delay = 0.25, width = 55, speed = 1550, boundingRadiusMod = 1, collision = { hero = true, minion = true } }

local menu = menu("ahrigod", "Cyrex Ahri")
	ts = ts(menu, 1000, 2)
	menu:header("xd", "Cyrex Ahri")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Where The Magic Happens")
		menu.keys:keybind("StartE", "Start Combo With E", false, "K")
		--menu.keys:keybind("getcd", "Get Player CD", "T", false)
	menu:menu("combo", "Combo Settings")
		menu.combo:header("xd", "Combo Settings")
		menu.combo:header("xd", "Q Settings")
		menu.combo:boolean("q", "Use Q", true)

		menu.combo:header("xd", "W Settings")
		menu.combo:boolean("w", "Use W", true)
		menu.combo:boolean("wc", "Cast Only if Enemy is Charmed?", false)
		menu.combo:slider("wr", "Min. W Range To Cast", 600, 300, 700, 50)

		menu.combo:header("xd", "E Settings")
		menu.combo:boolean("e", "Use E", true)

		menu.combo:header("xd", "R Settings")
		menu.combo:boolean("r", "Use R [Mouse & Beta]", false)

		menu.combo:header("xd", "Item Settings")
			menu.combo:menu("items", "Item Settings")
				menu.combo.items:header("xd", "Zhonya Settings")
				menu.combo.items:boolean("zhonya", "Use Zhonya", true)
				menu.combo.items:slider("itemhp", "Use Zhonyas if HP % <=", 15, 0, 100, 5)

				menu.combo.items:header("xd", "Seraphs Embrace Settings")
				menu.combo.items:boolean("seraph", "Use Seraphs Embrace", true)
				menu.combo.items:slider("seraphx", "Use Seraph if HP % <=", 15, 0, 100, 5)

	menu:menu("harass", "Harass Settings")
		menu.harass:header("xd", "Harass Settings")
		menu.harass:boolean("q", "Use Q", true)
		menu.harass:boolean("w", "Use W", true)
		menu.harass:boolean("e", "Use E", true)
		menu.harass:slider("Mana", "Min. Mana Percent: ", 10, 0, 100, 10)
	menu:menu("draws", "Draw Settings")
		menu.draws:header("xd", "Drawing Options")
		menu.draws:boolean("q", "Draw Q Range", true)
		menu.draws:boolean("w", "Draw W Range", true)
		menu.draws:boolean("e", "Draw E Range", true)
	ts:addToMenu()	
	menu:header("version", "Version: 1.4")
	menu:header("author", "Author: Coozbie")

local function OnTick()
	if orb.combat.is_active() then Combo() end
	if orb.menu.hybrid:get() then Harass() end
end

function Combo()
	local target = ts.target
	if target and common.IsValidTarget(target) then
		if menu.combo.e:get() and player:spellSlot(2).state == 0 and player.path.serverPos:dist(target.path.serverPos) < 950 then
			local seg = gpred.linear.get_prediction(ePred, target)
			if seg and seg.startPos:dist(seg.endPos) < 935 then
				if not gpred.collision.get_prediction(ePred, seg, target) then
					player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
				end
			end
		end
		if menu.keys.StartE:get() and player:spellSlot(2).state == 0 then return end
		if target.pos:dist(player.pos) < menu.combo.wr:get() and menu.combo.w:get() and player:spellSlot(1).state == 0 then
			if menu.combo.wc:get() and Charm == true then
				player:castSpell("self", 1)
			elseif not menu.combo.wc:get() or common.GetPercentHealth(target) < 40 then
				player:castSpell("self", 1)
			end
		end
		if menu.combo.q:get() and player:spellSlot(0).state == 0 and player.path.serverPos:dist(target.path.serverPos) < 870 then
			local seg = gpred.linear.get_prediction(qPred, target)
			if seg and seg.startPos:dist(seg.endPos) < 860 then
				if not gpred.collision.get_prediction(qPred, seg, target) then
					player:castSpell("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
				end
			end
		end
		common.DelayAction(function() CastR() end, 1)
	end
	--[Items]--
	if menu.combo.items.zhonya:get() and common.GetPercentHealth(player) <= menu.combo.items.itemhp:get() and CountEnemyHeroInRange(600) >= 1 then
		for i = 6, 11 do
	    	local item = player:spellSlot(i).name
	    	if item and item == "ZhonyasHourglass" then
	    		player:castSpell("self", i)
	    	end
        end
	end
	if menu.combo.items.seraph:get() and common.GetPercentHealth(player) <=  menu.combo.items.seraphx:get() and CountEnemyHeroInRange(600) >= 1 then
		for i = 6, 11 do
			local item = player:spellSlot(i).name
			if item and item == "ItemSeraphsEmbrace" then
				player:castSpell("self", i)
			end
		end
	end
end

function Harass()
	local target = ts.target
	if target and common.IsValidTarget(target) then
		if player.par / player.maxPar * 100 >= menu.harass.Mana:get() then
			if menu.harass.e:get() and player:spellSlot(2).state == 0 then
				local seg = gpred.linear.get_prediction(ePred, target)
				if seg and seg.startPos:dist(seg.endPos) < 950 then
					if not gpred.collision.get_prediction(ePred, seg, target) then
						player:castSpell("pos", 2, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
					end
				end
			end
			if target.pos:dist(player.pos) <= 500 then
				if menu.harass.w:get() and player:spellSlot(1).state == 0 then
					player:castSpell("self", 1)
				end
			end
			if menu.harass.q:get() and player:spellSlot(0).state == 0 then
				local seg = gpred.linear.get_prediction(qPred, target)
				if seg and seg.startPos:dist(seg.endPos) < 860 then
					if not gpred.collision.get_prediction(qPred, seg, target) then
						player:castSpell("pos", 0, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))
					end
				end
			end
		end
	end
end

function CastR()
	if menu.combo.r:get() and player:spellSlot(3).state == 0 then
		player:castSpell("pos", 3, game.mousePos)
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


--[[function CD()
	if menu.keys.getcd:get() then
		print(player:spellSlot(4).name)
	end
end
]]--

function OnUpdateBuff(buff, causer)
	if buff and buff.valid and buff.owner and buff.owner.type == player.type and buff.owner.team == TEAM_ENEMY then
		if buff.type == 22 or buff.name == "AhriSeduce" then
			Charm = true
		end
	end
end

function OnRemoveBuff(buff, causer)
	if buff and buff.valid and buff.owner and buff.owner.type == player.type and buff.owner.team == TEAM_ENEMY then
		if buff.type == 22 or buff.name == "AhriSeduce" then
			Charm = false
		end
	end
end 



function OnDraw()
	if menu.draws.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, 880, 2, graphics.argb(255, 7, 141, 237), 70)
	end
	if menu.draws.w:get() and player:spellSlot(1).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, menu.combo.wr:get(), 2, graphics.argb(255, 255, 112, 255), 70)
	end
	if menu.draws.e:get() and player:spellSlot(2).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, 975, 2, graphics.argb(255, 200, 0, 255), 70)
	end
end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.removebuff, OnRemoveBuff)
cb.add(cb.updatebuff, OnUpdateBuff)

print("Cyrex Ahri v"..version..": Loaded")