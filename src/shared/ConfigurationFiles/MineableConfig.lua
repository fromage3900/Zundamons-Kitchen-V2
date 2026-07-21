-- [[ModuleScript] MineableConfig (ref: RBX6330426701494520A633C16AF5A04948)]]
local mineableConfig = {}

mineableConfig.priceLists= {["Rock"]=10, ["Marble Rock"]=15, ["Gold Ore"]=30, ["Wheat"]=10, ["Apple"]=5, ["Wood Log"]=20, ["Pine Cone"]=5, ["WheatSeed"]=1, ["Apple Pie"]=100, ["Bread"]=60, ["Zunda Flower"]=12, ["Zunda Pea"]=18, ["Zunda Bread"]=140, ["Zunda Mochi"]=160, ["Zunda Mushroom"]=25, ["Zunda Berry"]=20, ["Zunda Root"]=22}

mineableConfig.Mineables={["Rock"]={["Health"]=100,
	                      ["MaxHealth"]=100,
	                      ["Respawn"]=15,
	                      ["loot"]={["Tier1"]={"Rock","Iron Ore"},
		                            ["Tier2"]={"Rock","Rock","Iron Ore","Iron Ore"},
		                            ["Tier3"]={"Rock","Rock","Rock","Iron Ore","Iron Ore","Iron Ore","Iron Ore"}
	                               }
                                  },
	                      ["MarbleRock"]={["Health"]=100,
		                                  ["MaxHealth"]=100,
		                                  ["Respawn"]=15,
		                            ["loot"]={["Tier1"]={"Marble Rock","Marble Rock","Rock"},
			                                  ["Tier2"]={"Marble Rock","Marble Rock","Marble Rock","Marble Rock"},
			                                  ["Tier3"]={"Marble Rock","Marble Rock","Marble Rock","Marble Rock","Gold Ore"}
		                           }
	                              },
	                      ["GoldRock"]={["Health"]=100,
		                                  ["MaxHealth"]=100,
		                                  ["Respawn"]=15,
		                            ["loot"]={["Tier1"]={"Gold Ore","Rock","Rock"},
			                                  ["Tier2"]={"Gold Ore","Gold Ore","Rock"},
			                                  ["Tier3"]={"Gold Ore","Gold Ore","Rock","Marble Rock"}
		                           }
	                              },
	                      ["Wheat"]={["Health"]=50,
		                             ["MaxHealth"]=50,
		                             ["Respawn"]=15,
		                             ["loot"]={["Tier1"]={"Wheat","Wheat","Wheat","Wheat","Wheat","WheatSeed"}
			                       }
	                              },
	                      ["AppleTree"]={["Health"]=100,
		                                ["MaxHealth"]=100,
		                                ["Respawn"]=15,
		                            ["loot"]={["Tier1"]={"Apple","Wood Log"},
			                                  ["Tier2"]={"Apple","Apple","Apple","Apple","Apple","Wood Log","Wood Log","Wood Log"}
			                       }
	                              },
	                      ["PineTree"]={["Health"]=100,
		                                ["MaxHealth"]=100,
		                                ["Respawn"]=15,
		                            ["loot"]={["Tier1"]={"Pine Cone","Wood Log"},
			                                  ["Tier2"]={"Pine Cone","Pine Cone","Wood Log","Wood Log","Wood Log"}
		                           }
	                              },
	                      ["ZundaMushroom"]={["Health"]=50,
		                                ["MaxHealth"]=50,
		                                ["Respawn"]=25,
		                            ["loot"]={["Tier1"]={"Zunda Mushroom","Zunda Mushroom","Zunda Mushroom"}
			                           }
	                              },
	                      ["ZundaBerry"]={["Health"]=40,
		                                ["MaxHealth"]=40,
		                                ["Respawn"]=20,
		                            ["loot"]={["Tier1"]={"Zunda Berry","Zunda Berry","Zunda Berry","Zunda Berry"}
			                           }
	                              },
	                      ["ZundaRoot"]={["Health"]=45,
		                                ["MaxHealth"]=45,
		                                ["Respawn"]=22,
		                            ["loot"]={["Tier1"]={"Zunda Root","Zunda Root","Zunda Root"}
			                           }
	                              },
}

return mineableConfig
