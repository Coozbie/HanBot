local avada_lib = module.lib('avada_lib')
if not avada_lib then
	console.set_color(12)
	print("You need to have Avada Lib in your community_libs folder to run Activator!")
	print("You can find it here:")
	console.set_color(11)
	print("https://gitlab.soontm.net/get_clear_zip.php?fn=avada_lib")
	console.set_color(15)
	return
elseif avada_lib.version < 1.07 then
	console.set_color(12)
	print("Your need to have Avada Lib updated to run to run Activator!")
	print("You can find it here:")
	console.set_color(11)
	print("https://gitlab.soontm.net/get_clear_zip.php?fn=avada_lib")
	console.set_color(15)
	return
end

local version = "1.05"

local common = avada_lib.common
local orb = module.internal("orb")
local ts = module.internal("TS")
local gpred = module.internal("pred")

--local lantern = nil
local potionActive = false

local summonerSpell = {
  smite = {
    slot = player:spellSlot(4).name:lower():find("smite") and 4 or 5,
    minionDamage = { 390, 410, 430, 450, 480, 510, 540, 570, 600, 640, 680, 720, 760, 800, 850, 900, 950, 1000 },
    heroDamage = { 28, 36, 44, 52, 60, 68, 76, 84, 92, 100, 108, 116, 124, 132, 140, 148, 156, 166 }
  },

  heal = {
    slot = player:spellSlot(4).name:find("SummonerHeal") and 4 or 5
  },

  barrier = {
    slot = player:spellSlot(4).name:find("SummonerBarrier") and 4 or 5
  },

  cleanse = {
    slot = player:spellSlot(4).name:find("SummonerBoost") and 4 or 5
  },

  ignite = {
    slot = player:spellSlot(4).name:find("SummonerDot") and 4 or 5,
    damage = { 80, 105, 130, 155, 180, 205, 230, 255, 280, 305, 330, 355, 380, 405, 430, 455, 480, 505 }
  }
}

local menu = menu("cbActivator", "Activator")
	menu:header("xd", "A C T I V A T O R")
	menu:menu("keys", "Key Settings")
		menu.keys:header("xd", "Items While Holding Space")
		menu.keys:keybind("combo", "Combo Key", "Space", nil)

	menu:header("xd", "Pot Settings")
	menu:menu("pot", "Auto Pot Settings")
		menu.pot:header("xd", "Use of Pots")
		menu.pot:boolean("usep", "Use Health Pot", true)
		menu.pot:boolean("enemy", "Use if no enemies", true)
		menu.pot:slider("usepx", "Use if HP% <=", 60, 0, 100, 10)
		menu.pot:header("xd", "Misc Items")
		menu.pot:boolean("useg", "Use [Kleptomancy] Sack of Gold", true)

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
			menu.itemo.ado:slider("botrkatownhp", "Use if my health is below %", 60, 10, 100, 10)

			menu.itemo.ado:header("xd", "Tiamat Settings")
			menu.itemo.ado:boolean("tiamat", "Use Tiamat/Hydra", true)
			menu.itemo.ado:boolean("titanic", "Use Titanic", true)

	menu:menu("itemd", "Defensive Items")
		menu.itemd:header("xd", "Shields Settings")
		menu.itemd:menu("def", "Shield Items")
			menu.itemd.def:header("xd", "Zhonya Settings")
			menu.itemd.def:boolean("zhonya", "Use Zhonya", true)
			menu.itemd.def:slider("itemhp", "Use Zhonyas if HP % <=", 20, 0, 100, 10)

			menu.itemd.def:header("xd", "Seraphs Embrace Settings")
			menu.itemd.def:boolean("seraph", "Use Seraphs Embrace", true)
			menu.itemd.def:slider("seraphx", "Use Seraph if HP % <=", 20, 0, 100, 10)

			--menu.itemd.def:header("xd", "Face Of Mountain Settings")
			--menu.itemd.def:boolean("bomb", "Use Face Of Mountain", true)
			--menu.itemd.def:slider("bombx", "Use FoM if HP % <=", 20, 0, 100, 10)

			--menu.itemd.def:header("xd", "Thresh Lantern Settings")
			--menu.itemd.def:boolean("tl", "Grab Lantern ?", true)

			menu.itemd.def:header("xd", "Gargoyle Stoneplate Settings")
			menu.itemd.def:boolean("gs", "Use Stoneplate", true)
			menu.itemd.def:slider("gsx", "Use Stoneplate if HP % <=", 10, 0, 100, 10)
			menu.itemd.def:slider("gsx2", "Enemys Near: ", 1, 0, 5, 1)

    --menu.itemd:menu("wb", "Ward Bush Trick")
      --menu.itemd.wb:boolean("wbt", "Ward Bush On Lose Vision", true)

		menu.itemd:header("xd", "Debuff Enemy")
		menu.itemd:menu("apd", "Debuff Enemy Settings")
			menu.itemd.apd:header("xd", "Randuin Settings")
			menu.itemd.apd:boolean("rand", "Use Randuin Omen", true)
			menu.itemd.apd:slider("randx", "Enemys Near: ", 1, 0, 5, 1)
			menu.itemd.apd:slider("randhp", "Use Randuin if HP % <=", 60, 10, 100, 10)

			menu.itemd.apd:header("xd", "Twin Shadow Settings")
			menu.itemd.apd:boolean("frost", "Use Twin Shadow", true)
			menu.itemd.apd:slider("frostx", "Enemys Near: ", 1, 0, 5, 1)

		menu.itemd:header("xd", "Buff Self & Ally")
		menu.itemd:menu("buf", "Items for Buff")
      --menu.itemd.buf:header("xd", "Face Of Mountain Settings")
      --menu.itemd.buf:boolean("fom", "Use for Ally", false)
      --menu.itemd.buf:slider("fomx", "Use if Ally HP % <=", 10, 0, 100, 10)

      menu.itemd.buf:header("xd", "Talisman of Ascencion Settings")
      menu.itemd.buf:boolean("toa", "Use Talisman", true)
      menu.itemd.buf:slider("toax", "Allies Near: ", 1, 0, 5, 1)

      menu.itemd.buf:header("xd", "Locket of Iron Solari Settings")
      menu.itemd.buf:boolean("lois", "Use Locket", true)
      menu.itemd.buf:slider("loisx", "Allies Near: ", 1, 0, 5, 1)
      menu.itemd.buf:slider("loishp", "Use Solari if HP % <=", 60, 10, 100, 10)

      menu.itemd.buf:header("xd", "Righteous Glory Settings")
      menu.itemd.buf:boolean("rg", "Use Righteous Glory", true)
      menu.itemd.buf:slider("rgx", "Allies Near: ", 1, 0, 5, 1)
      
      menu.itemd.buf:header("xd", "Redemption Settings")
      menu.itemd.buf:boolean("Ron", "Use Redemption?", true)
      menu.itemd.buf:slider("RSL", "Use Redemption HP% ", 45, 0, 100, 1)
				
		menu.itemd:header("xd", "Mikael's Crucible")
		menu.itemd:menu("mikaBF", "Mikeals Buff Settings")
			menu.itemd.mikaBF:boolean("silcenM", "Silence", false)
			menu.itemd.mikaBF:boolean("supM", "Suppression", true)
			menu.itemd.mikaBF:boolean("rootM", "Root", true)
			menu.itemd.mikaBF:boolean("tauntM", "Taunt", true)
			menu.itemd.mikaBF:boolean("sleepM", "Sleep", true)
			menu.itemd.mikaBF:boolean("stunM", "Stun", true)
			menu.itemd.mikaBF:boolean("blindM", "Blind", false)
			menu.itemd.mikaBF:boolean("fearM", "Fear", true)
			menu.itemd.mikaBF:boolean("charmM", "Charm", true)
			menu.itemd.mikaBF:boolean("knockM", "Knockback/Knockup", false)
        menu.itemd.mikaBF.knockM:set("tooltip", "Recommended: Off")
	
		menu.itemd:menu("mikz", "Mikeals Ally Selection")
      menu.itemd.mikz:boolean("AMK", "Auto Mikael's", true)
      for i = 0, objManager.allies_n - 1 do
        local ally = objManager.allies[i]
        if ally and ally.ptr ~= player.ptr then
          menu.itemd.mikz:boolean(ally.charName, "Mikeals Ally? ".. ally.charName, true)
          menu.itemd.mikz[ally.charName]:set('value', true)
        end
      end			
			
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
      menu.itemd.qssop:boolean("usecle", "Use Cleanse", true)
			--[[
			menu.itemd.qssop:header("xd", "Ignite Check")
			menu.itemd.qssop:boolean("smart", "Use QSS/Cleanse for Ignite", true)
			menu.itemd.qssop:slider("smartx", "Use if HP % <=", 10, 0, 100, 10)
      ]]--

	menu:header("xd", "Summoner Spell Settings")
	menu:menu("sum", "Summoner Spells")
    menu.sum:header("xds", "Smite")
    menu.sum:menu("smite", "Smite Settings")
      menu.sum.smite:keybind("usm", "Use Smite ?", false, "I")
      menu.sum.smite:header("xd", "Epic Settings")
      menu.sum.smite:boolean("baron", "Use for Baron", true)
      menu.sum.smite:boolean("dragon", "Use for Dragon", true)
      menu.sum.smite:boolean("herald", "Use for Herald", true)

      menu.sum.smite:header("xd", "Buffs Settings")
      menu.sum.smite:boolean("b", "Use for Blue", true)
      menu.sum.smite:boolean("r", "Use for Red", true)

      menu.sum.smite:header("xd", "Enemy Settings")
      menu.sum.smite:boolean("ks", "Use for Killsteal", true)
      menu.sum.smite:boolean("hp", "Use Red Smite for enemy", false)
      menu.sum.smite:slider("hpx", "Use if enemy HP % <=", 60, 10, 100, 10)

    menu.sum:header("xdh", "Heal")
    menu.sum:menu("hs", "Heal Settings")
      menu.sum.hs:header("xd", "Self Heal Settings")	
      menu.sum.hs:boolean("uh", "Auto Heal", true)
      menu.sum.hs:slider("uhx", "HP % to Cast", 10, 1, 100, 1)

      menu.sum.hs:header("xd", "Ally Heal Settings")
      menu.sum.hs:boolean("uha", "Auto Heal Ally", true)
      menu.sum.hs:slider("uhax", "HP % to Cast", 15, 1, 100, 1)

    menu.sum:header("xdi", "Ignite")
    menu.sum:menu("ign", "Ignite Settings")
      menu.sum.ign:boolean("Ignite", "Auto Ignite", true)

    menu.sum:header("xdb", "Barrier")
    menu.sum:menu("bs", "Barrier Settings")
      menu.sum.bs:boolean("ub", "Auto Barrier", true)
      menu.sum.bs:slider("ubx", "HP % to Cast", 15, 1, 100, 1)

  menu:menu("draws", "Summoners Draw Settings")
    menu.draws:boolean("dss", "Draw Smite State", true)
    menu.draws:boolean("smite", "Draw Smite Range", true)
    menu.draws:color("ds", 'Drawing Color', 255, 255, 255, 255)

    menu.draws:boolean("ignite", "Draw Ignite Range", true)
    menu.draws:color("di", 'Drawing Color', 255, 255, 0, 0)

  menu:header("xd", "Version: ".. version)
  menu:header("xd", "Author: Coozbie")
  
local function FuckSpellbookUsers()
  if player:spellSlot(4).name:lower():find("smite") then
    summonerSpell.smite.slot = 4
  elseif player:spellSlot(5).name:lower():find("smite") then
    summonerSpell.smite.slot = 5
  else
    summonerSpell.smite.slot = nil
  end

  if player:spellSlot(4).name:find("SummonerHeal") then
    summonerSpell.heal.slot = 4
  elseif player:spellSlot(5).name:find("SummonerHeal") then
    summonerSpell.heal.slot = 5
  else
    summonerSpell.heal.slot = nil
  end

  if player:spellSlot(4).name:find("SummonerBarrier") then
    summonerSpell.barrier.slot = 4
  elseif player:spellSlot(5).name:find("SummonerBarrier") then
    summonerSpell.barrier.slot = 5
  else
    summonerSpell.barrier.slot = nil
  end

  if player:spellSlot(4).name:find("SummonerBoost") then
    summonerSpell.cleanse.slot = 4
  elseif player:spellSlot(5).name:find("SummonerBoost") then
    summonerSpell.cleanse.slot = 5
  else
    summonerSpell.cleanse.slot = nil
  end

  if player:spellSlot(4).name:find("SummonerDot") then
    summonerSpell.ignite.slot = 4
  elseif player:spellSlot(5).name:find("SummonerDot") then
    summonerSpell.ignite.slot = 5
  else
    summonerSpell.ignite.slot = nil
  end

  if not summonerSpell.cleanse.slot then
    menu.itemd.qssop.usecle:set("visible", false)
  else
    menu.itemd.qssop.usecle:set("visible", true)
  end
  
  if not summonerSpell.smite.slot then
    menu.sum.xds:set("visible", false)
    menu.sum.smite:set("visible", false)
    menu.draws.dss:set("visible", false)
    menu.draws.smite:set("visible", false)
    menu.draws.ds:set("visible", false)
  else
    menu.sum.xds:set("visible", true)
    menu.sum.smite:set("visible", true)
    menu.draws.dss:set("visible", true)
    menu.draws.smite:set("visible", true)
    menu.draws.ds:set("visible", true)
  end
  
  if not summonerSpell.heal.slot then
    menu.sum.xdh:set("visible", false)
    menu.sum.hs:set("visible", false)
  else
    menu.sum.xdh:set("visible", true)
    menu.sum.hs:set("visible", true)
  end
  
  if not summonerSpell.ignite.slot then
    menu.sum.xdi:set("visible", false)
    menu.sum.ign:set("visible", false)
    menu.draws.ignite:set("visible", false)
    menu.draws.di:set("visible", false)
  else
    menu.sum.xdi:set("visible", true)
    menu.sum.ign:set("visible", true)
    menu.draws.ignite:set("visible", true)
    menu.draws.di:set("visible", true)
  end
  
  if not summonerSpell.barrier.slot then
    menu.sum.xdb:set("visible", false)
    menu.sum.bs:set("visible", false)
  else
    menu.sum.xdb:set("visible", true)
    menu.sum.bs:set("visible", true)
  end
end

local dragonNames = {
  ["SRU_Dragon_Water"] = true,
  ["SRU_Dragon_Fire"] = true,
  ["SRU_Dragon_Earth"] = true,
  ["SRU_Dragon_Air"] = true,
  ["SRU_Dragon_Elder"] = true,
}
local function AutoSmite()
  local range = 500 + player.boundingRadius
  if menu.sum.smite.usm:get() then
    for i = 0, objManager.minions.size[TEAM_NEUTRAL] - 1 do
      local minion = objManager.minions[TEAM_NEUTRAL][i]
      if minion and not minion.isDead and minion.isVisible then
        local dist = player.path.serverPos:dist(minion.path.serverPos)
        if dist < (range + minion.boundingRadius) and (summonerSpell.smite.minionDamage[player.levelRef > 18 and 18 or player.levelRef]) >= minion.health then
          if menu.sum.smite.baron:get() and minion.charName == "SRU_Baron" then
            player:castSpell("obj", summonerSpell.smite.slot, minion)
            break
          end
          if menu.sum.smite.dragon:get() and dragonNames[minion.charName] then
            player:castSpell("obj", summonerSpell.smite.slot, minion)
            break
          end
          if menu.sum.smite.herald:get() and minion.charName == "SRU_RiftHerald" then
            player:castSpell("obj", summonerSpell.smite.slot, minion)
            break
          end
          if menu.sum.smite.b:get() and minion.charName == "SRU_Blue" then
            player:castSpell("obj", summonerSpell.smite.slot, minion)
            break
          end
          if menu.sum.smite.r:get() and minion.charName == "SRU_Red" then
            player:castSpell("obj", summonerSpell.smite.slot, minion)
            break
          end
        end
      end
    end
  end
  if menu.sum.smite.ks:get() or menu.sum.smite.hp:get() then
    local slot = player:spellSlot(summonerSpell.smite.slot)
    for i = 0, objManager.enemies_n - 1 do
      local enemy = objManager.enemies[i]
      if enemy and common.IsValidTarget(enemy) then
        local dist = player.path.serverPos:dist(enemy.path.serverPos)
        if dist < (range + enemy.boundingRadius) then
          if menu.sum.smite.ks:get() and slot.name == "S5_SummonerSmitePlayerGanker" and (summonerSpell.smite.heroDamage[player.levelRef > 18 and 18 or player.levelRef]) > enemy.health then
            player:castSpell("obj", summonerSpell.smite.slot, enemy)
            break
          end
          if menu.sum.smite.hp:get() and slot.name == "S5_SummonerSmiteDuel" and common.GetPercentHealth(enemy) <= menu.sum.smite.hpx:get() then
            player:castSpell("obj", summonerSpell.smite.slot, enemy)
            break
          end
        end
      end
    end
  end
end

local function AutoIgnite()
  for i = 0, objManager.enemies_n - 1 do
    local enemy = objManager.enemies[i]
    if enemy and common.IsValidTarget(enemy) and not enemy.buff["sionpassivezombie"] and common.GetPercentHealth(enemy) < 15 then
      local dist = player.path.serverPos:distSqr(enemy.path.serverPos)
      local damage = (summonerSpell.ignite.damage[player.levelRef > 18 and 18 or player.levelRef])
      if dist < (600 * 600) and dist >= (500 * 500) and damage > enemy.health then
        player:castSpell("obj", summonerSpell.ignite.slot, enemy)
        break
      end
      if dist <= (500 * 500) and dist >= (200 * 200) and (damage + 40) > enemy.health then
        player:castSpell("obj", summonerSpell.ignite.slot, enemy)
        break
      end
    end
  end
end

local function AutoHeal()
  if menu.sum.hs.uh:get() then
    if #common.GetEnemyHeroesInRange(800) > 0 and common.GetPercentHealth() < menu.sum.hs.uhx:get() then
      player:castSpell("self", summonerSpell.heal.slot)
    end
  end
  if menu.sum.hs.uha:get() then
    for i = 0, objManager.allies_n - 1 do
      local ally = objManager.allies[i]
      if ally and not ally.isDead and not ally.buff[17] then
        local dist = player.path.serverPos:dist(ally.path.serverPos)
        if dist < 850 and #common.GetEnemyHeroesInRange(800, ally) > 0 and common.GetPercentHealth(ally) < menu.sum.hs.uhax:get() then
          player:castSpell("self", summonerSpell.heal.slot)
          break
        end
      end
    end
  end
end

local function AutoBarrier()
	if common.GetPercentHealth() < menu.sum.bs.ubx:get() and #common.GetEnemyHeroesInRange(800) > 0 then
		player:castSpell("self", summonerSpell.barrier.slot)
	end
end

local function AntiCC(typeName)
	if menu.itemd.qssop.useqss:get() then
		local useCleanse = true
		for i = 6, 11 do
      local slot = player:spellSlot(i)
			if slot.isNotEmpty and (slot.name == "QuicksilverSash" or slot.name == "ItemMercurial") and slot.state == 0 then
				common.DelayAction(function() player:castSpell("self", i) end, 0.3)
				useCleanse = false
				break
			end
		end
	end
	if summonerSpell.cleanse.slot then
		if menu.itemd.qssop.usecle:get() and typeName ~= "Suppresion" then
			common.DelayAction(function() player:castSpell("self", summonerSpell.cleanse.slot) end, 0.2)
		end
	end
end

local function DebuffEnemy(target)
  if target then
    if menu.itemd.apd.rand:get() and #common.GetEnemyHeroesInRange(500) >= menu.itemd.apd.randx:get() and common.GetPercentHealth() <= menu.itemd.apd.randhp:get() then
      for i = 6, 11 do
        local slot = player:spellSlot(i)
        if slot.isNotEmpty and (slot.name == 'RanduinsOmen') and slot.state == 0 then
          player:castSpell("self", i)
          break
        end
      end
    end
    if menu.itemd.apd.frost:get() and #common.GetEnemyHeroesInRange(1200) >= menu.itemd.apd.frostx:get() then
      local dist = player.path.serverPos:distSqr(target.path.serverPos)
      if dist < (1200 * 1200) and dist > (400 * 400) then
        for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and (slot.name == "ItemGlacialSpikeCast" or slot.name == "ItemWraithCollar") and slot.state == 0 then
            player:castSpell("self", i)
            break
          end
        end
      end
    end
  end
end

local function Shields()
  if menu.itemd.def.zhonya:get() and #common.GetEnemyHeroesInRange(700) >= 1 and common.GetPercentHealth() <= menu.itemd.def.itemhp:get() then
    for i = 6, 11 do
      local slot = player:spellSlot(i)
      if slot.isNotEmpty and (slot.name == "ZhonyasHourglass" or slot.name == "Item2420") and slot.state == 0 then
        player:castSpell("self", i)
        break
      end
    end
  end
  if menu.itemd.def.seraph:get() and common.GetPercentHealth() <=  menu.itemd.def.seraphx:get() and #common.GetEnemyHeroesInRange(600) >= 1 then
    for i = 6, 11 do
      local slot = player:spellSlot(i)
      if slot.isNotEmpty and slot.name == "ItemSeraphsEmbrace" and slot.state == 0 then
        player:castSpell("self", i)
        break
      end
    end
  end
  --[[
  if menu.itemd.def.bomb:get() and common.GetPercentHealth() <=  menu.itemd.def.bombx:get() and #common.GetEnemyHeroesInRange(600) >= 1 then
    for i = 6, 11 do
      local slot = player:spellSlot(i)
      if slot.isNotEmpty and slot.name == "HealthBomb" and slot.state == 0 then
        player:castSpell("obj", i, player)
        break
      end
    end
  end
  ]]
  if menu.itemd.def.gs:get() and common.GetPercentHealth() <= menu.itemd.def.gsx:get() and #common.GetEnemyHeroesInRange(600) >= menu.itemd.def.gsx2:get() then
    for i = 6, 11 do
      local slot = player:spellSlot(i)
      if slot.isNotEmpty and slot.name == "Item3193Active" and slot.state == 0 then
        player:castSpell("self", i)
        break
      end
    end
  end
  if menu.itemd.buf.toa:get() and #common.GetAllyHeroesInRange(500) >= menu.itemd.buf.toax:get() and #common.GetEnemyHeroesInRange(800) > 1 then
    for i = 6, 11 do
      local slot = player:spellSlot(i)
      if slot.isNotEmpty and slot.name == "ShurelyasCrest" and slot.state == 0 then
        player:castSpell("self", i)
        break
      end
    end
  end
  if menu.itemd.buf.lois:get() and common.GetPercentHealth() <= menu.itemd.buf.loishp:get() then
    if #common.GetAllyHeroesInRange(500) >= menu.itemd.buf.loisx:get() and #common.GetEnemyHeroesInRange(1000) >= 1 then
      for i = 6, 11 do
        local slot = player:spellSlot(i)
        if slot.isNotEmpty and slot.name == "IronStylus" and slot.state == 0 then
          player:castSpell("self", i)
          break
        end
      end
    end
  end
  if menu.itemd.buf.rg:get() and #common.GetAllyHeroesInRange(500) >= menu.itemd.buf.rgx:get() and #common.GetEnemyHeroesInRange(1000) >= 1 then
    for i = 6, 11 do
      local slot = player:spellSlot(i)
      if slot.isNotEmpty and slot.name == "ItemRighteousGlory" and slot.state == 0 then
        player:castSpell("self", i)
        break
      end
    end
  end
end

local function CastItems(target)
  if target then
    local dist = player.path.serverPos:dist(target.path.serverPos)
		if menu.itemo.ado.bwc:get() then
			if common.GetPercentHealth(target) <= menu.itemo.ado.bwcathp:get() and dist < 550 then
				for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and slot.name == 'BilgewaterCutlass' and slot == 0 then
            player:castSpell("obj", i, target)
            break
          end
				end
			end
		end
		if menu.itemo.ado.botrk:get() then
			if dist < 550 and (common.GetPercentHealth(target) <= menu.itemo.ado.botrkathp:get() or common.GetPercentHealth() <= menu.itemo.ado.botrkatownhp:get()) then
				for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and slot.name == 'ItemSwordOfFeastAndFamine' and slot.state == 0 then
            player:castSpell("obj", i, target)
            break
          end
				end
			end
		end
		if menu.itemo.ado.tiamat:get() then
			if dist <= 300 and not orb.core.can_attack() then
				for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and slot.name == 'ItemTiamatCleave' and slot.state == 0 then
            player:castSpell("self", i)
            --orb.core.reset()
            break
          end
				end
			end
		end
		if menu.itemo.ado.titanic:get() then
			if dist <= common.GetAARange(target) and not orb.core.can_attack() then
				for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and slot.name == "ItemTitanicHydraCleave"  and slot.state == 0 then
            player:castSpell("self", i)
            --orb.core.reset()
            break
          end
				end
			end
		end
		if menu.itemo.apo.bwc:get() then
			if common.GetPercentHealth(target) <= menu.itemo.apo.bwcathp:get() and dist < 550 then
				for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and slot.name == 'BilgewaterCutlass' and slot.state == 0 then
            player:castSpell("obj", i, target)
            break
          end
				end
			end
		end
		if menu.itemo.apo.hex:get() then
			if common.GetPercentHealth(target) <= menu.itemo.apo.hexathp:get() and dist < 700 then
				for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and slot.name == 'HextechGunblade' and slot.state == 0 then
            player:castSpell("obj", i, target)
            break
          end
				end
			end
		end
	end
end

--[[
local function ShieldAlly()
  local alliesInRange = common.GetAllyHeroesInRange(500)
	if #common.GetEnemyHeroesInRange(800) >= 1 and #alliesInRange >= 1 then
		for i = 1, #alliesInRange do
			local ally = alliesInRange[i]
			if ally and common.GetPercentHealth(ally) <= menu.itemd.buf.fomx:get() then
				for i = 6, 11 do
					local item = player:spellSlot(i)
					if slot.isNotEmpty and slot.name == "HealthBomb" and slot.state == 0 then
						player:castSpell("obj", i, hero)
            break
					end
				end
			end
		end
	end
end
]]

local redPred = { --range = 5500
  delay = 2.5,
  radius = 550,
  speed = math.huge,
  boundingRadiusMod = 0
}
local function Redemption()
  local RedFriend = common.GetAllyHeroesInRange(5500)
	for i = 1, #RedFriend do
		local RF = RedFriend[i]
		if RF and common.GetPercentHealth(RF) < menu.itemd.buf.RSL:get() and #common.GetEnemyHeroesInRange(700, RF) >= 1 then
			for i = 6, 11 do
				local slot = player:spellSlot(i)
				if slot.isNotEmpty and (slot.name == "Redemption" or slot.name == "ItemRedemption") and slot.state == 0 then
					local seg = gpred.circular.get_prediction(redPred, RF)
					if seg and seg.startPos:distSqr(seg.endPos) < (5500 * 5500) then
						player:castSpell("pos", i, vec3(seg.endPos.x, game.mousePos.y, seg.endPos.y))		
					end
				end
			end
		end
	end
end

local function Mikaels() --do print/opt
  local mikafriend = common.GetAllyHeroesInRange(700)
  for i = 1, #mikafriend do
    local ally = mikafriend[i]
    if ally and (menu.itemd.mikz[ally.charName] and menu.itemd.mikz[ally.charName]:get()) and #common.GetEnemyHeroesInRange(1000, ally) >= 1 then
      if (menu.itemd.mikaBF.stunM:get() and ally.buff[5]) or 
        (menu.itemd.mikaBF.rootM:get() and ally.buff[11]) or 
        (menu.itemd.mikaBF.silcenM:get() and ally.buff[7]) or 
        (menu.itemd.mikaBF.tauntM:get() and ally.buff[8]) or 
        (menu.itemd.mikaBF.supM:get() and ally.buff[24]) or 
        (menu.itemd.mikaBF.sleepM:get() and ally.buff[18]) or 
        (menu.itemd.mikaBF.charmM:get() and ally.buff[22]) or 
        (menu.itemd.mikaBF.fearM:get() and ally.buff[28]) or 
        (menu.itemd.mikaBF.knockM:get() and ally.buff[29]) then
        for i = 6, 11 do
          local slot = player:spellSlot(i)
          if slot.isNotEmpty and (slot.name == "MorellosBane" or slot.name == "ItemMorellosBane") and slot.state == 0 then
            common.DelayAction(function() player:castSpell("obj", i, ally) end, 0.2)
          end
        end
      end
    end
	end	
end

local potionNames = {
  ["RegenerationPotion"] = true,
  ["ItemMiniRegenPotion"] = true,
  ["ItemCrystalFlask"] = true,
  ["ItemDarkCrystalFlask"] = true,
  ["Item2010"] = true,
  ["LootedRegenerationPotion"] = true,
  ["ItemCrystalFlaskJungle"] = true,
  ["LootedPotionOfGiantStrength"] = true,
}
local lastPotion = 0
local function UsePotion()
	if ((os.clock() - lastPotion) < 8) or (not menu.pot.enemy:get() and #common.GetEnemyHeroesInRange(750) == 0) then
    return
  end
	for i = 6, 11 do
		local slot = player:spellSlot(i)
		if slot.isNotEmpty and potionNames[slot.name] and slot.state == 0 then
			player:castSpell("self", i)
			lastPotion = os.clock()
		end
	end
end

local function OnTick()
  FuckSpellbookUsers()
	if summonerSpell.smite.slot and (menu.sum.smite.usm:get() or menu.sum.smite.ks:get() or menu.sum.smite.hp:get()) and player:spellSlot(summonerSpell.smite.slot).state == 0 then
    AutoSmite()
  end
  local target = ts.get_result(function(res, obj, dist)
    if dist < 1000 then
      res.obj = obj
      return true
    end
  end, ts.filter_set[7])
  if target.obj then
    if menu.keys.combo:get() then
      DebuffEnemy(target.obj)
      CastItems(target.obj)
      Shields()
      --[[
      if menu.itemd.buf.fom:get() then
        ShieldAlly()
      end
      ]]
    end
    if summonerSpell.heal.slot and (menu.sum.hs.uh:get() or menu.sum.hs.uha:get()) and player:spellSlot(summonerSpell.heal.slot).state == 0 then
      AutoHeal()
    end
    if summonerSpell.barrier.slot and menu.sum.bs.ub:get() and player:spellSlot(summonerSpell.barrier.slot).state == 0 then
      AutoBarrier()
    end
  end
	if summonerSpell.ignite.slot and menu.sum.ign.Ignite:get() and player:spellSlot(summonerSpell.ignite.slot).state == 0 then
    AutoIgnite()
  end
	if menu.pot.usep:get() and not potionActive and not common.InFountain() and common.GetPercentHealth() <= menu.pot.usepx:get() then
    UsePotion()
  end
  --[[
	if menu.itemd.def.tl:get() and lantern ~= nil then
    local distance = player.path.serverPos:distSqr(lantern.pos)
    if distance < (250 * 250) then
      player:castSpell("obj", 62, lantern)
    end
  end
  ]]
	if menu.pot.useg:get() then
    for i = 6, 11 do
      local slot = player:spellSlot(i)
      if slot.isNotEmpty and slot.name == "ItemSackOfGold" and slot.state == 0 then
        player:castSpell("self", i)
        break
      end
    end
  end
	Shields()
	if menu.itemd.buf.Ron:get() then
    Redemption()
  end
	if menu.itemd.mikz.AMK:get() then
    Mikaels()
  end
end

local function OnUpdateBuff(buff, source)
	if buff.owner.ptr == player.ptr then
    if source.type == TYPE_HERO and source.team == TEAM_ENEMY then
      if menu.itemd.qss.exh:get() and buff.name == "SummonerExhaust" then
        AntiCC("Exhaust")
      end
      if menu.itemd.qss.stun:get() and (buff.type == 5 or buff.name == "LuxLightBinding") then
        AntiCC("Stun")
      end
      if menu.itemd.qss.silence:get() and buff.type == 7 then
        AntiCC("Silence")
      end
      if menu.itemd.qss.taunt:get() and buff.type == 8 then
        AntiCC("Taunt")
      end
      if menu.itemd.qss.root:get() and buff.type == 11 then
        AntiCC("Root")
      end
      if menu.itemd.qss.charm:get() and buff.type == 22 then
        AntiCC("Charm")
      end
      if menu.itemd.qss.sup:get() and buff.type == 24 then
        AntiCC("Suppression")
      end
      if menu.itemd.qss.blind:get() and buff.type == 25 then
        AntiCC("Blind")
      end
      if menu.itemd.qss.fear:get() and buff.type == 28 then
        AntiCC("Fear")
      end
      if menu.itemd.qss.knock:get() and buff.type == 29 then
        AntiCC("KnockUp")
      end
    end
    if potionNames[buff.name] then
      potionActive = true
    end
  end
end

local function OnRemoveBuff(buff)
	if buff.owner.ptr == player.ptr and potionNames[buff.name] then
    potionActive = false
	end
end

--[[
local function OnLoseVision(obj)

end

local function OnCreateObj(obj)
  if not lantern and (obj.name == "ThreshLantern" or obj.name:find("Lantern")) and (obj.owner and obj.owner.team == TEAM_ALLY) then
    lantern = nil --lantern = obj
  end
end
 
local function OnDeleteObj(obj)
  if (obj.name == "ThreshLantern" or obj.name:find("Lantern")) and (lantern and obj.ptr == lantern.ptr) then
    lantern = nil
  end
end
]]

local function OnDraw()
  if player.isOnScreen then
    if summonerSpell.smite.slot and player:spellSlot(summonerSpell.smite.slot).state == 0 and menu.draws.smite:get() then
      graphics.draw_circle(player.pos, (500 + player.boundingRadius), 1, menu.draws.ds:get(), 50)
    end
    if summonerSpell.ignite.slot and player:spellSlot(summonerSpell.ignite.slot).state == 0 and menu.draws.ignite:get() then
      graphics.draw_circle(player.pos, 600, 1, menu.draws.di:get(), 50)
    end
  end
	if summonerSpell.smite.slot and player:spellSlot(summonerSpell.smite.slot).state == 0 and menu.draws.dss:get() then
		local pos = graphics.world_to_screen(vec3(player.x, player.y, player.z))
		if menu.sum.smite.usm:get() then
			graphics.draw_text_2D("Auto Smite: On", 20, pos.x, pos.y, graphics.argb(255, 51, 255, 51))
		else
			graphics.draw_text_2D("Auto Smite: Off", 20, pos.x, pos.y, graphics.argb(255, 255, 30, 30))
		end
	end
end

orb.combat.register_f_pre_tick(OnTick)
cb.add(cb.updatebuff, OnUpdateBuff)
cb.add(cb.removebuff, OnRemoveBuff)
--cb.add(cb.losevision, OnLoseVision)
--cb.add(cb.createobj, OnCreateObj)
--cb.add(cb.deleteobj, OnDeleteObj)
cb.add(cb.draw, OnDraw)

print("Activator ".. version ..": Loaded")
print(player:spellSlot(6).name)

--ItemWillBoltSpellBase (GLPHextech800)
--Item3193Active (ArmaduraPetera)
--HealthBomb(FaceOfMountain)
--ItemMorellosBane("mikael")
--ShurelyasCrest(pelota amarilla + speed)
--ItemRedemption(Redencion)
--ItemSoFBoltSpellBase(Porto)
--ItemVeilChannel
--3907Cast
return {}