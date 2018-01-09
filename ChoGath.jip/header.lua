return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "Cyrex ChoGath",
  ["moduleName"] = "cho",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Chogath"
  end
}