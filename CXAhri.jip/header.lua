return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "Cyrex Ahri",
  ["moduleName"] = "ahrigod",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Ahri"
  end
}