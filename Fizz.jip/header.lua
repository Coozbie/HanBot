return {
  ["scriptType"] = "Champion",
  ["scriptName"] = "Cyrex Fizz",
  ["moduleName"] = "fizz",
  ["entryPoint"] = "main.lua",
  ["loadToCoreMenu"] = function()
    return player.charName == "Fizz"
  end
}