return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "Cyrex Kayn",
  ["moduleName"] = "kayn",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Kayn"
  end
}