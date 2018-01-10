return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "Cyrex Jinx",
  ["moduleName"] = "jinx",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Jinx"
  end
}