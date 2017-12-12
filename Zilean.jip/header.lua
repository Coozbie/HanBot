return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "Cyrex Zilean",
  ["moduleName"] = "zilean",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Zilean"
  end
}