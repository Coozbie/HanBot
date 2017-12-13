local version = "1.01"

local alib = module.load("avada_lib")
local orb = module.internal("orb/main")
local common = alib.common
local draw = alib.draw
local allies, enemies = common.GetAllyHeroes(), common.GetEnemyHeroes()
local lantern = nil

local smiteDmg = { 390, 410, 430, 450, 480, 510, 540, 570, 600, 640, 680, 720, 760, 800, 850, 900, 950, 1000 }
local smiteDmgKs = {28, 36, 44, 52, 60, 68, 76, 84, 92, 100, 108, 116, 124, 132, 140, 148, 156, 164}
local smiteSlot = nil
if player:spellslot(4).name == "SummonerSmite" or player:spellslot(4).name == "S5_SummonerSmitePlayerGanker" or player:spellslot(4).name == "S5_SummonerSmiteDuel" then
	smiteSlot = 4
elseif player:spellslot(5).name == "SummonerSmite" or player:spellslot(5).name == "S5_SummonerSmitePlayerGanker" or player:spellslot(5).name == "S5_SummonerSmiteDuel" then
	smiteSlot = 5
end

local healSlot = nil
if player:spellslot(4).name == "SummonerHeal" then
	healSlot = 4
elseif player:spellslot(5).name == "SummonerHeal" then
	healSlot = 5
end

local barrierSlot = nil
if player:spellslot(4).name == "SummonerBarrier" then
	barrierSlot = 4
elseif player:spellslot(5).name == "SummonerBarrier" then
	barrierSlot = 5
end

local cleanseSlot = nil
if player:spellslot(4).name == "SummonerBoost" then
	cleanseSlot = 4
elseif player:spellslot(5).name == "SummonerBoost" then
	cleanseSlot = 5
end

local igniteDmg = { 70, 90, 110, 130, 150, 170, 190, 210, 230, 250, 270, 290, 310, 330, 350, 370, 390, 410 } --"50 + (20 * myHero.level)"
local igniteSlot = nil
if player:spellslot(4).name == "SummonerDot" then
	igniteSlot = 4
elseif player:spellslot(5).name == "SummonerDot" then
	igniteSlot = 5
end


local menu = menuconfig("activator", "Activator")
	menu:header("xd", "A C T I V A T O R")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Items While Holding Space")
		menu.keys:keybind("combo", "Combo 4 Items", "Space", false)

	menu:header("xd", "Pot Settings")
	menu:menu("pot", "Auto Pot Settings")
		menu.pot:header("xd", "Use of Pots")
		menu.pot:boolean("usep", "Use Health Pot", true)
		menu.pot:boolean("enemy", "Use if no enemies", true)
		menu.pot:slider("usepx", "Use if HP % <=", 10, 0, 100, 10)

	menu:header("420", "Item Settings")
	menu:menu("itemo", "Offensive Items")
		menu.itemo:header("xd", "AP and AD Settings")
		menu.itemo:menu("apo", "AP Items")
			menu.itemo.apo:header("xd", "Hextech Settings")
			menu.itemo.apo:boolean("hex", "Use Hextech Gunblade", true)
			menu.itemo.apo:slider("hexathp", "Use if enemy health is below %", 60, 10, 100, 10)

			menu.itemo.apo:header("xd", "Bligewater Settings")
			menu.itemo.apo:boolean("bwc", "Use Bligewater Cutlass", true)
			menu.itemo.apo:slider("bwcathp", "Use if enemy health is below %", 60, 10, 100, 10)

		menu.itemo:menu("ado", "AD Items")
			menu.itemo.ado:header("xd", "Bligewater Settings")
			menu.itemo.ado:boolean("bwc", "Use Bligewater Cutlass", true)
			menu.itemo.ado:slider("bwcathp", "Use if enemy health is below %", 60, 10, 100, 10)

			menu.itemo.ado:header("xd", "Ruined King Settings")
			menu.itemo.ado:boolean("botrk", "Use Ruined King", true)
			menu.itemo.ado:slider("botrkathp", "Use if enemy health is below %", 60, 10, 100, 10)

			menu.itemo.ado:header("xd", "Tiamat Settings")
			menu.itemo.ado:boolean("tiamat", "Use Tiamat/Hydra", true)
			menu.itemo.ado:boolean("titanic", "Use Titanic", true)

	menu:menu("itemd", "Defensive Items")
		menu.itemd:header("xd", "Shields Settings")
		menu.itemd:menu("def", "Shield Items")
			menu.itemd.def:header("xd", "Zhonya Settings")
			menu.itemd.def:boolean("zhonya", "Use Zhonya", true)
			menu.itemd.def:slider("itemhp", "Use Zhonyas if HP % <=", 10, 0, 100, 10)

			menu.itemd.def:header("xd", "Seraphs Embrace Settings")
			menu.itemd.def:boolean("seraph", "Use Seraphs Embrace", true)
			menu.itemd.def:slider("seraphx", "Use Seraph if HP % <=", 10, 0, 100, 10)

			menu.itemd.def:header("xd", "Face Of Mountain Settings")
			menu.itemd.def:boolean("bomb", "Use Face Of Mountain", true)
			menu.itemd.def:slider("bombx", "Use FoM if HP % <=", 10, 0, 100, 10)

			menu.itemd.def:header("xd", "Thresh Lantern Settings")
			menu.itemd.def:boolean("tl", "Grab Lantern ?", true)

			menu.itemd.def:header("xd", "Gargoyle Stoneplate Settings")
			menu.itemd.def:boolean("gs", "Use Stoneplate", true)
			menu.itemd.def:slider("gsx", "Use Stoneplate if HP % <=", 10, 0, 100, 10)
			menu.itemd.def:slider("gsx2", "Enemys Near: ", 1, 0, 5, 1)

		menu.itemd:header("xd", "Debuff Enemy")
		menu.itemd:menu("apd", "Debuff Enemy Settings")
			menu.itemd.apd:header("xd", "Randuin Settings")
			menu.itemd.apd:boolean("rand", "Use Randuin Omen", true)
			menu.itemd.apd:slider("randx", "Enemys Near: ", 1, 0, 5, 1)

			menu.itemd.apd:header("xd", "Frost Queen Settings")
			menu.itemd.apd:boolean("frost", "Use Frost Queen", true)
			menu.itemd.apd:slider("frostx", "Enemys Near: ", 1, 0, 5, 1)

		menu.itemd:header("xd", "Buff Self & Ally")
		menu.itemd:menu("buf", "Items for Buff")
				menu.itemd.buf:header("xd", "Face Of Mountain Settings")
				menu.itemd.buf:boolean("fom", "Use for Ally", false)
				menu.itemd.buf:slider("fomx", "Use if Ally HP % <=", 10, 0, 100, 10)

				menu.itemd.buf:header("xd", "Talisman of Ascencion Settings")
				menu.itemd.buf:boolean("toa", "Use Talisman", true)
				menu.itemd.buf:slider("toax", "Allies Near: ", 1, 0, 5, 1)

				menu.itemd.buf:header("xd", "Locket of Iron Solari Settings")
				menu.itemd.buf:boolean("lois", "Use Locket", true)
				menu.itemd.buf:slider("loisx", "Allies Near: ", 1, 0, 5, 1)

				menu.itemd.buf:header("xd", "Righteous Glory Settings")
				menu.itemd.buf:boolean("rg", "Use Righteous Glory", true)
				menu.itemd.buf:slider("rgx", "Allies Near: ", 1, 0, 5, 1)

		menu.itemd:header("qss", "Cleanse Settings")
		menu.itemd:menu("qss", "Buff Config")
			menu.itemd.qss:boolean("stun", "Use for Stun", true)
			menu.itemd.qss:boolean("exh", "Use for Exhaust", true)
			menu.itemd.qss:boolean("silence", "Use for Silence", true)
			menu.itemd.qss:boolean("charm", "Use for Charm", true)
			menu.itemd.qss:boolean("taunt", "Use for Taunt", true)
			menu.itemd.qss:boolean("root", "Use for Root", true)
			menu.itemd.qss:boolean("sup", "Use for Suppression", true)
			menu.itemd.qss:boolean("blind", "Use for Blind", true)
			menu.itemd.qss:boolean("fear", "Use for Fear", true)
			menu.itemd.qss:boolean("knock", "Use for KnockUp", true)
		menu.itemd:menu("qssop", "QSS/Cleanse Settings")
			menu.itemd.qssop:header("xd", "QSS/Cleanse Options")
			menu.itemd.qssop:boolean("useqss", "Use QuicksilverSash", true)
			if cleanseSlot then
			menu.itemd.qssop:boolean("usecle", "Use Cleanse", true)
			end
			--[[
			menu.itemd.qssop:header("xd", "Ignite Check")
			menu.itemd.qssop:boolean("smart", "Use QSS/Cleanse for Ignite", true)
			menu.itemd.qssop:slider("smartx", "Use if HP % <=", 10, 0, 100, 10)]]--


	menu:header("xd", "Summoner Spell Settings")
	menu:menu("sum", "Summoner Spells")
		if smiteSlot then
		menu.sum:header("xd", "Smite")
		menu.sum:menu("smite", "Smite Settings")
			menu.sum.smite:header("xd", "Epic Settings")
			menu.sum.smite:boolean("baron", "Use for Baron", true)
			menu.sum.smite:boolean("dragon", "Use for Dragon", true)
			menu.sum.smite:boolean("herald", "Use for Herald", true)

			menu.sum.smite:header("xd", "Buffs Settings")
			menu.sum.smite:boolean("b", "Use for Blue", true)
			menu.sum.smite:boolean("r", "Use for Red", true)

			menu.sum.smite:header("xd", "Killsteal Settings")
			menu.sum.smite:boolean("ks", "Use for Killsteal", true)
		end

		if healSlot then
		menu.sum:header("xd", "Heal")
		menu.sum:menu("hs", "Heal Settings")
			menu.sum.hs:boolean("uh", "Auto Heal", true)
			menu.sum.hs:slider("uhx", "HP % to Cast", 10, 1, 100, 1)
		end

		if igniteSlot then
		menu.sum:header("xd", "Ignite")
		menu.sum:menu("ign", "Ignite Settings")
			menu.sum.ign:boolean("Ignite", "Auto Ignite", true)
		end

		if barrierSlot then
		menu.sum:header("xd", "Barrier")
		menu.sum:menu("bs", "Barrier Settings")
			menu.sum.bs:boolean("ub", "Auto Barrier", true)
			menu.sum.bs:slider("ubx", "HP % to Cast", 10, 1, 100, 1)
		end

		if smiteSlot or igniteSlot then
		menu:menu("draws", "Summoners Draw Settings")
		menu.draws:boolean("smite", "Draw Smite Range", true)
		menu.draws:boolean("ignite", "Draw Ignite Range", true)
	    end

	    menu:header("xd", "Version: 1.01")
	    menu:header("xd", "Author: Coozbie")
	    menu:header("xd", "Credits: Avada Team")

function AutoSmite()
	if not player.isDead and smiteSlot and common.CanUseSpell(smiteSlot) then
		for i = 0, objmanager.maxObjects - 1 do
			local obj = objmanager.get(i)
			if obj and obj.type == enum.type.minion and common.IsValidTarget(obj) and obj.team == enum.team.neutral and draw.GetDistance(obj, player) < 560 and obj.health <= smiteDmg[player.level] then
				print(obj.charName)
				if obj.charName == "SRU_Baron" then
					if menu.sum.smite.baron:get() then
						game.cast("obj", smiteSlot, obj)
					end
				elseif obj.charName == "SRU_Dragon_Water" or obj.charName == "SRU_Dragon_Fire" or obj.charName == "SRU_Dragon_Earth" or obj.charName == "SRU_Dragon_Air" or obj.charName == "SRU_Dragon_Elder" then
					if menu.sum.smite.dragon:get() then
						game.cast("obj", smiteSlot, obj)
					end
				elseif obj.charName == "SRU_RiftHerald" then
					if menu.sum.smite.herald:get() then
						game.cast("obj", smiteSlot, obj)
					end
				elseif obj.charName == "SRU_Blue" then
					if menu.sum.smite.b:get() then
						game.cast("obj", smiteSlot, obj)
					end
				elseif obj.charName == "SRU_Red" then
					if menu.sum.smite.r:get() then
						game.cast("obj", smiteSlot, obj)
					end
				end
			end
		end
		for i, enemy in ipairs(enemies) do
        	if common.IsValidTarget(enemy) and player.path.serverPos:dist(enemy.path.serverPos) <= 560 then
            	if menu.sum.smite.ks:get() and smiteDmgKs[player.level] > enemy.health then game.cast("obj", smiteSlot, enemy) end
        	end
    	end
	end
end

function AutoIgnite()
	for i, enemy in ipairs(enemies) do
        if common.IsValidTarget(enemy) and player.path.serverPos:dist(enemy.path.serverPos) <= 600 then
            if menu.sum.ign.Ignite:get() and igniteSlot and common.CanUseSpell(igniteSlot) and igniteDmg[player.level] > enemy.health then game.cast("obj", igniteSlot, enemy) end
        end
    end
end

function AutoHeal()
	if not player.isDead and healSlot and menu.sum.hs.uh:get() and common.CanUseSpell(healSlot) and player.health <= menu.sum.hs.uhx:get() / 100 * player.maxHealth and CountEnemyHeroInRange(900) >= 1 then
		game.cast("self", healSlot)
	end
end

function AutoBarrier()
	if not player.isDead and menu.sum.bs.ub:get() and barrierSlot and common.CanUseSpell(barrierSlot) and player.health <= menu.sum.bs.ubx:get() / 100 * player.maxHealth and CountEnemyHeroInRange(900) >= 1 then
		game.cast("self", barrierSlot)
	end
end

function OnUpdateBuff(buff, source)
	if buff and buff.valid and buff.owner and buff.owner == player and source and source.type == enum.type.hero and source.team == enum.team.enemy then
		if buff.name == "SummonerExhaust" and menu.itemd.qss.exh:get() then
			AntiCC("Exhaust")
		end
		if buff.type == 5 or buff.name == "LuxLightBinding" and menu.itemd.qss.stun:get() then
			AntiCC("Stun")
		end
		if buff.type == 7 and menu.itemd.qss.silence:get() then
			AntiCC("Silence")
		end
		if buff.type == 8 and menu.itemd.qss.taunt:get() then
			AntiCC("Taunt")
		end
		if buff.type == 11 and menu.itemd.qss.root:get() then
			AntiCC("Root")
		end
		if buff.type == 22 and menu.itemd.qss.charm:get() then
			AntiCC("Charm")
		end
		if buff.type == 24 and menu.itemd.qss.sup:get() then
			AntiCC("Suppression")
		end
		if buff.type == 25 and menu.itemd.qss.blind:get() then
			AntiCC("Blind")
		end
		if buff.type == 28 and menu.itemd.qss.fear:get() then
			AntiCC("Fear")
		end
		if buff.type == 29 and menu.itemd.qss.knock:get() then
			AntiCC("KnockUp")
		end
		if buff.name == "RegenerationPotion" or buff.name == "ItemMiniRegenPotion" or buff.name == "ItemCrystalFlask" or buff.name == "ItemDarkCrystalFlask" then
			potionOn = true
		end
	end
end

function OnRemoveBuff(buff, source)
	if buff and buff.valid and buff.owner and buff.owner == player and source and source.type == enum.type.hero and source.team == enum.team.enemy then
		if buff.name == "RegenerationPotion" or buff.name == "ItemMiniRegenPotion" or buff.name == "ItemCrystalFlask" or buff.name == "ItemDarkCrystalFlask" then
			potionOn = false
		end
	end
end

function OnCreateObj(obj)
	if obj and obj ~= nil and obj.valid and obj.team == enum.team.ally then
		if obj.name == "ThreshLantern" then
			lantern = obj
		end
	end
end

function OnDeleteObj(obj)
	if obj and obj ~= nil and obj.valid and obj.team == enum.team.ally then
		if obj.name == "ThreshLantern" then
			lantern = nil
		end
	end
end

function AntiCC(typeName)
	if menu.itemd.qssop.useqss:get() then
		local useCleanse = true
		for i = 6, 11 do
		local item = player:spellslot(i).name
			if item == "QuicksilverSash" or item == "ItemMercurial" then
				common.DelayAction(function() game.cast("self", i) end, 0.3)
				useCleanse = false
				break
			end
		end
	end
	if cleanseSlot then
		if menu.itemd.qssop.usecle:get() and useCleanse and typeName ~= "Suppression" then
			game.cast("self", cleanseSlot)
		end
	end
end

function Combo()
	if menu.keys.combo:get() then
		if orb.combat.target and not orb.combat.target.isDead then
			DebuffEn()
			CastItems()
		end		
	end
	Shields()
	ShieldAlly()
end

function DebuffEn()
	if menu.itemd.apd.rand:get() and CountEnemyHeroInRange(500) >= menu.itemd.apd.randx:get() and common.IsValidTarget(orb.combat.target) then
		for i = 6, 11 do
  		local item = player:spellslot(i).name
  			if item and (item == 'RanduinsOmen') then
    			game.cast("self", i)
  			end
		end
    end
    if menu.itemd.apd.frost:get() and CountEnemyHeroInRange(1000) >= menu.itemd.apd.frostx:get() and player.path.serverPos:dist(orb.combat.target.path.serverPos) < 700 then
		for i = 6, 11 do
			local item = player:spellslot(i).name
			if item and item == "ItemGlacialSpikeCast" or item == "ItemWraithCollar" then
				game.cast("self", i)
			end
		end
	end
end

function Shields()
	if not player.isDead then
		if menu.itemd.def.zhonya:get() and CountEnemyHeroInRange(700) >= 1 and common.GetPercentHealth(player) <= menu.itemd.def.itemhp:get() then
			for i = 6, 11 do
		    	local item = player:spellslot(i).name
		    	if item and item == "ZhonyasHourglass" or item == "Item2420" then
		    		game.cast("self", i)
		    	end
	        end
	    end
	    if menu.itemd.def.seraph:get() and common.GetPercentHealth(player) <=  menu.itemd.def.seraphx:get() and CountEnemyHeroInRange(600) >= 1 then
			for i = 6, 11 do
				local item = player:spellslot(i).name
				if item and item == "ItemSeraphsEmbrace" then
					game.cast("self", i)
				end
			end
		end
		if menu.itemd.def.bomb:get() and common.GetPercentHealth(player) <=  menu.itemd.def.bombx:get() and CountEnemyHeroInRange(600) >= 1 then
			for i = 6, 11 do
				local item = player:spellslot(i).name
				if item and item == "HealthBomb" then
					game.cast("obj", i, player)
				end
			end
		end
		if menu.itemd.def.gs:get() and common.GetPercentHealth(player) <=  menu.itemd.def.gsx:get() and CountEnemyHeroInRange(600) >= menu.itemd.def.gsx2:get() then
			for i = 6, 11 do
				local item = player:spellslot(i).name
				if item and item == "Item3193Active" then
					game.cast("self", i)
				end
			end
		end
		if menu.itemd.buf.toa:get() and CountAllysInRange(500) >= menu.itemd.buf.toax:get() then
			for i = 6, 11 do
				local item = player:spellslot(i).name
				if item and item == "ShurelyasCrest" then
					game.cast("self", i)
				end
			end
		end
		if menu.itemd.buf.lois:get() and CountAllysInRange(500) >= menu.itemd.buf.loisx:get() and CountEnemyHeroInRange(1000) >= 1 then
			for i = 6, 11 do
				local item = player:spellslot(i).name
				if item and item == "IronStylus" then
					game.cast("self", i)
				end
			end
		end
		if menu.itemd.buf.rg:get() and CountAllysInRange(500) >= menu.itemd.buf.rgx:get() and CountEnemyHeroInRange(1000) >= 1 then
			for i = 6, 11 do
				local item = player:spellslot(i).name
				if item and item == "ItemRighteousGlory" then
					game.cast("self", i)
				end
			end
		end
	end
end



function CastItems()
    if common.IsValidTarget(orb.combat.target) then
		if menu.itemo.ado.bwc:get() then
			if common.GetPercentHealth(orb.combat.target) <= menu.itemo.ado.bwcathp:get() and player.path.serverPos:dist(orb.combat.target.path.serverPos) <= 550 then
				for i = 6, 11 do
	  				local item = player:spellslot(i).name
	  				if item and (item == 'BilgewaterCutlass') then
	    				game.cast("obj", i, orb.combat.target)
	  				end
				end
			end
		end
		if menu.itemo.ado.botrk:get() then
			if common.GetPercentHealth(orb.combat.target) <= menu.itemo.ado.botrkathp:get() and player.path.serverPos:dist(orb.combat.target.path.serverPos) <= 550 then
				for i = 6, 11 do
	  				local item = player:spellslot(i).name
	  				if item and (item == 'ItemSwordOfFeastAndFamine') then
	    				game.cast("obj", i, orb.combat.target)
	  				end
				end
			end
		end
		if menu.itemo.ado.tiamat:get() then
			if player.path.serverPos:dist(orb.combat.target.path.serverPos) <= 300 and not orb.core.can_attack() then
				for i = 6, 11 do
	  				local item = player:spellslot(i).name
	  				if item and (item == 'ItemTiamatCleave') then
	    				game.cast("self", i)
	  				end
				end
			end
		end
		if menu.itemo.ado.titanic:get() then
			if player.path.serverPos:dist(orb.combat.target.path.serverPos) <= player.attackRange + player.boundingRadius and not orb.core.can_attack() then
				for i = 6, 11 do
	  				local item = player:spellslot(i).name
	  				if item and (item == "ItemTitanicHydraCleave" ) then
	    				game.cast("self", i)
	  				end
				end
			end
		end
		if menu.itemo.apo.bwc:get() then
			if common.GetPercentHealth(orb.combat.target) <= menu.itemo.apo.bwcathp:get() and player.path.serverPos:dist(orb.combat.target.path.serverPos) <= 550 then
				for i = 6, 11 do
	  				local item = player:spellslot(i).name
	  				if item and (item == 'BilgewaterCutlass') then
	    				game.cast("obj", i, orb.combat.target)
	  				end
				end
			end
		end
		if menu.itemo.apo.hex:get() then
			if common.GetPercentHealth(orb.combat.target) <= menu.itemo.apo.hexathp:get() and player.path.serverPos:dist(orb.combat.target.path.serverPos) <= 700 then
				for i = 6, 11 do
	  				local item = player:spellslot(i).name
	  				if item and (item == 'HextechGunblade') then
	    				game.cast("obj", i, orb.combat.target)
	  				end
				end
			end
		end
	end
end

function ShieldAlly()
	if menu.itemd.buf.fom:get() and CountEnemyHeroInRange(600) >= 1 and CountAllysInRange(500) >= 1 then
		for i = 1, #allies do
			local hero = allies[i]
			if hero and not hero.dead and common.GetDistance(player, hero) < 500 and common.GetPercentHealth(hero) <=  menu.itemd.buf.fomx:get() then
				for i = 6, 11 do
					local item = player:spellslot(i).name
					if item and item == "HealthBomb" then
						game.cast("obj", i, hero)
					end
				end
			end
		end
	end
end


local lastPotion = 0
function UsePotion()
	if os.clock() - lastPotion < 11 then return end
	if not menu.pot.enemy:get() then
		if CountEnemyHeroInRange(750) == 0 then return end
	end
	for i = 6, 11 do
		local item = player:spellslot(i).name
		if item and item == "RegenerationPotion" or item == "ItemMiniRegenPotion" or item == "ItemCrystalFlask" or item == "ItemDarkCrystalFlask" then
			game.cast("self", i)
			lastPotion = os.clock()
		end
	end
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

function CountEnemyHeroInRange(range)
	local range, count = range*range, 0 
	for i = 0, objmanager.enemies_n - 1 do
		if player.pos:distSqr(objmanager.enemies[i].pos) < range then 
	 		count = count + 1 
	 	end 
	end 
	return count 
end

function OnTick()
	if smiteSlot then AutoSmite() end
	if menu.keys.combo then Combo() end
	if healSlot then AutoHeal() end
	if barrierSlot then AutoBarrier() end
	if igniteSlot then AutoIgnite() end
	if menu.pot.usep and not potionOn and not common.InFountain() and common.GetPercentHealth(player) <=  menu.pot.usepx:get() then UsePotion() end
end

function OnDraw()
	if smiteSlot and common.CanUseSpell(smiteSlot) and menu.draws.smite:get() then
		glx.world.circle(player.pos, 560, 1, draw.color.gold, 50)
	end
	if igniteSlot and common.CanUseSpell(igniteSlot) and menu.draws.ignite:get() then
		glx.world.circle(player.pos, 600, 1, draw.color.red, 50)
	end
end


callback.add(enum.callback.draw, function() OnDraw() end)
callback.add(enum.callback.tick, function() OnTick() end)
callback.add(enum.callback.recv.removebuff, OnRemoveBuff)
callback.add(enum.callback.recv.updatebuff, OnUpdateBuff)

print("Activator "..version..": Loaded")

--ItemWillBoltSpellBase (GLPHextech800)
--Item3193Active (ArmaduraPetera)
--HealthBomb(FaceOfMountain)
--ItemMorellosBane("mikael")
--ShurelyasCrest(pelota amarilla + speed)
--ItemRedemption(Redencion)
--ItemSoFBoltSpellBase(Porto)
--ItemVeilChannel
return {}