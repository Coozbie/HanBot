return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "Khantum Phyzix",
  ["moduleName"] = "k6",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Khazix"
  end
}