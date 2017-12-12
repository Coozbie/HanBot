return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "Cyrex Kayle",
  ["moduleName"] = "kayle",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Kayle"
  end
}