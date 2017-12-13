return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "Cyrex Lux",
  ["moduleName"] = "lux",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Lux"
  end
}