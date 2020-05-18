/* Autosplitter for Metal Gear Solid: Integral (PC) */

state("mgsi") {
  bool      _STATS:         0x000000;
  ushort    Alerts:         0x38E87C;
  ushort    Kills:          0x38E87E;
  ushort    RationsUsed:    0x38E88C;
  ushort    Continues:      0x38E88E;
  ushort    Saves:          0x38E890;
  
  bool      _GAME_PROGRESS: 0x000000;
  uint      GameTime:       0x595344;
  sbyte     RoomCode:       0x28CE34;
  ushort    Progress:       0x38D7CA;
  
  bool      _BOSS_HEALTH:   0x000000;
  short     OcelotHp:       0x594124, 0x830;
  short     NinjaHp:        0x2BBC7C, 0x6D4;
  short     MantisHp:       0x3236C6;
  short     MantisMaxHp:    0x283A58;
  short     Wolf1Hp:        0x5059E0;
  short     HindHp:         0x4E6E14;
  short     Wolf2Hp:        0x502220;
  short     RavenHp:        0x4E9A20;
  short     RavenMaxHp:     0x4E97C8;
  short     RexHp:          0x4F071C;
  short     RexMaxHp:       0x4F0724;
  short     LiquidHp:       0x50B978;
  short     EscapeHp:       0x000000;
  short     EscapeMaxHp:    0x000000;
  
  bool      _OTHER:         0x000000;
  sbyte     Difficulty:     0x38E7E2;
  ushort    Health:         0x000000;
  ushort    O2Time:         0x595348;
  short     ChaffTime:      0x391A28;
  bool      InMenu:         0x31D180;
  bool      VsRex:          0x388630;
  byte20    WeaponData:     0x38E802;
  byte20    ItemData:       0x38E82A;
  ushort    DockTimer:      0x4F56AC;
}

isLoading {
  return true;
}

gameTime {
  return TimeSpan.FromMilliseconds((current.GameTime) * 1000 / 60);
}

reset {
  // Don't reset from the credits
  if ( (current.InMenu) && (!old.InMenu) && (current.Progress != 294) ) {
    vars.D.InitVars();
    return true;
  }
  return false;
}

start {
  if (
    ( (settings["o_startonload"]) && (!current.InMenu) && (old.InMenu) ) ||
    ( (current.Progress == 1) && (current.Progress != old.Progress) )
  ) {
    vars.D.InitVars();
    return true;
  }
  return false;
} 

startup {
  vars._INFORMATION = "";
  vars.Info = "";
  vars.CurrentRoom = "";
  vars.Difficulty = "";
  vars._OTHER = "";
  vars.DebugMessage = "";
  
  vars.D = new ExpandoObject();
  dynamic D = vars.D;
  D.Except = new Dictionary< string, Func<bool> >();
  D.Watch = new Dictionary< string, Func<bool> >();
  D.Initialised = false;
  
  D.Difficulties = new Dictionary<sbyte, string> {
    { -1, "Very Easy" },
    { 0, "Easy" },
    { 1, "Normal" },
    { 2, "Hard" },
    { 3, "Extreme" }
  };
  D.SplitTimes = new Dictionary<string, uint> {};
  Action InitVars = delegate() {
    var Keys = new List<string>(D.SplitTimes.Keys);
    foreach ( string Key in Keys ) D.SplitTimes[Key] = 0;
  };
  D.InitVars = InitVars;
  
  D.Rooms = new Dictionary<sbyte, string> {
    { 0, "Dock" },
    { 1, "Heliport" },
    { 2, "Tank Hangar" },
    { 3, "Cell" },
    { 4, "Armory" },
    { 6, "Nuke Building" },
    { 7, "Nuke Building B1" },
    { 8, "Nuke Building B2" },
    { 9, "Cave" },
    { 10, "Communications Tower" },
    { 11, "Walkway" },
    { 12, "Snowfield" },
    { 13, "Blast Furnace" },
    { 14, "Cargo Elevator" },
    { 15, "Warehouse North" },
    { 16, "Underground Base" },
    { 20, "Medi Room" },
    { 33, "Armory South" },
    { 34, "Canyon" },
    { 35, "Lab" },
    { 36, "Commander's Room" },
    { 37, "Underground Passage" },
    { 38, "Torture Room" },
    { 39, "Comms Tower Outside" },
    { 40, "Warehouse" },
    { 41, "Supply Route" },
    { 42, "Supply Route" },
    { 43, "Escape Route" },
    { 44, "Comms Tower Roof" },
    { 45, "Nuke Building B2 Corridor" },
  };
  
  settings.Add("options", true, "Options");
    settings.Add("debug_file", true, "Save debug information to LiveSplit program directory", "options");
    settings.Add("o_startonload", false, "Start splits when loading a save", "options");
    settings.Add("o_nomultisplit", true, "Suppress splitting on repeated actions", "options");
    settings.Add("o_nolocationclash", true, "Suppress location splits that clash with event splits", "options");
    
  settings.Add("asl", true, "ASL Var Viewer integration");
  settings.SetToolTip("asl", "Disabling this may slightly improve performance");
    settings.Add("asl_info", true, "Info (contextual information)", "asl");
      settings.Add("asl_info_vars", true, "Display these values:", "asl_info");
        settings.Add("asl_info_codename", true, "Codename changes", "asl_info_vars");
        settings.Add("asl_info_room", false, "Current location", "asl_info_vars");
        settings.SetToolTip("asl_info_room", "Use CurrentRoom if you only want the location");
        settings.Add("asl_info_chaff", true, "Chaff", "asl_info_vars");
        settings.Add("asl_info_o2", true, "O2", "asl_info_vars");
        settings.Add("asl_info_boss", true, "Boss health", "asl_info_vars");
          settings.Add("asl_info_boss_dmg_flurry", true, "Group hits done within a short time", "asl_info_boss");
          settings.SetToolTip("asl_info_boss_dmg_flurry", "Shows the sum damage for flurries of attacks");
          settings.Add("asl_info_boss_dmg_full", false, "Group all hits done during the battle", "asl_info_boss");
          settings.SetToolTip("asl_info_boss_dmg_full", "A simple damage increment that never resets");
          settings.Add("asl_info_boss_combo", true, "Add a combo counter", "asl_info_boss");
          settings.SetToolTip("asl_info_boss_combo", "This uses the same timing as grouped attacks above");
        settings.Add("asl_info_dock", true, "Dock elevator countdown", "asl_info_vars");
      settings.Add("asl_info_max", true, "Also show the maximum value for raw values", "asl_info");
      settings.Add("asl_info_percent", true, "Show percentages instead of raw values", "asl_info");
    settings.Add("asl_stats", true, "Stats (game stats and current codename)", "asl");
      settings.Add("asl_stats_short", false, "Show single letters for stats instead of full titles", "asl_stats");
      settings.SetToolTip("asl_stats_short", "Enable this if the full stat names make the message too long");

  settings.Add("advanced", true, "Split Points");
    settings.Add("advanced_evt", true, "Boss Completion Splits", "advanced");
      settings.Add("a_p29", true, "Guard Encounter", "advanced_evt");
      settings.Add("a_p39", true, "Revolver Ocelot", "advanced_evt");
      settings.Add("a_p68", true, "M1 Tank", "advanced_evt");
      settings.Add("a_p78", true, "Ninja", "advanced_evt");
      settings.Add("a_p133", true, "Psycho Mantis", "advanced_evt");
      settings.Add("a_p151", true, "Sniper Wolf", "advanced_evt");
      settings.Add("a_p188", true, "Hind D", "advanced_evt");
      settings.Add("a_p198", true, "Sniper Wolf 2", "advanced_evt");
      settings.Add("a_p212", true, "Vulcan Raven", "advanced_evt");
      settings.Add("a_p257", true, "Metal Gear REX", "advanced_evt");
      settings.Add("a_p278", true, "Liquid Snake", "advanced_evt");
      settings.Add("a_p286", true, "Escape", "advanced_evt");
      settings.Add("a_p294", true, "Score", "advanced_evt");
      settings.SetToolTip("a_p294", "On Very Easy, this will split at the final codec instead");
    settings.Add("advanced_minevt", false, "Other Event Splits", "advanced");
    settings.SetToolTip("advanced_minevt", "For more options, see the Area Movement Splits section");
      settings.Add("a_p7", false, "[Dock] Reached elevator", "advanced_minevt");
      settings.Add("a_p19", false, "[Cell] Reached the DARPA Chief", "advanced_minevt");
      settings.Add("a_p27", false, "[Cell] Reached Guard Encounter", "advanced_minevt");
      settings.Add("a_p37", false, "[Armory South] Reached Revolver Ocelot", "advanced_minevt");
      settings.Add("a_p50", false, "[Armory South] BRIBES", "advanced_minevt");
      settings.SetToolTip("a_p50", "Don't enable this. Really.");
      settings.Add("a_p65", false, "[Canyon] Reached M1 Tank", "advanced_minevt");
      settings.Add("a_p76", false, "[Lab] Reached Ninja", "advanced_minevt");
      settings.Add("a_p112", false, "[Nuke Building B1] Cornered Meryl", "advanced_minevt");
      settings.Add("a_p126", false, "[Commander's Room] Reached Mantis (stunned Meryl)", "advanced_minevt");
      settings.Add("a_p153", false, "[Underground Passage] DON'T MOVE!", "advanced_minevt");
      settings.Add("a_p158", false, "[Medi Room] First arrival at Medi Room", "advanced_minevt");
      settings.SetToolTip("a_p158", "Splits after the Cell vent clip in Any%");
      settings.Add("a_p163", false, "[Medi Room] Escaped from prison", "advanced_minevt");
      settings.Add("a_p174", false, "[Comms Tower A] Completed stairs chase", "advanced_minevt");
      settings.Add("a_p178", false, "[Comms Tower A Roof] Attached the rope", "advanced_minevt");
      settings.Add("a_p179", false, "[Comms Tower A Outside] Completed rappel", "advanced_minevt");
      settings.Add("a_p186", false, "[Comms Tower B Roof] Reached Hind D", "advanced_minevt");
      settings.Add("a_p194", false, "[Comms Tower B] Reached elevator ambush", "advanced_minevt");
      settings.Add("a_p195", false, "[Comms Tower B] Completed elevator ambush", "advanced_minevt");
      settings.Add("a_p197", false, "[Snowfield] Reached Sniper Wolf 2", "advanced_minevt");
      settings.Add("a_p206", false, "[Cargo Elevator] Reached elevator ambush", "advanced_minevt");
      settings.Add("a_p207", false, "[Cargo Elevator] Completed elevator ambush", "advanced_minevt");
      settings.Add("a_p211", false, "[Warehouse] Reached Vulcan Raven", "advanced_minevt");
      settings.Add("a_p228", false, "[Underground Base] Reached the control room", "advanced_minevt");
      settings.Add("a_p238", false, "[Underground Base] Retrieved PAL key", "advanced_minevt");
      settings.SetToolTip("a_p238", "Splits when the \"PAL KEY\" overlay disappears");
      settings.Add("a_p239", false, "[Underground Base] Inserted normal PAL key", "advanced_minevt");
      settings.Add("a_p241", false, "[Underground Base] Inserted cold PAL Key", "advanced_minevt");
      settings.Add("a_p247", false, "[Underground Base] Inserted hot PAL Key", "advanced_minevt");
      settings.Add("a_p252", false, "[Underground Base] Reached Metal Gear REX", "advanced_minevt");
      settings.Add("a_p255", false, "[Supply Route] Completed Metal Gear REX (Phase 1)", "advanced_minevt");
      settings.Add("a_p277", false, "[Supply Route] Reached Liquid Snake", "advanced_minevt");
    settings.Add("advanced_wep", false, "Weapon Unlock Splits", "advanced");
    settings.SetToolTip("advanced_wep", "Split the first time you pick up a weapon");
      settings.Add("a_w0", false, "SOCOM", "advanced_wep");
      settings.Add("a_w1", false, "FA-MAS", "advanced_wep");
      settings.Add("a_w2", false, "Grenade", "advanced_wep");
      settings.Add("a_w3", false, "Nikita", "advanced_wep");
      settings.Add("a_w4", false, "Stinger", "advanced_wep");
      settings.Add("a_w5", false, "Claymore", "advanced_wep");
      settings.Add("a_w6", false, "C4", "advanced_wep");
      settings.Add("a_w7", false, "Stun Grenade", "advanced_wep");
      settings.Add("a_w8", false, "Chaff Grenade", "advanced_wep");
      settings.Add("a_w9", false, "PSG-1", "advanced_wep");
    settings.Add("advanced_itm", false, "Item Unlock Splits", "advanced");
    settings.SetToolTip("advanced_itm", "Split the first time you pick up an item");
      // Cigs, Scope, Box A, B, C, NVG, Therm G, Gas Mask, Body Armor, Ketchup, Stealth, Bandana, Camera, Ration, Medicine, Diazepam, PAL Key, Card, Time Bomb, Mine D, MO Disk, Rope, Handk, Suppressor
      settings.Add("a_i2", false, "Cardboard Box A", "advanced_itm");
      settings.Add("a_i3", false, "Cardboard Box B", "advanced_itm");
      settings.Add("a_i4", false, "Cardboard Box C", "advanced_itm");
      settings.Add("a_i5", false, "Night Vision Goggles", "advanced_itm");
      settings.Add("a_i6", false, "Thermal Goggles", "advanced_itm");
      settings.Add("a_i7", false, "Gas Mask", "advanced_itm");
      settings.Add("a_i8", false, "Body Armor", "advanced_itm");
      settings.Add("a_i12", false, "Camera", "advanced_itm");
      settings.Add("a_i13", false, "Ration", "advanced_itm");
      settings.Add("a_i15", false, "Diazepam", "advanced_itm");
      settings.Add("a_i19", false, "Mine Detector", "advanced_itm");
      settings.Add("a_i21", false, "Rope", "advanced_itm");
      settings.Add("a_i23", false, "SOCOM Suppressor", "advanced_itm");
    settings.Add("advanced_loc", false, "Area Movement Splits", "advanced");
    settings.SetToolTip("advanced_loc", "Split when you move from one area to another. Defaults match the speedrun route.z");
      settings.Add("a_r0", true, "Dock", "advanced_loc");
        settings.Add("a_r-1_r1_p9", true, "to Heliport", "a_r0");
      settings.Add("a_r1", true, "Heliport", "advanced_loc");
        settings.Add("a_r1_r2", true, "to Tank Hangar", "a_r1");
          settings.Add("a_r1_r2_p18", true, "on first arrival", "a_r1_r2");
          settings.Add("a_rl_r2_all", false, "always", "a_r1_r2");
        settings.Add("a_r1_r6_all", false, "to Nuke Building", "a_r1");
        settings.Add("a_r1_r12_all", false, "to Snowfield", "a_r1");
      settings.Add("a_r2", true, "Tank Hangar", "advanced_loc");
        settings.Add("a_r2_r1_all", false, "to Heliport", "a_r2");
        settings.Add("a_r2_r3", true, "to Cell", "a_r2");
          settings.Add("a_r2_r3_p18", true, "on first arrival", "a_r2_r3");
          settings.Add("a_r2_r3_all", false, "always", "a_r2_r3");
        settings.Add("a_r2_r4", true, "to Armory", "a_r2");
          settings.Add("a_r2_r4_p150", true, "after Wolf ambushes Meryl", "a_r2_r4");
          settings.Add("a_r2_r4_all", false, "always", "a_r2_r4");
        settings.Add("a_r2_r34", true, "to Canyon", "a_r2");
          settings.Add("a_r2_r34_p64", true, "after Revolver Ocelot", "a_r2_r34");
          settings.Add("a_r2_r34_p150", true, "after collecting PSG-1 (AB)", "a_r2_r34");
          settings.Add("a_r2_r34_p163", true, "after torture", "a_r2_r34");
          settings.Add("a_r2_r34_all", false, "always", "a_r2_r34");
      settings.Add("a_r3", true, "Cell", "advanced_loc"); // TODO differentiate vent
        settings.Add("a_r3_r2", true, "to Tank Hangar", "a_r3");
          settings.Add("a_r3_r2_p163", true, "after torture", "a_r3_r2");
          settings.Add("a_r3_r2_all", false, "always", "a_r3_r2");
        settings.Add("a_r3_r4", true, "to Armory", "a_r3");
          settings.Add("a_r3_r4_p36", true, "after Guard Encounter", "a_r3_r4");
          settings.Add("a_r3_r4_p163", true, "after torture", "a_r3_r4");
          settings.Add("a_r3_r4_all", false, "always", "a_r3_r4");
        settings.Add("a_r3_r20_all", false, "to Medi Room", "a_r3");
      settings.Add("a_r4", true, "Armory", "advanced_loc");
        settings.Add("a_r4_r2", true, "to Tank Hangar", "a_r4");
          settings.Add("a_r4_r2_p52", true, "after Revolver Ocelot", "a_r4_r2");
          settings.Add("a_r4_r2_p150", true, "after collecting PSG-1 (AB)", "a_r4_r2");
          settings.Add("a_r4_r2_all", false, "always", "a_r4_r2");
        settings.Add("a_r4_r3_all", false, "to Cell", "a_r4");
        settings.Add("a_r4_r33", true, "to Armory South", "a_r4");
          settings.Add("a_r4_r33_p36", true, "after Guard Encounter", "a_r4_r33");
          settings.Add("a_r4_r33_all", false, "always", "a_r4_r33");
      settings.Add("a_r33", true, "Armory South", "advanced_loc"); // TODO differentiate vs ocelot
        settings.Add("a_r33_r4", true, "to Armory", "a_r33");
          settings.Add("a_r33_r4_p52", true, "after Revolver Ocelot", "a_r33_r4");
          settings.Add("a_r33_r4_all", false, "always", "a_r33_r4");
      settings.Add("a_r34", true, "Canyon", "advanced_loc"); // TODO diff vs tank
        settings.Add("a_r34_r2", true, "to Tank Hangar", "a_r34");
          settings.Add("a_r34_r2_p150", true, "after Wolf ambushes Meryl", "a_r34_r2");
          settings.Add("a_r34_r2_all", false, "always", "a_r34_r2");
        settings.Add("a_r34_r6", true, "to Nuke Building", "a_r34");
          settings.Add("a_r34_r6_p69", true, "after M1 Tank", "a_r34_r6");
          settings.Add("a_r34_r6_p150", true, "after collecting PSG-1 (AB)", "a_r34_r6");
          settings.Add("a_r34_r6_p163", true, "after torture", "a_r34_r6");
          settings.Add("a_r34_r6_all", false, "always", "a_r34_r6");
      settings.Add("a_r6", true, "Nuke Building", "advanced_loc");
        settings.Add("a_r6_r1", false, "to Heliport", "a_r6");
          settings.Add("a_r6_r1_p150", false, "after Wolf ambushes Meryl", "a_r6_r1");
          settings.Add("a_r6_r1_all", false, "always", "a_r6_r1");
        settings.Add("a_r6_r34", true, "to Canyon", "a_r6");
          settings.Add("a_r6_r34_p150", true, "after Wolf ambushes Meryl", "a_r6_r34");
          settings.Add("a_r6_r34_all", false, "always", "a_r6_r34");
        settings.Add("a_r6_r7", true, "to Nuke Building, B1", "a_r6");
          settings.Add("a_r6_r7_p69", true, "after M1 Tank", "a_r6_r7");
          settings.Add("a_r6_r7_p150", true, "after collecting PSG-1 (AB)", "a_r6_r7");
          settings.Add("a_r6_r7_p163", true, "after torture", "a_r6_r7");
          settings.Add("a_r6_r7_all", false, "always", "a_r6_r7");
        settings.Add("a_r6_r8", false, "to Nuke Building, B2", "a_r6");
        settings.Add("a_r6_r12_all", false, "to Snowfield", "a_r6");
      settings.Add("a_r7", true, "Nuke Building, B1", "advanced_loc");
        settings.Add("a_r7_r6", true, "to Nuke Building", "a_r7");
          settings.Add("a_r7_r6_p150", true, "after Wolf ambushes Meryl", "a_r7_r6");
        settings.Add("a_r7_r8", true, "to Nuke Building, B2", "a_r7");
          settings.Add("a_r7_r8_p69", true, "after collecting Nikita", "a_r7_r8");
          settings.Add("a_r7_r8_all", false, "always", "a_r7_r8");
        settings.Add("a_r7_r36", true, "to Commander's Room", "a_r7");
          settings.Add("a_r7_r36_p119", true, "after meeting Meryl", "a_r7_r36");
          settings.Add("a_r7_r36_p150", true, "after collecting PSG-1 (AB)", "a_r7_r36");
          settings.Add("a_r7_r36_p163", true, "after torture", "a_r7_r36");
          settings.Add("a_r7_r36_all", false, "always", "a_r7_r36");
      settings.Add("a_r8", true, "Nuke Building, B2", "advanced_loc");
        settings.Add("a_r8_r6_all", false, "to Nuke Building", "a_r8");
        settings.Add("a_r8_r7", true, "to Nuke Building, B1", "a_r8");
          settings.Add("a_r8_r7_p111", true, "after Ninja", "a_r8_r7");
        settings.Add("a_r8_r45", true, "to Nuke Building, B2 Corridor", "a_r8");
          settings.Add("a_r8_r45_p69", true, "after collecting Nikita", "a_r8_r45");
          settings.Add("a_r8_r45_all", false, "always", "a_r8_r45");
      settings.Add("a_r45", true, "Nuke Building, B2 Corridor", "advanced_loc");
        settings.Add("a_r45_r8", true, "to Nuke Building, B2", "a_r45");
          settings.Add("a_r45_r8_p111", true, "after Ninja", "a_r45_r8");
          settings.Add("a_r45_r8_all", false, "always", "a_r45_r8");
        settings.Add("a_r45_r35", true, "to Lab", "a_r45");
          settings.Add("a_r45_r35_p75", true, "after collecting Nikita", "a_r45_r35");
          settings.Add("a_r45_r35_all", false, "always", "a_r45_r35");
      settings.Add("a_r35", true, "Lab", "advanced_loc");
        settings.Add("a_r35_r45", true, "to Nuke Building, B2 Corridor", "a_r35");
          settings.Add("a_r35_r45_p111", true, "after Ninja", "a_r35_r45");
          settings.Add("a_r35_r45_all", false, "always", "a_r35_r45");
      settings.Add("a_r36", true, "Commander's Room", "advanced_loc"); // TODO diff mantis
        settings.Add("a_r36_r7", true, "to Nuke Building, B1", "a_r36");
          settings.Add("a_r36_r7_p150", true, "after Wolf ambushes Meryl", "a_r36_r7");
          settings.Add("a_r36_r7_pall", false, "always", "a_r36_r7");
        settings.Add("a_r36_r9", true, "to Cave", "a_r36");
          settings.Add("a_r36_r9_p137", true, "after Psycho Mantis", "a_r36_r9");
          settings.Add("a_r36_r9_p150", true, "after collecting PSG-1 (AB)", "a_r36_r9");
          settings.Add("a_r36_r9_p163", true, "after torture", "a_r36_r9");
          settings.Add("a_r36_r9_all", false, "always", "a_r36_r9");
      settings.Add("a_r9", true, "Cave", "advanced_loc");
        settings.Add("a_r9_r36", true, "to Commander's Room", "a_r9");
          settings.Add("a_r9_r36_p149", true, "after Wolf ambushes Meryl", "a_r9_r36");
          settings.Add("a_r9_r36_all", false, "always", "a_r9_r36");
        settings.Add("a_r9_r37", true, "to Underground Passage", "a_r9");
          settings.Add("a_r9_r37_p141", true, "after Psycho Mantis", "a_r9_r37");
          settings.Add("a_r9_r37_p150", true, "after collecting PSG-1 (AB)", "a_r9_r37");
          settings.Add("a_r9_r37_p163", true, "after torture", "a_r9_r37");
          settings.Add("a_r9_r37_all", false, "always", "a_r9_r37");
      settings.Add("a_r37", true, "Underground Passage", "advanced_loc");
        settings.Add("a_r37_r9", true, "to Cave", "a_r37");
          settings.Add("a_r37_r9_p149", true, "after Wolf ambushes Meryl", "a_r37_r9");
          settings.Add("a_r37_r9_all", false, "always", "a_r37_r9");
        settings.Add("a_r37_r38_all", true, "to Torture Room", "a_r37");
        settings.Add("a_r37_r10", true, "to Communications Tower A", "a_r37");
          settings.Add("a_r37_r10_p173", true, "after torture", "a_r37_r10");
          settings.Add("a_r37_r10_all", false, "always", "a_r37_r10");
      settings.Add("a_r38", true, "Torture Room", "advanced_loc");
        settings.Add("a_r38_r20_all", true, "to Medi Room", "a_r38");
      settings.Add("a_r20", true, "Medi Room", "advanced_loc");
        settings.Add("a_r20_r38_all", false, "to Torture Room", "a_r20");
        settings.Add("a_r20_r3", true, "to Cell", "a_r20");
          settings.Add("a_r20_r3_p163", true, "after torture", "a_r20_r3");
          settings.Add("a_r20_r3_all", false, "always", "a_r20_r3");
      settings.Add("a_r10", true, "Communications Towers", "advanced_loc");
        settings.Add("a_r10_r37_all", false, "to Underground Passage", "a_r10");
        settings.Add("a_r10_r44", true, "to Communications Tower Roofs", "a_r10");
          settings.Add("a_r10_r44_p173", true, "after stairs chase", "a_r10_r44");
          settings.Add("a_r10_r44_p183", true, "after meeting Otacon", "a_r10_r44");
          settings.Add("a_r10_r44_all", false, "always", "a_r10_r44");
        settings.Add("a_r10_r11_all", false, "to Walkway", "a_r10");
        settings.Add("a_r10_r12", true, "to Snowfield", "a_r10");
          settings.Add("a_r10_r12_p195", true, "after Hind D", "a_r10_r12");
          settings.Add("a_r10_r12_all", false, "always", "a_r10_r12");
      settings.Add("a_r44", true, "Communications Tower Roofs", "advanced_loc");
        settings.Add("a_r44_r39_all", true, "to Communications Tower Rappel", "a_r44");
        settings.Add("a_r44_r10", true, "to Communications Towers", "a_r44");
          settings.Add("a_r44_r10_p190", true, "after Hind D", "a_r44_r10");
          settings.Add("a_r44_r10_all", false, "always", "a_r44_r10");
      settings.Add("a_r39", true, "Communications Tower Rappel", "advanced_loc");
        settings.Add("a_r39_r11_all", false, "to Walkway", "a_r39");
      settings.Add("a_r11", true, "Walkway", "advanced_loc");
        settings.Add("a_r11_r10", true, "to Communications Towers", "a_r11");
          settings.Add("a_r11_r10_p180", true, "after walkway ambush", "a_r11_r10");
          settings.Add("a_r11_r10_all", false, "always", "a_r11_r10");
      settings.Add("a_r12", true, "Snowfield", "advanced_loc");
        settings.Add("a_r12_r1_all", false, "to Heliport", "a_r12");
        settings.Add("a_r12_r6_all", false, "to Nuke Building", "a_r12");
        settings.Add("a_r12_r10_all", false, "to Communications Towers", "a_r12");
        settings.Add("a_r12_r13", true, "to Blast Furnace", "a_r12");
          settings.Add("a_r-1_r13_p204", true, "after Sniper Wolf 2", "a_r12_r13");
          settings.Add("a_r12_r13_all", false, "always", "a_r12_r13");
      settings.Add("a_r13", true, "Blast Furnace", "advanced_loc");
        settings.Add("a_r13_r12_all", false, "to Snowfield", "a_r13");
        settings.Add("a_r13_r14", true, "to Cargo Elevator", "a_r13");
          settings.Add("a_r13_r14_p204", true, "after Sniper Wolf 2", "a_r13_r14");
          settings.Add("a_r13_r14_p244", true, "after heating the PAL key", "a_r13_r14");
          settings.Add("a_r13_r14_all", false, "always", "a_r13_r14");
      settings.Add("a_r14", true, "Cargo Elevator", "advanced_loc");
        settings.Add("a_r14_r13", true, "to Blast Furnace", "a_r14");
          settings.Add("a_r14_r13_p244", true, "after entering cold PAL key", "a_r14_r13");
          settings.Add("a_r14_r13_all", false, "always", "a_r14_r13");
        settings.Add("a_r14_r40", true, "to Warehouse", "a_r14");
          settings.Add("a_r14_r40_p209", true, "after Sniper Wolf 2", "a_r14_r40");
          settings.Add("a_r14_r40_all", false, "always", "a_r14_r40");
        settings.Add("a_r14_r17", true, "to Warehouse (with guards)", "a_r14");
          settings.Add("a_r14_r17_p246", true, "after heating the PAL key", "a_r14_r17");
      settings.Add("a_r40", true, "Warehouse", "advanced_loc");
        settings.Add("a_r40_r14_all", false, "to Cargo Elevator", "a_r40");
        settings.Add("a_r40_r15", true, "to Warehouse North", "a_r40");
          settings.Add("a_r40_r15_p219", true, "after Vulcan Raven", "a_r40_r15");
          settings.Add("a_r40_r15_p240", false, "after cooling the PAL key", "a_r40_r15");
          settings.Add("a_r40_r15_all", false, "always", "a_r40_r15");
      settings.Add("a_r17", true, "Warehouse (with guards)", "advanced_loc");
        settings.Add("a_r17_r14", true, "to Cargo Elevator", "a_r17");
          settings.Add("a_r17_r14_p242", true, "after entering cold PAL key", "a_r17_r14");
          settings.Add("a_r17_r14_all", false, "always", "a_r17_r14");
        settings.Add("a_r17_r15", false, "to Warehouse North", "a_r17");
          settings.Add("a_r17_r15_p246", true, "after heating the PAL key", "a_r17_r15");
          settings.Add("a_r17_r15_all", true, "always", "a_r17_r15");
      settings.Add("a_r15", true, "Warehouse North", "advanced_loc");
        settings.Add("a_r15_r40", true, "to Warehouse", "a_r15");
          settings.Add("a_r15_r40_p240", true, "after entering normal PAL key", "a_r15_r40");
          settings.Add("a_r15_r40_all", false, "always", "a_r15_r40");
        settings.Add("a_r15_r17", true, "to Warehouse (with guards)", "a_r15");
          settings.Add("a_r15_r17_p242", true, "after entering cold PAL key", "a_r15_r17");
          settings.Add("a_r15_r17_all", true, "always", "a_r15_r17");
        settings.Add("a_r15_r16", true, "to Underground Base", "a_r15");
          settings.Add("a_r15_r16_p219", true, "after Vulcan Raven", "a_r15_r16");
          settings.Add("a_r15_r16_p240", true, "after entering normal PAL key", "a_r15_r16");
          settings.Add("a_r15_r16_p242", true, "after cooling the PAL key", "a_r15_r16");
          settings.Add("a_r15_r16_p246", true, "after heating the PAL key", "a_r15_r16");
          settings.Add("a_r15_r16_all", false, "always", "a_r15_r16");
      settings.Add("a_r16", true, "Underground Base", "advanced_loc");
        settings.Add("a_r16_r15", true, "to Warehouse North", "a_r16");
          settings.Add("a_r16_r15_p240", true, "after entering normal PAL key", "a_r16_r15");
          settings.Add("a_r16_r15_p242", true, "after entering cold PAL key", "a_r16_r15");
          settings.Add("a_r16_r15_all", false, "always", "a_r16_r15");
        settings.Add("a_r16_r41_all", true, "to Supply Route (Rex)", "a_r16");
      settings.Add("a_r41", true, "Supply Route (Rex)", "advanced_loc");
        settings.Add("a_r41_r42_all", true, "to Supply Route (Liquid)", "a_r41");
      settings.Add("a_r42", true, "Supply Route (Liquid)", "advanced_loc");
        settings.Add("a_r42_r43_all", true, "to Escape Route", "a_r42");
  
  print("Startup complete");
}

update {
  dynamic D = vars.D;
  D.old = old;
  
  if (!D.Initialised) {
    
    // Debug message handler
    string DebugPath = System.IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\mgsi.log";
    D.DebugTimer = 0;
    D.InfoTimer = 0;
    D.InfoPriority = -1;
    D.DebugTimerStart = 120;
    D.PrevInfo = "";
    vars.DebugMessage = "";
    vars.Info = "";
    Action<string> Debug = delegate(string message) {
      message = "[" + current.GameTime + "] " + message;
      if (settings["debug_file"]) {
        using(System.IO.StreamWriter stream = new System.IO.StreamWriter(DebugPath, true)) {
          stream.WriteLine(message);
          stream.Close();
        }
      }
      print("[MGSIAS] " + message);
      vars.DebugMessage = message;
      // also overwrite the previous message if we're already showing the "splitting now" message
      if (D.DebugTimer != D.DebugTimerStart) D.PrevDebug = message;
    };
    D.Debug = Debug;
    
    Action<string, int, int> Info = delegate(string Message, int Timer, int Priority) {
      if (Timer == -1) D.PrevInfo = Message;
      if (Priority >= D.InfoPriority) {
        vars.Info = Message;
        D.InfoTimer = Timer;
        D.InfoPriority = Priority;
      }
    };
    D.Info = Info;
    
    // Confirm a split
    Func<string, string, bool> Split = delegate(string Code, string Reason) {
      if ( (!settings["o_nolocationclash"]) || (D.LocationClash(Code)) ) {
        Debug(Code + " clashes with an earlier split, not splitting");
        return false;
      }
      D.DebugTimer = D.DebugTimerStart;
      D.PrevDebug = vars.DebugMessage;
      Debug("Splitting now (" + Reason + ")");
      D.SplitTimes[Code] = current.GameTime;
      return true;
    };
    D.Split = Split;
    
  
    // List possible progress values at essentially the same point in the game
    var SameProgressData = new List<ushort[]> {
      new ushort[] { 52, 58 },
      new ushort[] { 149, 150 },
      new ushort[] { 290, 294 } // VE and regular final split
    };
    D.SameProgressData = new Dictionary<ushort, ushort[]>();
    foreach (ushort[] i in SameProgressData) {
      foreach (ushort j in i) D.SameProgressData.Add(j, i);
    }
    Func<ushort, ushort[]> SameProgress = delegate(ushort Progress) {
      return (D.SameProgressData.ContainsKey(Progress)) ? D.SameProgressData[Progress] : new ushort[] { Progress };
    };
    D.SameProgress = SameProgress;
    
    // Suppress locations that clash with a previous split
    D.LocationClashData = new Dictionary<string, string> {
      { "a_r0_r1_all", "a_p7" }, // Dock > Heliport after reaching Dock elevator
      { "a_r34_r6_p69", "a_p68" }, // Canyon > Nuke Bldg after beating Tank
      { "a_r10_r44_p173", "a_p174" }, // Comms Tower A > CTA Roof after chase
      { "a_r41_42_all", "a_p257" }, // Supply Route Rex > Liquid
      { "a_r42_43_all", "a_p278" } // Supply Route > Escape Route
    };
    Func<string, bool> LocationClash = delegate(string Code) {
      if (!D.LocationClashData.ContainsKey(Code)) return false;
      string Clash = D.LocationClashData[Code];
      return (D.SplitTimes[Clash] > 0);
    };
    D.LocationClash = LocationClash;
    
    // Check if a weapon/item has just unlocked
    Func<byte[], byte[], sbyte> ItemUnlocked = delegate(byte[] Data, byte[] OldData) {
      int Len = Data.Length;
      for (int i = 0; i < Len; i++) {
        int Key = (2 * i) + 1;
        if ( (Data[Key] == 0) && (OldData[Key] == 255) )
          return (sbyte) i;
      }
      return -1;
    };
    D.ItemUnlocked = ItemUnlocked;
  
    // Dock elevator timer
    Func<bool> WatDock = delegate() {
      if ( (settings["asl_info_dock"]) && (current.DockTimer < D.old.DockTimer) )
        D.Info("Elevator appears in " + D.FramesToSeconds(current.DockTimer * 2), 15, 1);
      return false;
    };
    D.Watch.Add("a_p6", WatDock);
    
    // VE final split
    Func<bool> ExcVEResults = () => (current.Difficulty == -1);
    D.Except.Add("a_p286", ExcVEResults);
    
    // Results
    Func<bool> WatResults = delegate() {
      if ( (!D.SplitTimes.ContainsKey("a_p294")) || (D.SplitTimes["a_p294"] != 0) ) return false;
      return (current.RoomCode != -1);
    };
    Func<bool> ExcFalse = () => false;
    D.Watch.Add("a_p294", WatResults);
    D.Except.Add("a_p294", ExcFalse); // Don't split unless the watcher returns true
    
    
    // General boss watcher
    D.BossCombo = 0;
    D.BossComboTimer = 0;
    D.BossRunningDmg = 0;
    Func<string, int, int, int, bool, bool> BossHealth = delegate(string Name, int Hp, int PrevHp, int MaxHp, bool EndOnZero) {
      if (!settings["asl_info_boss"]) return false;
      
      bool Return = false;
      bool ClearData = false;
      string StrDmg = "";
      int DisplayHp = Hp;
      // Boss has taken damage
      if (Hp < PrevHp) {
        // Handle boss dead situations
        if (Hp <= 0) {
          if (EndOnZero) ClearData = true;
          DisplayHp = 0;
        }
        // Combo data
        int HpDelta = PrevHp - Hp;
        D.BossCombo++;
        D.BossRunningDmg += HpDelta;
        if (settings["asl_info_boss_dmg_flurry"]) D.BossComboTimer = 30;
        else D.BossComboTimer = (settings["asl_info_boss_dmg_full"]) ? Int32.MaxValue : 0;
        // Damage string
        StrDmg = "-" + D.BossRunningDmg;
        if ( (settings["asl_info_boss_combo"]) && (D.BossCombo > 1) )
          StrDmg = D.BossCombo + " hits! " + StrDmg;
      }
      // Main info string      
      if ( (Hp != PrevHp) && (Hp > 0) ) {
        string StrInfo = " | " + D.FormatValue(DisplayHp, MaxHp) + " HP";
        D.Info(Name + StrInfo, -1, 1);
        if (StrDmg != "") D.Info(StrDmg + StrInfo, 120, 1);
        Return = true;
      }
      // Reset data when the combo times out
      if (D.BossComboTimer > 0) {
        D.BossComboTimer--;
        if (D.BossComboTimer == 0) {
          D.BossCombo = 0;
          D.BossRunningDmg = 0;
        }
      }
      // Clean up when boss is ded
      if (ClearData) {
        D.Info("Boss defeated!", 120, 1);
        D.PrevInfo = "";
        D.BossCombo = 0;
        D.BossComboTimer = 0;
        D.BossRunningDmg = 0;
        return true;
      }
      
      return Return;
    };
    D.BossHealth = BossHealth;
    
    // Bosses
    Func<bool> WatOcelot = () => (D.BossHealth("Revolver Ocelot", current.OcelotHp, D.old.OcelotHp, 1024, true) && false);
    Func<bool> WatNinja = () => (D.BossHealth("Ninja", current.NinjaHp, D.old.NinjaHp, 255, true) && false);
    Func<bool> WatMantis = () => (D.BossHealth("Psycho Mantis", current.MantisHp, D.old.MantisHp, current.MantisMaxHp, true) && false);
    Func<bool> WatWolf1 = () => (D.BossHealth("Sniper Wolf", current.Wolf1Hp, D.old.Wolf1Hp, 1024, true) && false);
    Func<bool> WatHind = () => (D.BossHealth("Hind D", current.HindHp, D.old.HindHp, 1024, false) && false);
    Func<bool> WatWolf2 = () => (D.BossHealth("Sniper Wolf", current.Wolf2Hp, D.old.Wolf2Hp, 1024, true) && false);
    Func<bool> WatRaven = () => (D.BossHealth("Vulcan Raven", current.RavenHp, D.old.RavenHp, current.RavenMaxHp, true) && false);
    Func<bool> WatRex = () => (D.BossHealth("Metal Gear REX", current.RexHp, D.old.RexHp, current.RexMaxHp, true) && false);
    D.WatRex = WatRex;
    
    Func<bool> WatLiquid = delegate() {
      if (!D.BossHealth("Liquid Snake", current.LiquidHp, D.old.LiquidHp, 255, false)) return false;
      int Phase = 1;
      if (
        ( (current.Difficulty < 2) && (current.LiquidHp < 56) ) ||
        (current.LiquidHp < 58)
      ) Phase = 3;
      else if (current.LiquidHp < 170) Phase = 2;
      string StrAdd = " (Phase " + Phase + ")";
      vars.Info += StrAdd;
      D.PrevInfo += StrAdd;
      return false;
    };
    
    //Func<bool> WatEscape = () => (D.BossHealth("Liquid Snake", current.EscapeHp, D.old.EscapeHp, D.EscapeMaxHp, false) && false);
    
    // Rex Phase 1
    Func<bool> WatRex1 = delegate() {
      if (current.VsRex) D.WatRex();
      if ( (!D.SplitTimes.ContainsKey("a_p255")) || (D.SplitTimes["a_p255"] != 0) ) return false;
      return ( (!current.VsRex) && (D.old.VsRex) );
    };
    
    // Rex Phase 2
    Func<bool> WatRex2 = delegate() {
      if (current.VsRex) D.WatRex();
      if ( (!D.SplitTimes.ContainsKey("a_p257")) || (D.SplitTimes["a_p257"] != 0) ) return false;
      return (!current.VsRex);
    };
    
    // Attach bosses
    D.Watch.Add("a_p38", WatOcelot);
    D.Watch.Add("a_p77", WatNinja);
    D.Watch.Add("a_p129", WatMantis);
    D.Watch.Add("a_r37_p150", WatWolf1);
    D.Watch.Add("a_p186", WatHind); 
    D.Watch.Add("a_p197", WatWolf2);
    D.Watch.Add("a_p211", WatRaven);
    D.Watch.Add("a_p255", WatRex1);
    D.Watch.Add("a_p257", WatRex2);
    D.Watch.Add("a_p277", WatLiquid);
    // D.Watch.Add("a_p283", WatEscape);
    
    
    // Convert frames to seconds
    Func<int, string> FramesToSeconds = (int Frames) => string.Format("{0:F1}", (decimal) Frames / 60);
    D.FramesToSeconds = FramesToSeconds;
    
    // Convert current/max to percentage (if that setting is enabled)
    Func<int, int, string> FormatValue = delegate(int Current, int Max) {
      if (settings["asl_info_percent"]) return string.Format("{0:P0}", (double) Current / Max);
      if (settings["asl_info_max"]) {
        int Len = (int) Math.Floor(Math.Log10(Max) + 1);
        return string.Format("{0," + Len + "}/{1,-" + Len + "}", Current, Max);
      }
      return Current.ToString();
    };
    D.FormatValue = FormatValue;
    
    D.Initialised = true;
  }
  
  vars.CurrentRoom = "";
  if ( (settings["asl_info"]) && (!current.InMenu) ) {
    
    if (settings["asl_info_chaff"]) {
      if ( (current.ChaffTime != old.ChaffTime) && (old.ChaffTime > 0) )
        D.Info( string.Format(
          "Chaff: {0} ({1,4} left)",
          D.FormatValue(current.ChaffTime, 300),
          D.FramesToSeconds(current.ChaffTime * 2)
        ), 15, 2);
    }
    
    if (settings["asl_info_o2"]) {
      if (old.O2Time < 1024)
        D.Info( string.Format(
          "O2: {0} ({1,4} left)",
          D.FormatValue(current.O2Time, 1024),
          D.FramesToSeconds(current.O2Time * 4)
        ), 15, 3);
    }
    
    if ( (current.RoomCode != old.RoomCode) || (vars.CurrentRoom == "") ) {
      string CurrentRoom;
      D.Rooms.TryGetValue(current.RoomCode, out CurrentRoom);
      if (CurrentRoom != "") vars.CurrentRoom = CurrentRoom;
      if (D.InfoTimer == -1) D.InfoTimer = 0;
    }
    
    if ( (current.Difficulty != old.Difficulty) || (vars.Difficulty == "") ) {
      vars.Difficulty = ( (current.Difficulty >= -1) && (current.Difficulty <= 3) ) ?
        D.Difficulties[current.Difficulty] : "";
    }
    
    if (D.InfoTimer != -1) {
      D.InfoTimer--;
      if (D.InfoTimer == -1) {
        vars.Info = ( (settings["asl_info_room"]) && (D.PrevInfo == "") ) ? vars.CurrentRoom : D.PrevInfo;
        D.InfoPriority = -1;
      }
    }
    
    if (settings["asl_info_codename"]) {
      
    }
    
  }
  
  
  if ( (!current.InMenu) && (old.InMenu) ) D.InitVars();
  return true;
}

split {
  dynamic D = vars.D;

  sbyte NewItem = -1;
  if (settings["advanced_wep"]) {
    NewItem = D.ItemUnlocked(current.WeaponData, old.WeaponData);
    if ( (NewItem != -1) && (settings["a_w" + NewItem]) )
      return D.Split("a_w" + NewItem, "Weapon " + NewItem + " unlocked");
  }
  if (settings["advanced_itm"]) {
    NewItem = D.ItemUnlocked(current.ItemData, old.ItemData);
    if ( (NewItem != -1) && (settings["a_i" + NewItem]) )
      return D.Split("a_i" + NewItem, "Item " + NewItem + " unlocked");
  }
  
  string ProgressCode = "a_p" + current.Progress;
  string RoomCode = "a_r" + current.RoomCode;
  string RoomProgressCode = RoomCode + "_p" + current.Progress;
  bool WatchProgress = ( (D.Watch.ContainsKey(ProgressCode)) && (D.Watch[ProgressCode]()) );
  bool WatchRoom = ( (D.Watch.ContainsKey(RoomCode)) && (D.Watch[RoomCode]()) );
  bool WatchRoomProgress = ( (D.Watch.ContainsKey(RoomProgressCode)) && (D.Watch[RoomProgressCode]()) );
  
  if ( (settings["advanced_evt"]) || (settings["advanced_minevt"]) ) {
    if ( (settings.ContainsKey(ProgressCode)) && (settings[ProgressCode]) ) {
      if (WatchProgress) return D.Split(ProgressCode, ProgressCode + " (watch)");
      if (current.Progress != old.Progress) {
        if (D.Except.ContainsKey(ProgressCode)) {
          if (D.Except[ProgressCode]()) return D.Split(ProgressCode, ProgressCode + " (except)");
        }
        else return D.Split(ProgressCode, "Reached " + ProgressCode);
      }
    }
  }
  
  if ( (settings["advanced_loc"]) && (current.RoomCode != old.RoomCode) ) {
    string LocationCode = "a_r" + old.RoomCode + "_r" + current.RoomCode;
    string LocationAll = LocationCode + "_all";
    if ( (settings.ContainsKey(LocationAll)) && (settings[LocationAll]) ) return D.Split(LocationAll, LocationAll + " (all visits");
    foreach ( ushort Progress in D.SameProgress(current.Progress) ) {
      string LocationProgress = LocationCode + "_p" + Progress;
      D.Debug(LocationProgress + " (looking)");
      if ( (settings.ContainsKey(LocationProgress)) && (settings[LocationProgress]) ) {
        if ( (!settings["o_nomultisplit"]) || (!D.SplitTimes.ContainsKey(LocationProgress)) || (D.SplitTimes[LocationProgress] == 0) )
          return D.Split(LocationProgress, LocationProgress + " (room change)");
      }
    }
  }
  
  return false;
}







































