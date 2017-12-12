return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "Cyrex Kassadin",
  ["moduleName"] = "kassadin",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Kassadin"
  end
}