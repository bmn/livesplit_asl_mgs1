/* Autosplitter for Metal Gear Solid: Integral (PC) */

state("mgsi") {
  bool      STATS:        0x000000;
  ushort    Alerts:       0x38E87C;
  ushort    Kills:        0x38E87E;
  ushort    Rations:      0x38E88C;
  ushort    Continues:    0x38E88E;
  ushort    Saves:        0x38E890;
  bool      OTHER_DATA_BELOW: 0x000000;
  uint      GameTime:     0x595344;
  sbyte     RoomCode:     0x28CE34;
  ushort    Progress:     0x38D7CA;
  ushort    Health:       0x000000;
  ushort    O2Time:       0x595348;
  short     ChaffTime:    0x391A28;
  ushort    OcelotHp:     0x4FD2D4;
  ushort    Wolf1Hp:      0x5059E0;
  ushort    RexHp:        0x323906;
  byte      LiquidHp:     0x50B978;
  bool      InMenu:       0x31D180;
  bool      VsRex:        0x388630;
  byte20    WeaponData:   0x38E802;
}

isLoading {
  return true;
}

gameTime {
  return TimeSpan.FromMilliseconds((current.GameTime) * 1000 / 60);
}

reset {
  // Don't reset from the credits
  if ( (current.InMenu) && (current.InMenu != old.InMenu) && (current.Progress != 294) ) {
    vars.D.InitVars();
    return true;
  }
  return false;
}

start {
  if ( (current.Progress == 1) && (current.Progress != old.Progress) ) {
    vars.D.InitVars();
    return true;
  }
  return false;
} 

startup {
  vars.D = new ExpandoObject();
  dynamic D = vars.D;
  D.Except = new Dictionary< string, Func<bool> >();
  D.Watch = new Dictionary< string, Func<bool> >();
  D.Initialised = false;
  
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
		{ 6, "Nuke Building 1" },
		{ 7, "Nuke Building 1, B1" },
		{ 8, "Nuke Building 1, B2" },
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
		{ 45, "Nuke Building 1, B2 Corridor" },
  };
  
  settings.Add("options", true, "Options");
    settings.Add("debug_file", true, "Save debug information to LiveSplit program directory", "options");
    settings.Add("o_nomultisplit", true, "Suppress splitting on repeated actions", "options");
    settings.Add("o_nolocationclash", true, "Suppress location splits that clash with enabled major splits (TODO)", "options");
    
  settings.Add("asl", true, "ASL Var Viewer integration");
  settings.SetToolTip("asl", "Disabling this may slightly improve performance");
    settings.Add("asl_info", true, "Info (contextual information)", "asl");
      settings.Add("asl_info_vars", true, "Display these values:", "asl_info");
        settings.Add("asl_info_codename", true, "Codename changes (TODO)", "asl_info_vars");
        settings.Add("asl_info_room", false, "Current location", "asl_info_vars");
        settings.SetToolTip("asl_info_room", "Use CurrentRoom if you only want the location");
        settings.Add("asl_info_chaff", true, "Chaff", "asl_info_vars");
        settings.Add("asl_info_o2", true, "O2 (TODO)", "asl_info_vars");
          settings.Add("asl_info_o2health", false, "Also show the time remaining from Life", "asl_info_o2");
        settings.Add("asl_info_boss", true, "Boss health (TODO)", "asl_info_vars");
          settings.Add("asl_info_boss_dmg_flurry", true, "Group hits done within a short time", "asl_info_boss");
          settings.SetToolTip("asl_info_boss_dmg_flurry", "Shows the sum damage for flurries of attacks");
          settings.Add("asl_info_boss_dmg_full", false, "Group all hits done during the battle", "asl_info_boss");
          settings.SetToolTip("asl_info_boss_dmg_full", "A simple damage increment that never resets");
          settings.Add("asl_info_boss_combo", true, "Add a combo counter", "asl_info_boss");
          settings.SetToolTip("asl_info_boss_combo", "This uses the same timing as grouped attacks above");
        settings.Add("asl_info_choke", true, "Choke torture progress (TODO)", "asl_info_vars");
      settings.Add("asl_info_max", true, "Also show the maximum value for raw values", "asl_info");
      settings.Add("asl_info_percent", true, "Show percentages instead of raw values", "asl_info");
    settings.Add("asl_codename", true, "CodeNameStatus (Perfect Stats attempt tracking) (TODO)", "asl");
      settings.Add("asl_codename_specific", true, "Also show the top-rank-specific stats if they are broken", "asl_codename");
      settings.SetToolTip("asl_codename_specific", "Disable this if you're going for Perfect Stats rather than a top rank such as Big Boss");
      settings.Add("asl_codename_short", false, "Show single letters for stats instead of full titles", "asl_codename");
      settings.SetToolTip("asl_codename_short", "Enable this if the full stat names make the message too long");

  settings.Add("advanced", true, "Split Points");
    settings.Add("advanced_evt", true, "Split on major events", "advanced");
      settings.Add("a_p29", true, "Guard Encounter", "advanced_evt");
      settings.Add("a_p39", true, "Revolver Ocelot", "advanced_evt");
      settings.Add("a_p68", true, "M1 Tank", "advanced_evt");
      settings.Add("a_p78", true, "Ninja", "advanced_evt");
      settings.Add("a_p133", true, "Psycho Mantis", "advanced_evt");
      settings.Add("a_p151", true, "Sniper Wolf", "advanced_evt");
      settings.Add("a_p174", true, "Communications Tower Chase", "advanced_evt");
      settings.Add("a_p179", true, "Communications Tower Rappel", "advanced_evt");
      settings.Add("a_p188", true, "Hind D", "advanced_evt");
      settings.Add("a_p195", true, "Comms Tower Elevator Ambush", "advanced_evt");
      settings.Add("a_p198", true, "Sniper Wolf 2", "advanced_evt"); // test this with gme, switch to 200 if failed
      settings.Add("a_p207", true, "Cargo Elevator Ambush", "advanced_evt");
      settings.Add("a_p212", true, "Vulcan Raven", "advanced_evt");
      settings.Add("a_p255", true, "Rex Phase 1", "advanced_evt");
      settings.Add("a_p257", true, "Rex Phase 2", "advanced_evt");
      settings.Add("a_p278", true, "Liquid Snake", "advanced_evt");
      settings.Add("a_p286", true, "Escape", "advanced_evt");
      settings.Add("a_p294", true, "Results", "advanced_evt");
    settings.Add("advanced_minevt", false, "Split on minor events", "advanced");
      settings.Add("a_p7", false, "Dock Elevator", "advanced_minevt");
      settings.Add("a_p27", false, "Exit DARPA Chief's cell", "advanced_minevt");
      settings.Add("a_p126", false, "Stun Meryl", "advanced_minevt");
      settings.Add("a_p238", false, "Retrieved PAL Key", "advanced_minevt");
      settings.Add("a_p239", false, "Normal PAL Key", "advanced_minevt");
      settings.Add("a_p241", false, "Cold PAL Key", "advanced_minevt");
      settings.Add("a_p247", false, "Hot PAL Key", "advanced_minevt");
      settings.Add("a_p287", false, "Ending Codec (final split for Very Easy)", "advanced_minevt");
    settings.Add("advanced_wep", false, "Split when collecting weapons for the first time", "advanced");
      settings.Add("a_w0", true, "SOCOM", "advanced_wep");
      settings.Add("a_w1", true, "FA-MAS", "advanced_wep");
      settings.Add("a_w2", true, "Grenade", "advanced_wep");
      settings.Add("a_w3", true, "Nikita", "advanced_wep");
      settings.Add("a_w4", true, "Stinger", "advanced_wep");
      settings.Add("a_w5", true, "Claymore", "advanced_wep");
      settings.Add("a_w6", true, "C4", "advanced_wep");
      settings.Add("a_w7", true, "Stun Grenade", "advanced_wep");
      settings.Add("a_w8", true, "Chaff Grenade", "advanced_wep");
      settings.Add("a_w9", true, "PSG-1", "advanced_wep");
    settings.Add("advanced_loc", false, "Split when moving between areas", "advanced");
      settings.Add("a_r0", true, "Dock", "advanced_loc");
        settings.Add("a_r0_r1_all", true, "to Heliport", "a_r0");
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
        settings.Add("a_r3_r2", false, "to Tank Hangar", "a_r3");
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
          settings.Add("a_r36_r9_p137", true, "after Psycho Mantis", "a_r36_r9"); // maybe 138
          settings.Add("a_r36_r9_p150", true, "after collecting PSG-1 (AB)", "a_r36_r9");
          settings.Add("a_r36_r9_p163", true, "after torture", "a_r36_r9");
          settings.Add("a_r36_r9_all", false, "always", "a_r36_r9");
      settings.Add("a_r9", true, "Cave", "advanced_loc");
        settings.Add("a_r9_r36", true, "to Commander's Room", "a_r9");
          settings.Add("a_r9_r36_p149", true, "after Wolf ambushes Meryl", "a_r9_r36"); // maybe 150
          settings.Add("a_r9_r36_all", false, "always", "a_r9_r36");
        settings.Add("a_r9_r37", true, "to Underground Passage", "a_r9");
          settings.Add("a_r9_r37_p141", true, "after Psycho Mantis", "a_r9_r37"); // maybe 143
          settings.Add("a_r9_r37_p150", true, "after collecting PSG-1 (AB)", "a_r9_r37");
          settings.Add("a_r9_r37_p163", true, "after torture", "a_r9_r37");
          settings.Add("a_r9_r37_all", false, "always", "a_r9_r37");
      settings.Add("a_r37", true, "Underground Passage", "advanced_loc");
        settings.Add("a_r37_r9", true, "to Cave", "a_r37");
          settings.Add("a_r37_r9_p149", true, "after Wolf ambushes Meryl", "a_r37_r9");
          settings.Add("a_r37_r9_all", false, "always", "a_r37_r9");
        settings.Add("a_r37_r38_all", true, "to Torture Room", "a_r37");
        settings.Add("a_r37_r10", true, "to Communications Tower A", "a_r37");
          settings.Add("a_r37_r10_p173", true, "after torture", "a_r37");
          settings.Add("a_r37_r10_all", false, "always", "a_r37");
      settings.Add("a_r38", true, "Torture Room", "advanced_loc");
        settings.Add("a_r38_r20_all", false, "to Medi Room", "a_r38");
      settings.Add("a_r20", true, "Medi Room", "advanced_loc");
        settings.Add("a_r20_r38_all", false, "to Torture Room", "a_r20");
        settings.Add("a_r20_r3", true, "to Cell", "a_r20");
          settings.Add("a_r20_r3_p163", true, "after torture", "a_r20_r3");
          settings.Add("a_r20_r3_all", false, "always", "a_r20_r3");
      settings.Add("a_r10", true, "Communications Towers", "advanced_loc");
        settings.Add("a_r10_r37_all", false, "to Underground Passage", "a_r10");
        settings.Add("a_r10_r44", true, "to Communications Tower Roofs", "a_r10");
          settings.Add("a_r10_r44_p173", true, "after stairs chase", "a_r10_r44"); // maybe 174
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
          settings.Add("a_r12_r13_p204", true, "after Sniper Wolf 2", "a_r12_r13");
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
          settings.Add("a_r14_r13_all", true, "always", "a_r14_r13");
        settings.Add("a_r14_r40", true, "to Warehouse", "a_r14");
          settings.Add("a_r14_r40_p210", true, "after Sniper Wolf 2", "a_r14_r40"); // maybe 209
          settings.Add("a_r14_r40_all", false, "always", "a_r14_r40");
        settings.Add("a_r14_r17", true, "to Warehouse (with guards)", "a_r14");
          settings.Add("a_r14_r17_p246", true, "after heating the PAL key", "a_r14_r17");
      settings.Add("a_r40", true, "Warehouse", "advanced_loc");
        settings.Add("a_r40_r14_all", false, "to Cargo Elevator", "a_r40");
        settings.Add("a_r40_r15", true, "to Warehouse North", "a_r40");
          settings.Add("a_r40_r15_p219", true, "after Vulcan Raven", "a_r40_r15");
          settings.Add("a_r40_r15_all", false, "after cooling the PAL key", "a_r40_r15");
      settings.Add("a_r17", true, "Warehouse (with guards)", "advanced_loc");
        settings.Add("a_r17_r14", true, "to Cargo Elevator", "a_r17");
          settings.Add("a_r17_r14_p242", true, "after entering cold PAL key", "a_r17_r14");
          settings.Add("a_r17_r14_all", false, "always", "a_r17_r14");
        settings.Add("a_r17_r15", false, "to Warehouse North", "a_r17");
          settings.Add("a_r17_r15_p246", false, "after heating the PAL key", "a_r17_r15");
      settings.Add("a_r15", true, "Warehouse North", "advanced_loc");
        settings.Add("a_r15_r40", true, "to Warehouse", "a_r15");
          settings.Add("a_r15_r40_p240", true, "after entering normal PAL key", "a_r15_r40");
          settings.Add("a_r15_r40_p242", true, "after entering cold PAL key", "a_r15_r40");
          settings.Add("a_r15_r40_all", false, "always", "a_r15_r40");
        settings.Add("a_r15_r16", true, "to Underground Base", "a_r15");
          settings.Add("a_r15_r16_p219", true, "after Vulcan Raven", "a_r15_r16");
          settings.Add("a_r15_r16_p240", true, "after entering normal PAL key", "a_r15_r16");
          settings.Add("a_r15_r16_p242", true, "after cooling the PAL key", "a_r15_r16");
          settings.Add("a_r15_r16_p246", true, "after heating the PAL key", "a_r15_r16");
          settings.Add("a_r15_r16_all", false, "always", "a_r15_r16");
      settings.Add("a_r16", true, "Underground Base", "advanced_loc"); // TODO diff levels, cutscenes?
        settings.Add("a_r16_r15", true, "to Warehouse North", "a_r16");
          settings.Add("a_r16_r15_p240", true, "after entering normal PAL key", "a_r16_r15");
          settings.Add("a_r16_r15_p242", true, "after entering cold PAL key", "a_r16_r15");
          settings.Add("a_r16_r15_all", false, "always", "a_r16_r15");
        settings.Add("a_r16_r41", true, "to Supply Route (Rex)", "a_r16");
      settings.Add("a_r41", true, "Supply Route (Rex)", "advanced_loc");
        settings.Add("a_r41_r42", true, "to Supply Route (Liquid)", "a_r41");
      settings.Add("a_r42", true, "Supply Route (Liquid)", "advanced_loc");
        settings.Add("a_r42_r43", true, "to Escape Route", "a_r42");
  
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
    
    Action<string, int> Info = delegate(string Message, int Timer) {
      if (Timer == -1) D.PrevInfo = Message;
      vars.Info = Message;
      D.InfoTimer = Timer;
    };
    D.Info = Info;
    
    // Confirm a split
    Func<string, string, bool> Split = delegate(string Code, string Reason) {
      D.DebugTimer = D.DebugTimerStart;
      D.PrevDebug = vars.DebugMessage;
      Debug("Splitting now (" + Reason + ")");
      D.SplitTimes[Code] = current.GameTime;
      return true;
    };
    D.Split = Split;
    
  
    // List possible progress values at essentially the same point in the game
    D.SameProgressData = new Dictionary<ushort, ushort[]> {
      { 52, new ushort[] { 52, 58 } },
      { 58, new ushort[] { 52, 58 } }
    };
    Func<ushort, ushort[]> SameProgress = delegate(ushort Progress) {
      return (D.SameProgressData.ContainsKey(Progress)) ? D.SameProgressData[Progress] : new ushort[] { Progress };
    };
    D.SameProgress = SameProgress;
    
    // Check if a weapon has just unlocked
    Func<sbyte> WeaponUnlocked = delegate() {
      for (int i = 0; i < 10; i++) {
        int Key = (2 * i) + 1;
        if ( (current.WeaponData[Key] == 0) && (D.old.WeaponData[Key] == 255) )
          return (sbyte) i;
      }
      return -1;
    };
    D.WeaponUnlocked = WeaponUnlocked;
  
  
    // Rex Phase 1
    Func<bool> WatRex1 = delegate() {
      if ( (vars.SplitTimes["Rex1"] > 0) || (current.VsRex) || (!vars.old.VsRex) ) return false;
      vars.SplitTimes["Rex1"] = current.GameTime;
      return true;
    };
    D.Watch.Add("a_p255", WatRex1);
    
    // Rex Phase 2
    Func<bool> WatRex2 = delegate() {
      if ( (vars.SplitTimes["Rex2"] > 0) || (current.VsRex) ) return false;
      vars.SplitTimes["Rex2"] = current.GameTime;
      return true;
    };
    D.Watch.Add("a_p257", WatRex2);
    
    // Results
    Func<bool> WatResults = delegate() {
      if ( (vars.SplitTimes["Results"] > 0) || (current.RoomCode == -1) ) return false;
      vars.SplitTimes["Results"] = current.GameTime;
      return true;
    };
    D.Watch.Add("a_p294", WatResults);
    
    
    D.Initialised = true;
  }
  
  
  if ( (settings["asl_info"]) && (!current.InMenu) ) {
    
    if (settings["asl_info_chaff"]) {
      if (current.ChaffTime != -1) D.Info("Chaff: " + current.ChaffTime, 30);
    }
    
    if (current.RoomCode != old.RoomCode) {
      string CurrentRoom;
      D.Rooms.TryGetValue(current.RoomCode, out CurrentRoom);
      if (CurrentRoom != "") {
        vars.CurrentRoom = CurrentRoom;
        if (settings["asl_info_room"]) D.Info(vars.CurrentRoom, -1);
      }
    }
    
    if (D.InfoTimer != -1) {
      D.InfoTimer--;
      if (D.InfoTimer == -1) vars.Info = D.PrevInfo;
    }
    
  }
  
  
  if ( (!current.InMenu) && (old.InMenu) ) D.InitVars();
  return true;
}

split {
  dynamic D = vars.D;

  if (settings["advanced_wep"]) {
    sbyte NewWeapon = D.WeaponUnlocked();
    if ( (NewWeapon != -1) && (settings["a_w" + NewWeapon]) ) return D.Split("a_w" + NewWeapon, "Weapon " + NewWeapon + " unlocked");
  }
  
  if ( (settings["advanced_evt"]) || (settings["advanced_minevt"]) ) {
    string ProgressCode = "a_p" + current.Progress;
    if ( (settings.ContainsKey(ProgressCode)) && (settings[ProgressCode]) ) {
      if ( (D.Watch.ContainsKey(ProgressCode)) && (D.Watch[ProgressCode]()) ) return D.Split(ProgressCode, "Watch for " + ProgressCode);
      if (current.Progress != old.Progress) {
        if (D.Except.ContainsKey(ProgressCode)) {
          if (D.Except[ProgressCode]()) return D.Split(ProgressCode, "Except for " + ProgressCode);
        }
        else return D.Split(ProgressCode, "Reached " + ProgressCode);
      }
    }
  }
  
  if ( (settings["advanced_loc"]) && (current.RoomCode != D.old.RoomCode) ) {
    string LocationCode = "a_r" + D.old.RoomCode + "_r" + current.RoomCode;
    string LocationAll = LocationCode + "_all";
    if ( (settings.ContainsKey(LocationAll)) && (settings[LocationAll]) ) return D.Split(LocationAll, "All visits for " + LocationAll);
    foreach ( ushort Progress in D.SameProgress(current.Progress) ) {
      string LocationProgress = LocationCode + "_p" + Progress;
      D.Debug("Looking for " + LocationProgress);
      if ( (settings.ContainsKey(LocationProgress)) && (settings[LocationProgress]) ) {
        if ( (!settings["o_nomultisplit"]) || (!D.SplitTimes.ContainsKey(LocationProgress)) || (D.SplitTimes[LocationProgress] == 0) )
          return D.Split(LocationProgress, "Room change for " + LocationProgress);
      }
    }
  }
  
  return false;
}