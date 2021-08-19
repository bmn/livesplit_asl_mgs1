/****************************************************/
/* Metal Gear Solid Autosplitter 2.0                */
/*                                                  */
/* Emulator Compatibility:                          */
/*  * BizHawk  * DuckStation  * ePSXe  * Mednafen   */
/*  * Retroarch (Beetle PSX)                        */
/*                                                  */
/* Game Compatibility:                              */
/*  * Metal Gear Solid (PSX EU/US/JP)               */
/*  * Metal Gear Solid Integral (PSX JP)            */
/*  * Metal Gear Solid Integral (PC)                */
/*  * Metal Gear Solid Special Missions (PSX EU)    */
/*  * Metal Gear Solid VR Missions (PSX US)         */
/*  * Metal Gear Solid Integral VR-Disc (PSX JP)    */
/*  * Metal Gear Solid Integral VR-Disc (PC)        */
/*                                                  */
/* Created by bmn for Metal Gear Solid Speedrunners */
/*                                                  */
/* Thanks to dlimes13, NickRPGreen and plywood_     */
/*   for their input                                */
/*                                                  */
/* MGSR Clippy art modified from a piece by         */
/*   https://www.deviantart.com/nnmushroom          */
/****************************************************/


/****************************************************/
/* state: Process names to attach to
/* If DuckStation's process name changes in the future, update it here
/*  (it should continue to work as long as the name starts with "duckstation")
/****************************************************/
state("duckstation-qt-x64-ReleaseLTCG") {} // DuckStation
state("duckstation-nogui-x64-ReleaseLTCG") {} // DuckStation
state("ePSXe") {} // ePSXe
state("EmuHawk") {} // BizHawk
state("mednafen") {} // Mednafen
state("mgsi") {} // PC
state("mgsvr") {} // PC (VR Missions)
state("retroarch") {} // Retroarch (Beetle PSX only)


/****************************************************/
/* startup: Initialise the autosplitter and define
/* all functions that don't need settings/current
/****************************************************/
startup {
  vars.D = new ExpandoObject();
  var D = vars.D;

  // Create the main data structures the splitter will be using
  D.Sets = new ExpandoObject(); // Sets of helper data
  D.Names = new ExpandoObject(); // Sets of friendly names
  D.Funcs = new ExpandoObject(); // Helper functions
  D.Mem = new MemoryWatcherList(); // Active MemoryWatchers
  D.ManualMem = new Dictionary<string, ExpandoObject>(); // Manual MemoryWatcher (e.g. byte[])
  D.New = new ExpandoObject(); // Functions to create new data structures
  D.Game = new ExpandoObject(); // Data about the game/emulator
  D.Run = new ExpandoObject(); // Splitter data about the run
  D.Vars = new ExpandoObject(); // Splitter-specific variables
  
  // Shortcuts for startup
  var F = D.Funcs;
  var V = D.Vars;
  var New = D.New;
  var G = D.Game;
  var R = D.Run;
  var M = D.Mem;
  var MM = D.ManualMem;

  // Initial Variable values
  V.ExceptionCount = new Dictionary<string, int>();
  V.AllSettings = new HashSet<string>();
  V.DefaultSettings = new Dictionary<string, bool>();
  V.DefaultParentSettings = new Dictionary<string, bool>();
  V.DefaultSettingsTemplateCount = 0;
  V.LiveSplitDir = System.IO.Path.GetDirectoryName(Application.ExecutablePath);
  V.AppDataDir = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData)
    + "\\bmn\\MetalGearSolidAutosplitter";
  V.DefaultSettingsFile = V.AppDataDir + "\\MetalGearSolid.DefaultSettings";
  V.MajorSplitsFile = V.AppDataDir + "\\MetalGearSolid.MajorSplits";
  V.DebugLogPath = V.AppDataDir + "\\MetalGearSolid.Autosplitter.log";
  V.DebugLogBuffer = new List<string>();
  V.TimerModel = new TimerModel { CurrentState = timer };
  V.BaseFPS = refreshRate;
  V.i = (int)0;
  V.InitInitiated = false;
  V.SplitFileDir = V.AppDataDir;
  V.LastError = DateTime.Now;

  // Initial Game values
  G.BaseAddress = IntPtr.Zero;
  G.OldBaseAddress = IntPtr.Zero;
  G.ProductCode = String.Empty;
  G.VRMissions = false;
  G.FpsLog = new List< Tuple<DateTime, uint> >();
  G.Emulator = true;
  G.Emulators = new List<ExpandoObject>();
  G.CurrentMemoryWatchers = new MemoryWatcherList();
  G.HiddenMemoryWatchers = new MemoryWatcherList();
  G.CodeMemoryWatchers = new MemoryWatcherList();

  // Initial Run values
  R.CompletedSplits = new Dictionary<string, bool>();
  R.LatestSplits = new Stack<string>();
  R.ActiveWatchCodes = new HashSet<string>();
  R.CurrentLocations = new HashSet<string>();
  R.CurrentProgress = new HashSet<string>();
  R.AnyPercentRoute = false;
  R.EscapeRadarTimes = 0;
  R.VrSplitOnExit = false;
  
  // Initialise structure for split watchers and checkers
  F.Watch = new Dictionary<string, Func<int>>();
  F.Check = new Dictionary<string, Func<bool>>();
  
  
  /****************************************************/
  /* startup: Sets definitions
  /****************************************************/
  
  // Sets of progress values that can represent the same point in the game
  // These names can be used in signatures (in place of progress) to cover multiple values
  // Mostly used for PC where progress can change repeatedly hella fast
  var progressSets = new Dictionary<string, short[]>() {
    // (value[n] == -1) -> next 2 are a progress range
    { "ReachDarpaChief",  new short[] { -1, 19, 24 } },
    { "VentClip",         new short[] { 18, 158 } },
    { "AfterOcelot",      new short[] { -1, 52, 64 } },
    { "ReachNinja",       new short[] { -1, 75, 77 } },
    { "ReachUgPassage",   new short[] { -1, 141, 143 } },
    { "ABEscape",         new short[] { 163 } },
    { "AfterEscape",      new short[] { -1, 163, 173 } },
    { "DefeatCTAChase",   new short[] { -1, 163, 174 } },
    { "CommTowerB",       new short[] { -1, 180, 183, -1, 190, 195 } },
    { "BeforeHind",       new short[] { -1, 180, 183 } },
    { "ReachHind",        new short[] { 185, 186 } },
    { "AfterHind",        new short[] { -1, 190, 194 } },
    { "ReachRaven",       new short[] { -1, 207, 211 } },
    { "AfterRaven",       new short[] { -1, 217, 219 } },
    { "ReachCommandRoom", new short[] { -1, 225, 237 } },
    { "HeatingKey",       new short[] { -1, 242, 246 } },
  };
  D.Sets.Progress = new Dictionary<short, List<string>>();
  var pSet = D.Sets.Progress;
  foreach (var p in progressSets) {
    int count = p.Value.Length;
    for (int i = 0; i < count; i++) {
      var v = p.Value[i];
      if (v == -1) {
        for (short j = p.Value[i + 1]; j <= p.Value[i + 2]; j++) {
          if (!pSet.ContainsKey(j)) pSet.Add(j, new List<string>());
          pSet[j].Add(p.Key);
        }
        i += 3;
      }
      if (!pSet.ContainsKey(v)) pSet.Add(v, new List<string>());
      pSet[v].Add(p.Key);
    }
  }
  
  // Sets of locations, again for use in signatures
  // Some are used as PC catch-alls (same as for progress)
  // Others cover different ways to get to the same place (e.g. elevators with 3 floors)
  var locationSets = new Dictionary<string, string[]>() {
    { "Heliport",     new string[] { "d00a", "s01a", "d01a" } },
    { "TankHangar",   new string[] { "s02a", "s02c", "s02e", "s03a", "s04a" } },
    { "NukeBuilding", new string[] { "s06a", "s07a", "s08a" } },
    { "Snowfield",    new string[] { "s12b", "s12c", "change" } },
  };
  D.Sets.Location = new Dictionary<string, string>();
  foreach (var l in locationSets) {
    foreach (var m in l.Value) D.Sets.Location.Add(m, l.Key);
  }
  
  // Split modifiers { <modifier>, <original> }
  // These are in the Split Modifiers section of settings
  // If both <modifier> and <original> are enabled, <original>'s split point will be disabled
  // and <modifier> will become an active split point
  D.Sets.SplitModifiers = new Dictionary<string, string>() {
    { "CP-7", "OL-s00a" },
    { "CP-153", "CP-157" },
    { "CP-163", "OL-s03c.CL-s03a.CP-163" },
    { "CP-178", "OL-s11g.CL-s11d" },
    { "CP-179", "OL-s11d.CL-s11i" },
  };
  
  // Memory addresses (relative to the start of PSX memory 0x000000 to 0x1FFFFF)
  // for each PSX version of the game
  D.Sets.PSXAddresses = new Dictionary<string, Dictionary<string, int>>() {
    // JP
    { "SLPM-86111", new Dictionary<string, int>() {
      { "Alerts",           0xB581C },
      { "Kills",            0xB581E },
      { "RationsUsed",      0xB582C },
      { "Continues",        0xB582E },
      { "Saves",            0xB5830 },
      { "GameTime",         0xAC2D8 },
      { "Difficulty",       0xB577C },
      { "Progress",         0xB46BA },
      { "Location",         0xABCEC },
      { "NoControl",        0xABCF7 },
      { "InMenu",           0xAC806 },
      { "VsRex",            0xC0EB8 },
      { "ControllerInput",  0xAC240 },
      { "Frames",           0xABC58 },
      { "WeaponData",       0xB57A0 },
      { "ItemData",         0xB57CA }, // todo test
      { "ElevatorTimer",    0x163B28 },
      { "OcelotHP",         0x167910 },
      { "NinjaHP",          0x15AC8C },
      { "MantisHP",         0x16C7A8 },
      { "Wolf1HP",          0x1747B4 },
      { "HindHP",           0x153FA8 },
      { "Wolf2HP",          0x171148 },
      { "RavenHP",          0x15779C },
      { "Rex1HP",           0x15E10C },
      { "Rex2HP",           0x15F414 },
      { "LiquidHP",         0x17A424 },
      { "EscapeHP",         0xB710E },
      { "RadarState",       0xABCF5 },
      { "ScoreState",       0xADB12 },
      { "O2Timer",          0xAC324 },
      { "ChaffTimer",       0xBE968 },
      { "DiazepamTimer",    0xB5812 },
      { "Life",             0xB5796 },
      { "MaxLife",          0xB5798 },
      { "EquippedItem",     0xB579E },
    } },
    // JP Integral
    { "SLPM-86247", new Dictionary<string, int>() {
      { "Alerts",           0xB4E34 },
      { "Kills",            0xB4E36 },
      { "RationsUsed",      0xB4E44 },
      { "Continues",        0xB4E46 },
      { "Saves",            0xB4E48 },
      { "GameTime",         0xAB9E8 },
      { "Difficulty",       0xB4D9A },
      { "Progress",         0xB3CD2 },
      { "Location",         0xAB3C4 },
      { "NoControl",        0xAB3CF },
      { "InMenu",           0xABDFC },
      { "VsRex",            0xC04F8 },
      { "ControllerInput",  0xAB950 },
      { "Frames",           0xAB330 },
      { "WeaponData",       0xB4DB8 },
      { "ItemData",         0xB4DE2 },
      { "ElevatorTimer",    0x1636D8 },
      { "OcelotHP",         0x1682DC },
      { "NinjaHP",          0x15BD30 },
      { "MantisHP",         0x16D280 },
      { "MantisMaxHP",      0xC3390 },
      { "Wolf1HP",          0x173484 },
      { "HindHP",           0x154E0C },
      { "Wolf2HP",          0x170204 },
      { "RavenHP",          0x157A1C },
      { "RavenMaxHP",       0xB40F0 },
      { "Rex1HP",           0x15E630 },
      { "RexMaxHP",         0xB40F6 },
      { "Rex2HP",           0x15F948 },
      { "LiquidHP",         0x179A54 },
      { "EscapeHP",         0xB6746 },
      { "RadarState",       0xAB3CD },
      { "ScoreState",       0xAD22A },
      { "O2Timer",          0xABA34 },
      { "ChaffTimer",       0xBDFA0 },
      { "DiazepamTimer",    0xB4E2A },
      { "Life",             0xB4DAE },
      { "MaxLife",          0xB4DB0 },
      { "EquippedItem",     0xB4DB6 },
    } },
    // JP VR
    { "SLPM-86249", new Dictionary<string, int>() {
      { "Location",         0xA9018 },
      { "Score",            0xE2FC4 },
      { "LevelState",       0xE2FC8 },
      { "Frames",           0xA8F84 },
    } },
    // US
    { "SLUS-00594", new Dictionary<string, int>() {
      { "Alerts",           0xB75B4 },
      { "Kills",            0xB75B6 },
      { "RationsUsed",      0xB75C4 },
      { "Continues",        0xB75C6 },
      { "Saves",            0xB75C8 },
      { "GameTime",         0xAE168 },
      { "Difficulty",       0xB751A },
      { "Progress",         0xB6452 },
      { "Location",         0xADB3C },
      { "NoControl",        0xADB47 },
      { "InMenu",           0xD2841 }, // maybe D2991, D2BD9, D2D89...
      { "VsRex",            0xC2C60 },
      { "ControllerInput",  0xAE0D0 },
      { "Frames",           0xADA50 },
      { "WeaponData",       0xB7538 },
      { "ItemData",         0xB7562 },
      { "ElevatorTimer",    0x162304 },
      { "OcelotHP",         0x168168 },
      { "NinjaHP",          0x15B59C },
      { "MantisHP",         0x16CFFC },
      { "MantisMaxHP",      0xC5AF0 },
      { "Wolf1HP",          0x173DEC },
      { "HindHP",           0x154ECD4 },
      { "Wolf2HP",          0x1701BC },
      { "RavenHP",          0x157408 },
      { "RavenMaxHP",       0xB6970 },
      { "Rex1HP",           0x15E5A8 },
      { "RexMaxHP",         0xB6876 },
      { "Rex2HP",           0x15F8B0 },
      { "LiquidHP",         0x17997C },
      { "EscapeHP",         0xB8EAE },
      { "RadarState",       0xADB45 },
      { "ScoreState",       0xAF9AA },
      { "O2Timer",          0xAE1B4 },
      { "ChaffTimer",       0xC0710 },
      { "DiazepamTimer",    0xB75AA },
      { "Life",             0xB752E },
      { "MaxLife",          0xB7530 },
      { "EquippedItem",     0xB7536 },
    } },
    // US VR
    { "SLUS-00957", new Dictionary<string, int>() {
      { "Location",         0xAC1DC },
      { "Score",            0xB4A44 },
      { "LevelState",       0xB4A48 },
      { "Frames",           0xAC148 },
    } },
    // EU
    { "SLES-01370", new Dictionary<string, int>() {
      { "Alerts",           0xB5E8C },
      { "Kills",            0xB5E8E },
      { "RationsUsed",      0xB5E9C },
      { "Continues",        0xB5E9E },
      { "Saves",            0xB5EA0 },
      { "GameTime",         0xACA40 },
      { "Difficulty",       0xB5DF2 },
      { "Progress",         0xB4D2A },
      { "Location",         0xAC430 },
      { "NoControl",        0xAC43B },
      { "InMenu",           0xD0F42 }, // todo test
      { "VsRex",            0xC1538 },
      { "ControllerInput",  0xAC9A8 },
      { "Frames",           0xAC39C },
      { "WeaponData",       0xB5E10 },
      { "ItemData",         0xB5E3A },
      { "ElevatorTimer",    0x1622F4 },
      { "OcelotHP",         0x168168 },
      { "NinjaHP",          0x15B6BC },
      { "MantisHP",         0x16D01C },
      { "MantisMaxHP",      0xC43D0 },
      { "Wolf1HP",          0x1737A8 },
      { "HindHP",           0x154CD4 },
      { "Wolf2HP",          0x1701BC },
      { "RavenHP",          0x157408 },
      { "RavenMaxHP",       0xB5148 },
      { "Rex1HP",           0x15E5A8 },
      { "RexMaxHP",         0xB514E },
      { "Rex2HP",           0x15F8B0 },
      { "LiquidHP",         0x17997C },
      { "EscapeHP",         0xB778E },
      { "RadarState",       0xAC439 },
      { "ScoreState",       0xAE282 },
      { "O2Timer",          0xACA8C },
      { "ChaffTimer",       0xBEFE8 },
      { "DiazepamTimer",    0xB5E82 },
      { "Life",             0xB5E06 },
      { "MaxLife",          0xB5E08 },
      { "EquippedItem",     0xB5E0E },
    } },
    // EU VR
    { "SLES-02136", new Dictionary<string, int>() {
      { "Location",         0xAC444 },
      { "Score",            0xB4CAC },
      { "LevelState",       0xB4CB0 },
      { "Frames",           0xAC3B0 },
    } },
  };
  
  // Split set fragments - will be used later to create split sets
  D.Sets.Split = new Dictionary<string, List<string>>() {
    { "EarlyGame", new List<string>() {
      "OL-s00a", "OL-s01a.CL-s02a.CP-18", "OL-TankHangar.CL-s03a.CP-18",
    } },
    { "Any", new List<string>() {
      "OL-s03a.CL-s03c.CP-VentClip", "OL-s03b.CL-s03c", "OL-s03c.CL-s03a.CP-163", "OL-TankHangar.CL-s04a.CP-163", "OL-TankHangar.CL-s02e.CP-163",
    } },
    { "AllBosses", new List<string> () {
      "W.CL-s03a.CP-18", "CP-ReachDarpaChief", "OP-26", "OP-28", "CL-s04a.CP-36", "CL-s04b.CP-36", "OP-36", "OP-38", "OL-s04c.CL-s04a.CP-52", "OL-TankHangar.CL-s02c.CP-AfterOcelot", "CL-s05a.CP-AfterOcelot", "CP-65", "OP-66", "CL-s07a.CP-69", "CL-s08a.CP-69", "CL-s08c.CP-69", "CL-s08b.CP-ReachNinja", "OP-77", "OL-s08b.CL-s08c.CP-111", "OL-s08c.CL-s08a.CP-111", "CL-s07a.CP-111", "CP-112", "OL-s07c.CL-s07b.CP-119", "OP-125", "CP-133", "OL-s07b.CL-s09a.CP-137", "OL-s09a.CL-s10a.CP-ReachUgPassage", "CP-146", "OL-s10a.CL-s09a.CP-149", "OL-s09a.CL-s07b.CP-149", "OL-s07b.CL-s07a.CP-150", "OL-NukeBuilding.CL-s06a.CP-150", "OL-s06a.CL-s05a.CP-150", "OL-s05a.CL-s02e.CP-150", "OL-TankHangar.CL-s04a.CP-150", "OL-TankHangar.CL-s02e.CP-150", "OL-s02e.CL-s05a.CP-150", "OL-s05a.CL-s06a.CP-150", "OL-NukeBuilding.CL-s07a.CP-150", "OL-s07a.CL-s07b.CP-150", "OL-s07b.CL-s09a.CP-150", "OL-s09a.CL-s10a.CP-150", "OP-150", "CP-157", "OL-s03b.CL-s03c", "OL-s03c.CL-s03a.CP-163", "OL-TankHangar.CL-s02e.CP-ABEscape",
    } },
    { "ToCommsTowers", new List<string>() {
      "OL-s02e.CL-s05a.CP-163", "OL-s05a.CL-s06a.CP-163", "OL-NukeBuilding.CL-s07a.CP-163", "OL-s07a.CL-s07b.CP-163", "OL-s07b.CL-s09a.CP-163", "OL-s09a.CL-s10a.CP-163", "OL-s10a.CL-s11a.CP-AfterEscape", "OL-s11a.CL-s11b.CP-DefeatCTAChase"
    } },
    { "CommTowerA-Rappel", new List<string>() {
      "OL-s11g.CL-s11d", "OL-s11d.CL-s11i"
    } },
    { "Walkway", new List<string>() { "OL-s11i.CL-s11c.CP-180" } },
    { "CommTowerB-CAny", new List<string>() {
      "OL-s11c.CL-s11h.CP-BeforeHind", "OL-s11h.CL-s11c.CP-CommTowerB",
    } },
    { "CommTowerB-AB", new List<string>() {
      "OL-s11c.CL-s11h.CP-BeforeHind", "CP-ReachHind", "OP-186", "OL-s11h.CL-s11c.CP-CommTowerB",
    } },
    { "CommTowerB-Glitchless", new List<string>() {
      "OL-s11c.CL-s11e.CP-AfterHind", "CP-195"
    } },
    { "ToWolf2", new List<string>() {
      "OL-s11c.CL-s12a.CP-CommTowerB", "CP-197", "OP-197",
    } },
    { "Stinger-CAny", new List<string>() {
      "OL-Snowfield.CL-s11c.CP-204", "OL-s11c.CL-s11i.CP-204", "OL-s11i.CL-s11c.CP-204", "OL-s11c.CL-Snowfield.CP-204",
    } },
    { "DiscChange", new List<string>() { "OL-s12b.CL-change.CP-204" } },
    { "Disc2", new List<string>() {
      "OL-Snowfield.CL-s13a.CP-204", "OL-s13a.CL-s14e.CP-204", "CP-206", "CP-207", "OL-s14e.CL-s15a.CP-ReachRaven", "OP-211", "OL-s15a.CL-s15b.CP-AfterRaven", "OL-s15b.CL-s16a.CP-AfterRaven", "OL-s16a.CL-s16b.CP-221", "OL-s16b.CL-s16c.CP-223", "OL-s16c.CL-s16d.CP-ReachCommandRoom", "OL-s16d.CL-s16c.CP-ReachCommandRoom", "OL-s16c.CL-s16b.CP-237", "OL-s16b.CL-s16a.CP-237", "OL-s16a.CL-s16b.CP-238", "OL-s16b.CL-s16c.CP-238",  "OL-s16c.CL-s16d.CP-238", "OP-238", "OL-s16d.CL-s16c.CP-240", "OL-s16c.CL-s16b.CP-240", "OL-s16b.CL-s16a.CP-240", "OL-s16a.CL-s15b.CP-240", "OL-s15b.CL-s15a.CP-240", "OL-s15a.CL-s15b.CP-240", "OL-s15b.CL-s16a.CP-240", "OL-s16a.CL-s16b.CP-240", "OL-s16b.CL-s16c.CP-240", "OL-s16c.CL-s16d.CP-240", "OP-240", "OL-s16d.CL-s16c.CP-242", "OL-s16c.CL-s16b.CP-242", "OL-s16b.CL-s16a.CP-242", "OL-s16a.CL-s15b.CP-242", "OL-s15b.CL-s15c.CP-242", "OL-s15c.CL-s14e.CP-242", "OL-s14e.CL-s13a.CP-HeatingKey", "OL-s13a.CL-s14e.CP-HeatingKey", "OL-s14e.CL-s15c.CP-HeatingKey", "OL-s15c.CL-s15b.CP-HeatingKey", "OL-s15b.CL-s16a.CP-HeatingKey", "OL-s16a.CL-s16b.CP-HeatingKey", "OL-s16b.CL-s16c.CP-HeatingKey", "OL-s16c.CL-s16d.CP-HeatingKey", "CP-247", "OL-s16d.CL-d16e", "CP-252", "W.CP-255", "W.CP-257", "OP-277", "OL-s19a.CL-s19b", "CP-286", "W.CP-294",
    } },
  };
  
  D.Sets.AllSplits = new HashSet<string>();
  
  // Split sets for each category - uses the fragments above
  // These are used when building split files from current settings
  D.Sets.Category = new Dictionary<string, List<string>>() {
    { "PC All Bosses", new List<string>() {
      "EarlyGame", "AllBosses", "ToCommsTowers", "CommTowerA-Rappel", "Walkway", "CommTowerB-AB", "ToWolf2", "Disc2"
    } },
    { "Console All Bosses", new List<string>() {
      "EarlyGame", "AllBosses", "ToCommsTowers", "CommTowerA-Rappel", "Walkway", "CommTowerB-AB", "CommTowerB-Glitchless", "ToWolf2", "DiscChange", "Disc2"
    } },
    { "PC Any%", new List<string>() {
      "EarlyGame", "Any", "ToCommsTowers", "CommTowerA-Rappel", "Walkway", "ToWolf2", "Disc2"
    } },
    { "Console Any%", new List<string>() {
      "EarlyGame", "Any", "ToCommsTowers", "CommTowerA-Rappel", "Walkway", "CommTowerB-CAny", "ToWolf2", "DiscChange", "Stinger-CAny", "Disc2",
    } },
    { "PC Glitchless", new List<string>() {
      "EarlyGame", "AllBosses", "ToCommsTowers", "CommTowerA-Rappel", "Walkway", "CommTowerB-AB", "CommTowerB-Glitchless", "ToWolf2", "Disc2"
    } },
  };
  
  // How fast O2 drops in each area. 4096 is equivalent to 1/frame
  D.Sets.O2Rates = new Dictionary<string, int>() {
    { "s00a", 2048 },
    { "s02a", 8192 },
    { "s02c", 16384 }, // Technically you can backtrack to the rat poison, but for simplicity...
    { "s06a", 19200 },
    { "s08a", 3072 },
    { "s16a", 2048 },
    { "s16d", 8192 },
    { "s16d-ambush", 3000 },
  };

  // How much (as a divisor) the Gas Mask slows O2 loss
  D.Sets.O2MaskDivisors = new Dictionary<string, int>() {
    { "s00a", 8 },
    { "s02c", 8 },
    { "s06a", 16 },
    { "s08a", 4 },
    { "s16d", 2 },
  };

  
  /****************************************************/
  /* startup: Friendly name definitions
  /****************************************************/
  
  // Split names - used when generating split files & when splitting in debug
  D.Names.Split = new Dictionary<string, string>() {
    { "OL-s00a", "Dock" },
    { "OL-s01a.CL-s02a.CP-18", "Heliport" },
    { "OL-TankHangar.CL-s03a.CP-18", "Tank Hangar" },
    { "OL-s03a.CL-s03c.CP-VentClip", "Cell" },
    { "M.OL-s03a.CL-s03c.CP-VentClip", "{Vent Clip}Cell" },
    { "W.CL-s03a.CP-18", "Cell" },
    { "CP-ReachDarpaChief", "DARPA Chief" },
    { "OP-26", "Cell" },
    { "OP-28", "Guard Encounter" },
    { "CL-s04a.CP-36", "Cell" },
    { "CL-s04b.CP-36", "Armory" },
    { "OP-36", "Armory South" },
    { "OP-38", "Revolver Ocelot" },
    { "OL-s04c.CL-s04a.CP-52", "Armory South" },
    { "OL-TankHangar.CL-s02c.CP-AfterOcelot", "Armory" },
    { "CL-s05a.CP-AfterOcelot", "Tank Hangar" },
    { "CP-65", "Canyon" },
    { "OP-66", "M1 Tank" },
    { "CL-s07a.CP-69", "Nuke Building 1F" },
    { "CL-s08a.CP-69", "Nuke Building B1" },
    { "CL-s08c.CP-69", "Nuke Building B2" },
    { "CL-s08b.CP-ReachNinja", "Lab Hallway" },
    { "OP-77", "Ninja" },
    { "OL-s08b.CL-s08c.CP-111", "Lab" },
    { "OL-s08c.CL-s08a.CP-111", "Lab Hallway" },
    { "CL-s07a.CP-111", "Nuke Building B2" },
    { "CP-112", "Meryl" },
    { "OL-s07c.CL-s07b.CP-119", "Nuke Building B1" },
    { "OP-125", "Commander's Room" },
    { "CP-133", "Psycho Mantis" },
    { "OL-s07b.CL-s09a.CP-137", "Commander's Room" },
    { "OL-s09a.CL-s10a.CP-ReachUgPassage", "Cave" },
    { "CP-146", "Underground Passage Ambush" },
    { "OL-s10a.CL-s09a.CP-149", "Underground Passage" },
    { "OL-s09a.CL-s07b.CP-149", "Cave" },
    { "OL-s07b.CL-s07a.CP-150", "Commander's Room" },
    { "OL-NukeBuilding.CL-s06a.CP-150", "Nuke Building B1" },
    { "OL-s06a.CL-s05a.CP-150", "Nuke Building 1F" },
    { "OL-s05a.CL-s02e.CP-150", "Canyon" },
    { "OL-TankHangar.CL-s04a.CP-150", "Tank Hangar" },
    { "OL-TankHangar.CL-s02e.CP-150", "Armory" },
    { "M.OL-TankHangar.CL-s02e.CP-150", "{PSG1}Armory" },
    { "OL-s02e.CL-s05a.CP-150", "Tank Hangar" },
    { "OL-s05a.CL-s06a.CP-150", "Canyon" },
    { "OL-NukeBuilding.CL-s07a.CP-150", "Nuke Building 1F" },
    { "OL-s07a.CL-s07b.CP-150", "Nuke Building B1" },
    { "OL-s07b.CL-s09a.CP-150", "Commander's Room" },
    { "OL-s09a.CL-s10a.CP-150", "Cave" },
    { "OP-150", "Sniper Wolf 1" },
    { "CP-157", "Underground Passage" },
    { "OL-s03b.CL-s03c", "Torture" },
    { "OL-s03c.CL-s03a.CP-163", "Medi Room" },
    { "M.OL-s03c.CL-s03a.CP-163", "{Escape}Medi Room" },
    { "OL-TankHangar.CL-s04a.CP-163", "Cell" }, // to Armory (Any%)
    { "OL-TankHangar.CL-s02e.CP-163", "Armory" },
    { "M.OL-TankHangar.CL-s02e.CP-163", "{PSG1}Armory" },
    { "OL-TankHangar.CL-s02e.CP-ABEscape", "Cell" }, // to Tank Hangar (AB)
    { "OL-s02e.CL-s05a.CP-163", "Tank Hangar" },
    { "OL-s05a.CL-s06a.CP-163", "Canyon" },
    { "OL-NukeBuilding.CL-s07a.CP-163", "Nuke Building 1F" },
    { "OL-s07a.CL-s07b.CP-163", "Nuke Building B1" },
    { "OL-s07b.CL-s09a.CP-163", "Commander's Room" },
    { "OL-s09a.CL-s10a.CP-163", "Cave" },
    { "OL-s10a.CL-s11a.CP-AfterEscape", "Underground Passage" },
    { "OL-s11a.CL-s11b.CP-DefeatCTAChase", "Comms Tower A" },
    { "M.OL-s11a.CL-s11b.CP-DefeatCTAChase", "{Stairs Chase}Comms Tower A" },
    { "OL-s11g.CL-s11d", "Comms Tower A Roof" },
    { "OL-s11d.CL-s11i", "Comms Tower A Wall" },
    { "M.OL-s11d.CL-s11i", "Rappel" },
    { "OL-s11i.CL-s11c.CP-180", "Walkway" },
    { "OL-s11c.CL-s11h.CP-BeforeHind", "Comms Tower B" }, // (AB/Console Any%)
    { "CP-ReachHind", "Comms Tower B Roof" }, // to Hind (AB)
    { "OP-186", "Hind D" },
    { "OL-s11h.CL-s11c.CP-CommTowerB", "Comms Tower B Roof" }, // back (AB/Console Any%)
    { "OL-s11c.CL-s11e.CP-AfterHind", "Comms Tower B" }, // to elevator (Console AB)
    { "CP-195", "Guard Encounter" }, // (Console AB)
    { "OL-s11c.CL-s12a.CP-CommTowerB", "Comms Tower B" },
    { "CP-197", "Snowfield" },
    { "OP-197", "Sniper Wolf 2" },
    { "OL-Snowfield.CL-s11c.CP-204", "Snowfield" }, // to CTB (Console Any%)
    { "OL-s11c.CL-s11i.CP-204", "Comms Tower B" },
    { "OL-s11i.CL-s11c.CP-204", "Walkway" },
    { "OL-s11c.CL-Snowfield.CP-204", "Comms Tower B" },
    { "OL-s12b.CL-change.CP-204", "Disc Change" }, // Console only
    { "OL-Snowfield.CL-s13a.CP-204", "Snowfield" },
    { "OL-s13a.CL-s14e.CP-204", "Blast Furnace" },
    { "CP-206", "Cargo Elevator" },
    { "CP-207", "Guard Encounter" },
    { "OL-s14e.CL-s15a.CP-ReachRaven", "Cargo Elevator" },
    { "OP-211", "Vulcan Raven" },
    { "OL-s15a.CL-s15b.CP-AfterRaven", "Warehouse" },
    { "OL-s15b.CL-s16a.CP-AfterRaven", "Warehouse North" },
    { "OL-s16a.CL-s16b.CP-221", "Underground Base 1" },
    { "OL-s16b.CL-s16c.CP-223", "Underground Base 2" },
    { "OL-s16c.CL-s16d.CP-ReachCommandRoom", "Underground Base 3" },
    { "OL-s16d.CL-s16c.CP-ReachCommandRoom", "Command Room" },
    { "OL-s16c.CL-s16b.CP-237", "Underground Base 3" },
    { "OL-s16b.CL-s16a.CP-237", "Underground Base 2" },
    { "OL-s16a.CL-s16b.CP-238", "Underground Base 1" },
    { "M.OL-s16a.CL-s16b.CP-238", "{PAL Key}Underground Base 1" },
    { "OL-s16b.CL-s16c.CP-238", "Underground Base 2" },
    { "OL-s16c.CL-s16d.CP-238", "Underground Base 3" },
    { "OP-238", "Normal PAL Key" },
    { "OL-s16d.CL-s16c.CP-240", "Command Room" },
    { "M.OL-s16d.CL-s16c.CP-240", "{Normal PAL Key}Command Room" },
    { "OL-s16c.CL-s16b.CP-240", "Underground Base 3" },
    { "OL-s16b.CL-s16a.CP-240", "Underground Base 2" },
    { "OL-s16a.CL-s15b.CP-240", "Underground Base 1" },
    { "OL-s15b.CL-s15a.CP-240", "Warehouse North" },
    { "M.OL-s15b.CL-s15a.CP-240", "{Enter Warehouse}Warehouse North" },
    { "OL-s15a.CL-s15b.CP-240", "Warehouse" },
    { "OL-s15b.CL-s16a.CP-240", "Warehouse North" },
    { "OL-s16a.CL-s16b.CP-240", "Underground Base 1" },
    { "OL-s16b.CL-s16c.CP-240", "Underground Base 2" },
    { "OL-s16c.CL-s16d.CP-240", "Underground Base 3" },
    { "OP-240", "Cold PAL Key" },
    { "OL-s16d.CL-s16c.CP-242", "Command Room" },
    { "M.OL-s16d.CL-s16c.CP-242", "{Cold PAL Key}Command Room" },
    { "OL-s16c.CL-s16b.CP-242", "Underground Base 3" },
    { "OL-s16b.CL-s16a.CP-242", "Underground Base 2" },
    { "OL-s16a.CL-s15b.CP-242", "Underground Base 1" },
    { "OL-s15b.CL-s15c.CP-242", "Warehouse North" },
    { "OL-s15c.CL-s14e.CP-242", "Warehouse" },
    { "OL-s14e.CL-s13a.CP-HeatingKey", "Cargo Elevator" },
    { "M.OL-s14e.CL-s13a.CP-HeatingKey", "{Enter Blast Furnace}Cargo Elevator" },
    { "OL-s13a.CL-s14e.CP-HeatingKey", "Blast Furnace" },
    { "OL-s14e.CL-s15c.CP-HeatingKey", "Cargo Elevator" },
    { "OL-s15c.CL-s15b.CP-HeatingKey", "Warehouse" },
    { "OL-s15b.CL-s16a.CP-HeatingKey", "Warehouse North" },
    { "OL-s16a.CL-s16b.CP-HeatingKey", "Underground Base 1" },
    { "OL-s16b.CL-s16c.CP-HeatingKey", "Underground Base 2" },
    { "OL-s16c.CL-s16d.CP-HeatingKey", "Underground Base 3" },
    { "CP-247", "Hot PAL Key" },
    { "OL-s16d.CL-d16e", "Command Room" },
    { "M.OL-s16d.CL-d16e", "{Hot PAL Key}Command Room" },
    { "CP-252", "Underground Base 3" },
    { "W.CP-255", "Metal Gear REX (Phase 1)" },
    { "W.CP-257", "Metal Gear REX" },
    { "OP-277", "Liquid Snake" },
    { "OL-s19a.CL-s19b", "Escape Route 1" },
    { "CP-286", "Escape" },
    { "M.CP-286", "{Escape}Escape Route 2" },
    { "W.CP-294", "Score" },
  };
  
  D.Names.SplitSetting = new Dictionary<string, string>();
  
  // Names of PSX versions of the game according to product code
  D.Names.PSXVersion = new Dictionary<string, string>() {
    { "SLPM-86111", "Metal Gear Solid (JP)" },
    { "SLPM-86247", "MGS Integral (JP)" },
    { "SLPM-86249", "MGS Integral VR-Disc (JP)" },
    { "SLUS-00594", "Metal Gear Solid (US)" },
    { "SLUS-00957", "MGS VR Missions (US)" },
    { "SLES-01370", "Metal Gear Solid (EU)" },
    { "SLES-02136", "MGS Special Missions (EU)" },
  };
  
  // Location names for [vars.Location] according to the Location memory value
  // First character [sd] not included, last character only used when it varies
  D.Names.Location = new Dictionary<string, string>() {
    { "00",  "Dock" },
    { "01",  "Heliport" },
    { "02",  "Tank Hangar" },
    { "03a", "Cell" },
    { "03b", "Medi Room" },
    { "03c", "Medi Room" },
    { "03d", "Cell" },
    { "04a", "Armory" },
    { "04b", "Armory South" },
    { "04c", "Armory South" },
    { "05",  "Canyon" },
    { "06",  "Nuke Building 1F" },
    { "07a", "Nuke Building B1"},
    { "07b", "Commander's Room" },
    { "07c", "Nuke Building B1"},
    { "08a", "Nuke Building B2" },
    { "08b", "Lab" },
    { "08c", "Lab Hallway" },
    { "09",  "Cave" },
    { "10",  "Underground Passage" },
    { "11a", "Comms Tower A" },
    { "11b", "Comms Tower A Roof" },
    { "11c", "Comms Tower B" },
    { "11d", "Comms Tower A Wall" },
    { "11e", "Comms Tower B Elevator" },
    { "11g", "Comms Tower A Roof" },
    { "11h", "Comms Tower B Roof" },
    { "11i", "Walkway" },
    { "12",  "Snowfield" },
    { "13",  "Blast Furnace" },
    { "14",  "Cargo Elevator" },
    { "15a", "Warehouse" },
    { "15b", "Warehouse North" },
    { "15c", "Warehouse" },
    { "16a", "Underground Base 1" },
    { "16b", "Underground Base 2" },
    { "16c", "Underground Base 3" },
    { "16d", "Command Room" },
    { "16e", "Underground Base 3" },
    { "17",  "Supply Route" },
    { "18",  "Supply Route" },
    { "19a", "Escape Route 1" },
    { "19b", "Escape Route 2" }, 
  };
  
  // Weapon names - used in debug when checkers require a weapon
  D.Names.Weapon = new Dictionary<int, string>() {
    { 0,  "" },
    { 1,  "SOCOM" },
    { 2,  "FA-MAS" },
    { 3,  "Grenade" },
    { 4,  "Nikita" },
    { 5,  "Stinger" },
    { 6,  "Claymore" },
    { 7,  "C4" },
    { 8,  "Stun Grenade" },
    { 9,  "Chaff Grenade" },
    { 10, "PSG-1" },
  };
  
  // Item names - used in debug when checkers require an item
  D.Names.Item = new Dictionary<int, string>() {
    { 0, "Cigs" },
    { 1, "Scope" },
    { 2, "Box A" },
    { 3, "Box B" },
    { 4, "Box C" },
    { 5, "NVG" },
    { 6, "Thermal Goggles" },
    { 7, "Gas Mask" },
    { 8, "Body Armor" },
    { 9, "Ketchup" },
    { 10, "Stealth" },
    { 11, "Bandana" },
    { 12, "Camera" },
    { 13, "Ration" },
    { 14, "Medicine" },
    { 15, "Diazepam" },
    { 16, "PAL Key" },
    { 17, "Card" },
    { 18, "Time Bomb" },
    { 19, "Mine Detector" },
    { 20, "MO Disk" },
    { 21, "Rope" },
    { 22, "Handkerchief" },
    { 23, "Suppressor" },
  };
  
  
  /****************************************************/
  /* startup: Helper function definitions
  /****************************************************/
  
  // Outputs <message> to Windows stdout
  // Replaced with a more capable version in init
  F.Debug = (Action<string>)((message) => {
    print("[MGS1] " + message);
  });
  
  // Writes runtime errors to the error log (with a 5 sec cooldown)
  // Replaced with a more capable version in init
  F.EventLogWritten = new EntryWrittenEventHandler((Action<object, EntryWrittenEventArgs>)((sender, e) => {
    var entry = e.Entry;
    if ( entry.Source.Equals("LiveSplit") && entry.EntryType.Equals("Error") ) {
      if ( (entry.TimeGenerated - V.LastError).Seconds > 4 ) {
        V.LastError = DateTime.Now;
        string message = string.Format("[Error at {0}] {1}",
            V.LastError.ToString("T"), entry.Message);
        F.WriteFile(V.DebugLogFile, message, true);
      }
    }
  }));
  V.EventLog = new EventLog("Application");
  V.EventLog.EnableRaisingEvents = true;
  V.EventLog.EntryWritten += F.EventLogWritten;
  
  // Reset all run-related variables when the LiveSplit timer is reset
  F.TimerOnReset = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((sender, e) => {
    F.ResetRunVars();
  });
  timer.OnReset += F.TimerOnReset;
  
  // Reinitialise the location/progress state and FPS log when the LiveSplit timer starts
  F.TimerOnStart = (EventHandler)((sender, e) => {
    if (!G.VRMissions) F.SetStateCodes();
    G.FpsLog.Clear();
  });
  timer.OnStart += F.TimerOnStart;
  
  // Returns pretty name of a Location, given the location <code>
  F.LocationName = (Func<string, string>)((code) => {
    if (code.Equals(String.Empty)) return String.Empty;
    code = code.Substring(1, 3);
    string name;
    if (!D.Names.Location.TryGetValue(code, out name)) {
      code = code.Substring(0, 2);
      if (!D.Names.Location.TryGetValue(code, out name)) return "";
    }
    return name;
  });
  
  // Resets the autosplitter and game/memory variables to an initial state
  F.ResetAllVars = (Action)(() => {
    V.ThisSecond = DateTime.Now.Second;
    V.LastSecond = V.ThisSecond;
    V.SecondIncremented = false;
    V.InfoTimeout = null;
    V.InfoPriority = -1;
    V.InfoFallback = String.Empty;
    vars.Platform = "None";
    vars.Version = "None";
    vars.FPS = String.Empty;
    vars.Info = String.Empty;
    vars.Location = String.Empty;
    vars.Stats = String.Empty;
    F.ResetGameVars();
  });
  
  // Resets the game variables and memory watchers to an initial state
  F.ResetGameVars = (Action)(() => {
    G.BaseAddress = IntPtr.Zero;
    G.OldBaseAddress = IntPtr.Zero;
    G.ProductCode = String.Empty;
    G.EU = false;
    G.JP = false;
    G.VRMissions = false;
    G.Emulator = true;
    G.Emulators.Clear();
    G.CurrentMemoryWatchers.Clear();
    G.HiddenMemoryWatchers.Clear();
    G.CodeMemoryWatchers.Clear();
    F.ResetMemoryVars();
  });
  
  // Resets the run variables to an initial state
  F.ResetRunVars = (Action)(() => {
    R.CompletedSplits = new Dictionary<string, bool>();
    R.ActiveWatchCodes = new HashSet<string>();
    R.CurrentLocations = new HashSet<string>();
    R.OldLocations = new HashSet<string>();
    R.CurrentProgress = new HashSet<string>();
    R.OldProgress = new HashSet<string>();
    R.EscapeRadarTimes = 0;
    R.VrSplitOnExit = false;
    R.LastBoss = String.Empty;
    V.ExceptionCount.Clear();
  });
  
  // Resets the memory watchers to the initial state for the current game
  F.ResetMemoryVars = (Action)(() => {
    M.Clear();
    M.AddRange(G.CurrentMemoryWatchers);
    M.AddRange(G.HiddenMemoryWatchers);
  });
  
  // Returns true if, in Dictionary <dict>, an entry with key <key> exists and is true
  F.DictIsTrue = (Func<Dictionary<string, bool>, string, bool>)((dict, key) =>
    ( (dict.ContainsKey(key)) && (dict[key]) ) );
  
  // Checks whether a split has already happened, then handles the paperwork
  // and returns true if the split block should itself return true
  F.Split = (Func<string, bool>)((code) => {
    string name = (D.Names.Split.ContainsKey(code)) ?
      " (" + F.StripSubsplitFormatting(D.Names.Split[code]) + ")" : "";
    if (R.CompletedSplits.ContainsKey(code)) {
      F.Debug("Repeat split for " + code + name);
      return false;
    }
    R.CompletedSplits.Add(code, true);
    R.LatestSplits.Push(code);
    if (F.SettingEnabled(code)) {
      F.Debug("Splitting for " + code + name);
      return true;
    }
    F.Debug(code + name + " not enabled, not splitting");
    return false;
  });
  
  // Trigger a split directly in LiveSplit and send <message> to debug
  F.ManualSplit = (Func<string, bool>)((message) => {
    V.TimerModel.Split();
    if (message != null) F.Debug(message);
    return false;
  });
  
  // Trigger a split undo in LiveSplit and send <message> to debug
  F.UndoSplit = (Func<string, bool>)((message) => {
    V.TimerModel.UndoSplit();
    if (message != null) F.Debug(message);
    return false;
  });

  // Trigger a split skip in liveSplit and send <message> to debug
  F.SkipSplit = (Func<string, bool>)((message) => {
    V.TimerModel.SkipSplit();
    if (message != null) F.Debug(message);
    return false;
  });
  
  // Return true if a controller button (or combination) is newly-pressed
  // Buttons: (0x1) L2 R2 L1 R1 T C X S Sel L3 R3 St U R D L (0x8000)
  F.ButtonPress = (Func<int, bool>)((mask) => (
    ((M["ControllerInput"].Current & mask) == mask) &&
    ((M["ControllerInput"].Old & mask) != mask) )
  );

  // Add memory address <offset> to the base address and return
  F.Addr = (Func<int, IntPtr>)((offset) => IntPtr.Add(G.BaseAddress, offset));
  
  // Increment the autosplitter's global iteration counter
  // and return true if a full second has passed
  F.Increment = (Func<bool>)(() => {
    V.i++;
    V.LastSecond = V.ThisSecond;
    V.ThisSecond = DateTime.Now.Second;
    V.SecondIncremented = (V.LastSecond != V.ThisSecond);
    return V.SecondIncremented;
  });
  
  // Returns the current (old if <useOld> == true) ammo
  // for weapon (item if <useItems> == true) <id> 
  F.AmmoCount = (Func<int, bool, bool, short>)((id, useItems, useOld) => {
    var type = useItems ? MM["ItemData"] : MM["WeaponData"];
    var names = useItems ? D.Names.Item : D.Names.Weapon;
    var data = useOld ? type.Old : type.Current;
    var key = (id * 2);
    var ammo = (short)((short)data[key] + ((short)data[key + 1] << 8));
    F.Debug(names[id] + " ammo: " + ammo);
    return ammo;
  });

  // Returns true if weapon <id> has 0 or more ammo
  F.HasWeapon = (Func<int, bool>)((id) => F.AmmoCount(id, false, false) != -1);
  
  // Ditto for item <id>
  F.HasItem = (Func<int, bool>)((id) => F.AmmoCount(id, true, false) != -1);

  // Returns a string-formatted number of seconds
  // given number of frames <frames>, at a rate of 30fps
  F.FramesToSeconds = (Func<int, string>)((frames) => string.Format("{0:F1}", (decimal) frames / F.FramesPerSecond()));
  
  // Returns the current game's target FPS (25 for EU, 30 for others)
  F.FramesPerSecond = (Func<int>)(() => G.EU ? 25 : 30);
  
  // Returns a formatted percentage "n%", given <numerator>/<denominator>
  F.Percentage = (Func<int, int, string>)((numerator, denominator) => {
    if (denominator == 0) return "0%";
    return (int)( ((decimal)numerator * 100) / denominator ) + "%";
  });
  
  // Returns true if <val> is between <low> and <high> (inclusive)
  F.Between = (Func<int, int, int, bool>)((val, low, high) =>
    ((val >= low) && (val <= high)) );
  
  // Wipes the main MemoryWatcher list
  // and repopulate it using the current game's current and hidden lists
  F.ResetActiveWatchers = (Action)(() => {
    M.Clear();
    M.AddRange(G.CurrentMemoryWatchers);
    M.AddRange(G.HiddenMemoryWatchers);
  });
  
  // Returns true if any stat value (Alerts/Kills/Saves/Continues/Rations) has changed
  F.StatsChanged = (Func<bool>)(() => (
    (M["Alerts"].Changed) || (M["Kills"].Changed) || (M["Saves"].Changed) ||
    (M["Continues"].Changed) || (M["RationsUsed"].Changed)
  ));
  
  // Writes a text file
  F.WriteFile = (Action<string, string, bool>)((file, content, append) => {
    string dir = Path.GetDirectoryName(file);
    if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
    using( System.IO.StreamWriter stream = 
      new System.IO.StreamWriter(file, append) ) {
      stream.WriteLine(content);
      stream.Close();
    }
  });
  
  // Opens an Explorer window pointing at <target>.
  // If <isFile> == true, <target> is a file that will be selected
  F.OpenExplorer = (Action<string, bool>)((target, isFile) => {
    string args = isFile ? string.Format("/e, /select, \"{0}\"", target) : target;
    ProcessStartInfo info = new ProcessStartInfo();
    info.FileName = "explorer";
    info.Arguments = args;
    Process.Start(info);
  });
  
  // Returns a split name with any subsplits formatting removed
  F.StripSubsplitFormatting = (Func<string, string>)((name) => {
    if (name[0] == '-')
      name = name.Substring(1, name.Length - 1);
    return name;
  });
  
  // Returns the V.DefaultSettings default for <key>, otherwise <def>
  // Ignores parent if <cat> is true
  F.DefaultSetting = (Func<string, bool, bool, bool>)((key, def, cat) => {
    V.AllSettings.Add(key);
    if (V.DefaultSettings.ContainsKey(key)) return V.DefaultSettings[key];
    
    if ( (!cat) && (settings.CurrentDefaultParent != null) ) {
      var parts = new List<string>(settings.CurrentDefaultParent.Split('.'));
      
      for (int i = parts.Count(); i != 0; i--) {
        string[] segment = parts.Take(i).ToArray();
        string section = string.Join(".", segment);
        if (V.DefaultParentSettings.ContainsKey(section))
          return V.DefaultParentSettings[section];
      }
    }
    
    return def;
  });
  
  // Adds a new setting <key> with default value <def>, description <desc>
  // and optional tooltip <tooltip>
  F.AddSettingToolTip = (Action<string, bool, string, string>)((key, def, desc, tooltip) => {
    settings.Add(key, F.DefaultSetting(key, def, false), " " + desc);
    if (tooltip != null) settings.SetToolTip(key, tooltip);
    if ( (settings.CurrentDefaultParent != null) &&
      (settings.CurrentDefaultParent.StartsWith("Splits")) ) {
      D.Sets.AllSplits.Add(key);
      D.Names.SplitSetting.Add(key, desc);
    }
  });
  F.AddSetting = (Action<string, bool, string>)((key, def, desc) =>
    F.AddSettingToolTip(key, def, desc, null) );

  // Adds a child setting <key>, prepending <key> with the current default parent,
  // with default value <def>, description <desc> and optional tooltip <tooltip>
  F.AddChildSettingToolTip = (Action<string, bool, string, string>)((key, def, desc, tooltip) => {
    string fullKey = settings.CurrentDefaultParent + "." + key;
    settings.Add(fullKey, F.DefaultSetting(fullKey, def, false), " " + desc);
    if (tooltip != null) settings.SetToolTip(fullKey, tooltip);
  });
  F.AddChildSetting = (Action<string, bool, string>)((key, def, desc) =>
    F.AddChildSettingToolTip(key, def, desc, null) );

  F.AddChildCategory = (Action<string, bool, string>)((key, def, desc) => {
    string fullKey = settings.CurrentDefaultParent + "." + key;
    settings.Add(fullKey, F.DefaultSetting(fullKey, def, true), " " + desc);
  });

  // Changes the current default parent for settings to <parent>, and return <key>
  F.SettingParent = (Func<string, string, string>)((key, parent) => {
    settings.CurrentDefaultParent = parent;
    return key;
  });
  
  F.ShowToolsForm = (Action)(() => {
    int width = 240;
    int width2 = 225;
    
    var toolsForm = new Form() {
      Size = new System.Drawing.Size(450, 128),
      Text = "Metal Gear Solid Autosplitter Toolbox",
      FormBorderStyle = FormBorderStyle.FixedSingle,
      MaximizeBox = false
    };
    
    var btnAppData = new Button() {
      Text = "Open Autosplitter Data Directory",
      Dock = DockStyle.Fill
    };
    btnAppData.Click += (EventHandler)((sender, e) => F.OpenExplorer(V.AppDataDir, false));
    
    var btnFirstRun = new Button() {
      Text = "Change Default Settings Template",
      Dock = DockStyle.Fill
    };
    btnFirstRun.Click += (EventHandler)((sender, e) => F.ShowFirstRunForm(false));
    
    var btnSplitFiles = new Button() {
      Text = "Build Split Files for current settings",
      Dock = DockStyle.Fill
    };
    btnSplitFiles.Click += (EventHandler)((sender, e) => F.ShowMajorSplitsForm());
    
    var binData = Convert.FromBase64String("R0lGODlhDwAaALMJANQyAG8BAVs8AJWVlc/Pz5SUlNDQ0P///wAAAP///wAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAkALAAAAAAPABoAAASCMElpCJkYm1EKQRlVYMhghMYoIeWZbSCYDBfJJjdSuOsB2zIc6zbZ4VZDohA47B2CydwT8ZxEcdMqUknVrlIU5MQAIoyMCY+EVh7RJEZ0YpO+mE8FwHh0N8FrCQQDEgQChgIBehNmE4eGARiMIW9jgyFqGpYTfigqdSGLHZyghBYhEQA7");
    var stream = new MemoryStream(binData);
    
    var picClippit = new PictureBox() {
      Location = new System.Drawing.Point(388, 22),
      Size = new System.Drawing.Size(30, 52),
      Image = new System.Drawing.Bitmap(stream),
      SizeMode = PictureBoxSizeMode.StretchImage
    };
    
    var lblClippit = new Label() {
      BackColor = System.Drawing.Color.FromArgb(0xff, 0xfd, 0xd7),
      Text = "It looks like you're running a game.\n\nWould you like help?",
      Size = new System.Drawing.Size(114, 59),
      Location = new System.Drawing.Point(260, 10),
      Padding = new Padding(2)
    };
    lblClippit.Font = new System.Drawing.Font("Tahoma", lblClippit.Font.Size);
    
    var flpPanel = new TableLayoutPanel() {
      Size = new System.Drawing.Size(width, 88),
      Location = new System.Drawing.Point(3, 0)
    };
    
    flpPanel.Controls.Add(btnFirstRun, 0 ,0);
    flpPanel.Controls.Add(btnSplitFiles, 0, 1);
    flpPanel.Controls.Add(btnAppData, 0, 2);
    
    toolsForm.Controls.Add(flpPanel);
    
    toolsForm.Controls.Add(picClippit);
    toolsForm.Controls.Add(lblClippit);
    
    toolsForm.Show();
  });
  
  F.ShowFirstRunForm = (Action<bool>)((isFirstRun) => {
    int width = 415;
    
    using (var firstRunForm = new Form() {
      Size = new System.Drawing.Size(width, 322),
      FormBorderStyle = FormBorderStyle.FixedSingle,
      MaximizeBox = false,
      Text = isFirstRun ? "Metal Gear Solid Autosplitter 2.0 First Run" :
        "Default Settings Template"
    }) {
    
      string introCustom = isFirstRun ? " used the MGS Autosplitter on this system." :
        "- wait, you opened the window yourself?";
      
      var lblIntro = new Label() {
        Text = string.Format("This seems to be the first time you've{0}\n\nPlease select a default settings template.\nThis will define the default settings for this autosplitter in all your layouts.\nYou can tweak settings in the Layout Editor later.\n\nProtip: You can customise the default for every setting later by opening\n\"Tools\" > \"Change Default Settings Template\" from the settings.", introCustom),
        Location = new System.Drawing.Point(10, 10),
        Size = new System.Drawing.Size(width - (18*2), 110)
      };
      
      var lstTemplate = new ListBox() {
        Location = new System.Drawing.Point(10, 128),
        Size = new System.Drawing.Size(width - (18*2), 114)
      };
      
      lstTemplate.Items.Add("Major Splits only");
      lstTemplate.Items.Add("Major Splits, plus pre-boss Splits");
      lstTemplate.Items.Add("Major Splits, plus most Other Splits");
      lstTemplate.Items.Add("Major Splits, plus most Other Splits (with Boba skip)");
      lstTemplate.Items.Add("[For Old v1 Split Files] Major Splits only");
      lstTemplate.Items.Add("[For Old v1 Split Files] Major Splits plus Area Movement");
      lstTemplate.Items.Add("Enable all available Splits");
      
      V.DefaultSettingsTemplateCount = lstTemplate.Items.Count;
      lstTemplate.SelectedIndex = 2;
      if (!isFirstRun) {
        lstTemplate.Items.Add("Use my current customised settings");
        lstTemplate.SelectedIndex = V.DefaultSettingsTemplateCount;
      }

      var btnConfirm = new Button() {
        Text = "Let's Go",
        Location = new System.Drawing.Point(width - 101, 234)
      };
      btnConfirm.Click += (EventHandler)((sender, e) => {
        F.ProcessFirstRun(lstTemplate.SelectedIndex, isFirstRun);
        firstRunForm.Close();
      });

      firstRunForm.Controls.Add(lblIntro);
      firstRunForm.Controls.Add(lstTemplate);
      firstRunForm.Controls.Add(btnConfirm);
      
      firstRunForm.ShowDialog();
    }
  });
  
  F.ProcessFirstRun = (Action<int, bool>)((templateId, isFirstRun) => {
    string content;
    if ( isFirstRun || (templateId != V.DefaultSettingsTemplateCount) ) {
      var settingTemplates = new List<string>() {
        "+-Splits\n+OL-s03a.CL-s03c.CP-VentClip\n+OP-28\n+OP-38\n+OP-66\n+OP-77\n+CP-133\n+OL-TankHangar.CL-s02e.CP-150\n+OP-150\n+OL-s11d.CL-s11i\n+OP-186\n+OP-197\n+OP-211\n+OL-s15b.CL-s15a.CP-240\n+OL-s14e.CL-s13a.CP-HeatingKey\n+W.CP-257\n+OP-277\n+CP-286\n+W.CP-294", // Majors only
        "+-Splits\n+OL-s03a.CL-s03c.CP-VentClip\n+OP-26\n+OP-28\n+OP-36\n+OP-38\n+CP-65\n+OP-66\n+CL-s08b.CP-ReachNinja\n+OP-77\n+OP-125\n+CP-133\n+OL-TankHangar.CL-s02e.CP-150\n+OL-s09a.CL-s10a.CP-150\n+OP-150\n+OL-s11d.CL-s11i\n+CP-ReachHind\n+OP-186\n+CP-197\n+OP-197\n+OL-s14e.CL-s15a.CP-ReachRaven\n+OP-211\n+OL-s15b.CL-s15a.CP-240\n+OL-s14e.CL-s13a.CP-HeatingKey\n+CP-252\n+W.CP-257\n+OP-277\n+CP-286\n+W.CP-294", // Majors + pre-boss
        "", // Defaults
        "-OL-s11g.CL-s11d\n-OL-s11d.CL-s11i", // Boba skip
        "+-Splits\n+OP-28\n+OP-38\n+OP-66\n+OP-77\n+CP-133\n+OP-150\n+OP-186\n+OP-197\n+OP-211\n+W.CP-257\n+OP-277\n+CP-286\n+W.CP-294", // Old Major
        "-W.CL-s03a.CP-18\n-CP-ReachDarpaChief\n-OP-26\n-OP-36\n-CP-65\n-CP-112\n-OP-125\n-CP-146\n+OL-s03b.CL-s03c\n-CP-ReachHind\n-CP-197\n-OL-s12b.CL-change.CP-204\n-CP-206\n-CP-207\n+OL-s16d.CL-s16c.CP-ReachCommandRoom\n-OP-238\n-OP-240\n-CP-247\n-W.CP-255", // Old Area Movement
        "++Splits", // E V E R Y T H I N G
      };
      content = settingTemplates[templateId];
    }
    else content = F.CustomSettingTemplate();
    
    if (templateId != V.DefaultSettingsTemplateCount) {
      string majorContent = "OL-s03a.CL-s03c.CP-VentClip\nOP-28\nOP-38\nOP-66\nOP-77\nCP-133\nOL-TankHangar.CL-s02e.CP-150\nOP-150\nOL-TankHangar.CL-s02e.CP-163\nOL-s11d.CL-s11i\nOP-186\nOP-197\nOP-211\nOL-s15b.CL-s15a.CP-240\nOL-s14e.CL-s13a.CP-HeatingKey\nW.CP-257\nOP-277\nCP-286\nW.CP-294";
      F.WriteFile(V.MajorSplitsFile, majorContent, false);
      F.Debug("Wrote MajorSplits file, content:\n" + majorContent);
    }
    
    F.WriteFile(V.DefaultSettingsFile, content, false);
    F.Debug("Wrote DefaultSettings file for template " + templateId + ", content:\n" + content);
    
    string successMsg = "Saved the default settings template to AppData.\n\n";
    if (isFirstRun)
      successMsg += "To access this window again, toggle \"MGS Autosplitter Toolbox\" in the layout component settings.\n\nYou can also create a new set of Split Files from the toolbox.";
    else if (templateId != V.DefaultSettingsTemplateCount)
      successMsg += "Your current settings have not been changed.\n\nTo use the \"Reset to Default\" button, please reload the autosplitter or restart LiveSplit first.";
    
    MessageBox.Show(successMsg, "Default Settings templates created", MessageBoxButtons.OK, MessageBoxIcon.Information);
  });
      
    

  // Return a blank emulator specification definition
  // Populated specs are used when scanning for game memory
  New.EmulatorSpec = (Func<ExpandoObject>)(() => {
    dynamic emu = new ExpandoObject();
    emu.BaseOffset = null;
    emu.Module = null;
    emu.ModuleNames = null;
    emu.Platform = null;
    emu.Signature = null;
    emu.SignatureOffset = 0;
    emu.DerefLevel = 0;
    emu.CheckMappedMemory = false;
    emu.ScanForMemory = false;
    return emu;
  });
  
  // Return a new Manual MemoryWatcher for byte[]
  // with address <addr> and length <len>
  New.ByteArray = (Func<IntPtr, int, ExpandoObject>)((addr, len) => {
    dynamic ba = new ExpandoObject();
    ba.Address = addr;
    ba.Length = len;
    ba.Current = new byte[len];
    ba.Old = new byte[len];
    ba.Update = F.UpdateByteArray;
    return ba;
  });
  // startup: Function definitions END
  
  
  // Look for a DefaultSettings file
  if (!File.Exists(V.DefaultSettingsFile))
    F.ShowFirstRunForm(true);
  
  // If DefaultSettings file exists, parse it and create DefaultSettings
  // and DefaultParentSettings dictionaries for later settings definitions
  if (File.Exists(V.DefaultSettingsFile)) {
    string[] defaultSettings = File.ReadAllLines(V.DefaultSettingsFile);
    foreach (string line in defaultSettings) {
      string l = line;
      if (l.Length < 3) continue;
      
      int enable = 0;
      int enableChildren = 0;
      
      if (l[0] == '+') enable = 1;
      else if (l[0] == '-') enable = -1;
      if (enable != 0) l = l.Substring(1);
      
      if (l[0] == '+') enableChildren = 1;
      else if (l[0] == '-') enableChildren = -1;
      if (enableChildren != 0) {
        l = l.Substring(1);
        V.DefaultParentSettings.Add(l, (enableChildren == 1));
      }
      
      if (enable != 0) V.DefaultSettings.Add(l, (enable == 1));
    }
  }
  
  
  /****************************************************/
  /* startup: Settings definitions
  /****************************************************/
  F.AddSettingToolTip("Tools", false, "MGS Autosplitter Toolbox (toggle setting with game open)", "You must have the game/emulator open to launch the toolbox.\nThis is due to technical limitations with the ASL framework.");

  F.AddSetting(F.SettingParent("Opt", null), true, "Settings");

    F.AddChildSetting(F.SettingParent("Debug", "Opt"), true, "Debug Logging");
      F.AddChildSettingToolTip(F.SettingParent("File", "Opt.Debug"), true, "Save debug information to AppData directory", "Log location: " + V.DebugLogPath);
      F.AddChildSettingToolTip("StdOut", false, "Log debug information to Windows debug log", "This can be viewed in a tool such as DebugView.");

    F.AddChildSetting(F.SettingParent("Behaviour", "Opt"), true, "Autosplitter Behaviour");
      F.AddChildSettingToolTip(F.SettingParent("UndoPAL", "Opt.Behaviour"), true, "Undo certain splits to maintain split integrity", "Triggers undo if you go back after failing to cool/heat the PAL Key correctly. In practice:\n * Enabled: Very slow Warehouse/Blast Furnace split\n * Disabled: Very slow split at the point you decide to backtrack; potential false gold on Warehouse/Blast Furnace\n\nTriggers undo if you go to Nuke Building B2 without the Nikita (when F7 Area Reloading is available) then return to B1.");
      F.AddChildSettingToolTip("KevinSkipSplits", true, "Skip splits to stay on route after Comm Tower A's Boba skip", "Skips the splits for:\n* Comms Tower A\n* Comms Tower A Roof\n\nSplits for:\n* Comms Tower A Rappel");
      F.AddChildSetting("StartOnLoad", false, "Start timer when loading a save");
      F.AddChildSettingToolTip("HalfFrameRate", false, "Run splitter logic at 30 fps",  "Can improve performance on weaker systems, at the cost of some precision.");
      F.AddChildSettingToolTip("VR.InstaSplit", false, "In VR Missions, split instantly upon hitting the goal", "If disabled, this will split when leaving the level.\nVR Missions are currently only supported on PC.");

    F.AddChildSetting(F.SettingParent("Test", "Opt"), false, "Testing Functions");
      F.AddChildSetting(F.SettingParent("SplitOnStart", "Opt.Test"), false, "Split when Start (Console) or F3 (PC) is pressed");
      F.AddChildSetting("SplitOnR3", false, "Split when R3 is pressed (Console only)");
      F.AddChildSetting("SplitOnLocation", false, "Split whenever the location code changes");
      F.AddChildSetting("SplitOnProgress", false, "Split whenever the progress code changes");
    
    F.AddChildSettingToolTip(F.SettingParent("ASL", "Opt"), true, "ASL Var Viewer integration", "Disabling this may slightly improve performance");
      F.AddChildSetting(F.SettingParent("FPS", "Opt.ASL"), true, "FPS (framerate counter for console)");
        F.AddChildSetting(F.SettingParent("2DP", "Opt.ASL.FPS"), false, "Display FPS to 2 decimal places");
        F.AddChildSetting("1", true, "Include 1 sec counter");
        F.AddChildSetting("5", true, "Include 5 sec counter");
        F.AddChildSetting("15", true, "Include 15 sec counter");
        F.AddChildSetting("60", false, "Include 60 sec counter");
        F.AddChildSetting("-1", false, "Include counter for the whole run");
      F.AddChildSetting(F.SettingParent("Location", "Opt.ASL"), true, "Location (name of current location)");
      F.AddChildSetting("Stats", true, "Stats (game stats)");
        F.AddChildSetting(F.SettingParent("Alerts", "Opt.ASL.Stats"), true, "Include Alerts");
        F.AddChildSetting("Continues", true, "Include Continues");
        F.AddChildSetting("Kills", true, "Include Kills");
        F.AddChildSetting("Rations", true, "Include Rations");
        F.AddChildSetting("Saves", true, "Include Saves");
      F.AddChildSetting(F.SettingParent("Info", "Opt.ASL"), true, "Info (contextual information)");
        F.AddChildSetting(F.SettingParent("Alt", "Opt.ASL.Info"), true, "Show another variable when Info is empty");
          F.AddChildSetting(F.SettingParent("FPS", "Opt.ASL.Info.Alt"), false, "FPS");
          F.AddChildSetting("Location", false, "Location");
          F.AddChildSetting("Stats", false, "Stats");
        F.AddChildSetting(F.SettingParent("Boss", "Opt.ASL.Info"), true, "Include Boss Health");
        F.AddChildSetting("Life", true, "Include Snake Health");
        F.AddChildSetting("Chaff", true, "Include Chaff timer");
        F.AddChildSetting("O2", true, "Include O2 timer");
        F.AddChildSetting("Diazepam", true, "Include Diazepam timer");
        F.AddChildSetting("Dock", true, "Include Dock elevator countdown");

  F.AddSetting(F.SettingParent("Splits", null), true, "Split Points");
  
    F.AddSetting(F.SettingParent("OL-s00a", "Splits"), true, "Dock ⮞ Heliport");
    F.AddSetting("OL-s01a.CL-s02a.CP-18", true, "Heliport ⮞ Tank Hangar");
    F.AddSetting("OL-TankHangar.CL-s03a.CP-18", true, "Tank Hangar ⮞ Cell");
    F.AddSetting("OL-s03a.CL-s03c.CP-VentClip", true, "[Any%] Vent Clip"); // to p158
    F.AddChildCategory("AB", true, "[All Bosses]");
      F.AddSetting(F.SettingParent("W.CL-s03a.CP-18", "Splits.AB"), true, "[AB] Cell ⮞ Cell Vent");
      F.AddSetting("CP-ReachDarpaChief", true, "[AB] Cell Vent ⮞ Cell (DARPA Chief)"); // 19-24
      F.AddSetting("OP-26", true, "[AB] Cell ⮞ Guard Encounter"); // during fade, maybe also 28 (during fight)
      F.AddSetting("OP-28", true, "[AB] Guard Encounter");
      F.AddSetting("CL-s04a.CP-36", true, "[AB] Cell ⮞ Armory");
      F.AddSetting("CL-s04b.CP-36", true, "[AB] Armory ⮞ Armory South");
      F.AddSetting("OP-36", true, "[AB] Armory South ⮞ Revolver Ocelot");
      F.AddSetting("OP-38", true, "[AB] Revolver Ocelot");
      F.AddSetting("OL-s04c.CL-s04a.CP-52", true, "[AB] Armory South ⮞ Armory");
      F.AddSetting("OL-TankHangar.CL-s02c.CP-AfterOcelot", true, "[AB] Armory ⮞ Tank Hangar");
      F.AddSetting("CL-s05a.CP-AfterOcelot", true, "[AB] Tank Hangar ⮞ Canyon");
      F.AddSetting("CP-65", true, "[AB] Canyon ⮞ M1 Tank");
      F.AddSetting("OP-66", true, "[AB] M1 Tank"); // or CP-67
      F.AddSetting("CL-s07a.CP-69", true, "[AB] Nuke Building 1F ⮞ Nuke Building B1");
      F.AddSetting("CL-s08a.CP-69", true, "[AB] Nuke Building B1 ⮞ Nuke Building B2"); // also nikita check
      F.AddSetting("CL-s08c.CP-69", true, "[AB] Nuke Building B2 ⮞ Lab Hallway");
      F.AddSetting("CL-s08b.CP-ReachNinja", true, "[AB] Lab Hallway ⮞ Lab (Ninja)");
      F.AddSetting("OP-77", true, "[AB] Ninja"); // or CP-78
      F.AddSetting("OL-s08b.CL-s08c.CP-111", true, "[AB] Lab ⮞ Lab Hallway");
      F.AddSetting("OL-s08c.CL-s08a.CP-111", true, "[AB] Lab Hallway ⮞ Nuke Building B2");
      F.AddSetting("CL-s07a.CP-111", true, "[AB] Nuke Building B2 ⮞ Nuke Building B1");
      F.AddSetting("CP-112", true, "[AB] Nuke Building B1 ⮞ Found Meryl"); // or OP-111
      F.AddSetting("OL-s07c.CL-s07b.CP-119", true, "[AB] Nuke Building B1 ⮞ Commander's Room"); // insta
      F.AddSetting("OP-125", true, "[AB] Commander's Room ⮞ Psycho Mantis"); // or CP-126
      F.AddSetting("CP-133", true, "[AB] Psycho Mantis"); // or OP-129
      F.AddSetting("OL-s07b.CL-s09a.CP-137", true, "[AB] Commander's Room ⮞ Cave"); // maybe also 138-139
      F.AddSetting("OL-s09a.CL-s10a.CP-ReachUgPassage", true, "[AB] Cave ⮞ Underground Passage"); // OL maybe not necessary
      F.AddSetting("CP-146", false, "[AB] Underground Passage ⮞ Ambushed"); // or OP-145
      F.AddSetting("OL-s10a.CL-s09a.CP-149", true, "[AB] Underground Passage ⮞ Cave");
      F.AddSetting("OL-s09a.CL-s07b.CP-149", true, "[AB] Cave ⮞ Commander's Room"); // maybe 150 too, OL maybe not necessary
      F.AddSetting("OL-s07b.CL-s07a.CP-150", true, "[AB] Commander's Room ⮞ Nuke Building B1");
      F.AddSetting("OL-NukeBuilding.CL-s06a.CP-150", true, "[AB] Nuke Building B1 ⮞ Nuke Building 1F");
      F.AddSetting("OL-s06a.CL-s05a.CP-150", true, "[AB] Nuke Building 1F ⮞ Canyon");
      F.AddSetting("OL-s05a.CL-s02e.CP-150", true, "[AB] Canyon ⮞ Tank Hangar");
      F.AddSetting("OL-TankHangar.CL-s04a.CP-150", true, "[AB] Tank Hangar ⮞ Armory");
      F.AddSetting("OL-TankHangar.CL-s02e.CP-150", true, "[AB] Armory (PSG1) ⮞ Tank Hangar"); // also psg1 up to (not inc) p151
      F.AddSetting("OL-s02e.CL-s05a.CP-150", true, "[AB] Tank Hangar ⮞ Canyon");
      F.AddSetting("OL-s05a.CL-s06a.CP-150", true, "[AB] Canyon ⮞ Nuke Building 1F");
      F.AddSetting("OL-NukeBuilding.CL-s07a.CP-150", true, "[AB] Nuke Building 1F ⮞ Nuke Building B1");
      F.AddSetting("OL-s07a.CL-s07b.CP-150", true, "[AB] Nuke Building B1 ⮞ Commander's Room");
      F.AddSetting("OL-s07b.CL-s09a.CP-150", true, "[AB] Commander's Room ⮞ Cave");
      F.AddSetting("OL-s09a.CL-s10a.CP-150", true, "[AB] Cave ⮞ Sniper Wolf 1");
      F.AddSetting("OP-150", true, "[AB] Sniper Wolf 1"); // CP-151 is during next
      F.AddSetting("CP-157", true, "[AB] Underground Passage ⮞ Torture Room"); // s10a_s03b_p157?

    F.AddSetting(F.SettingParent("OL-s03b.CL-s03c", "Splits"), false, "Torture ⮞ Medi Room"); // 157-158?
    F.AddSetting("OL-s03c.CL-s03a.CP-163", true, "Medi Room ⮞ Cell");
    F.AddSetting("OL-TankHangar.CL-s04a.CP-163", true, "[Any%] Cell ⮞ Armory");
    F.AddSetting("OL-TankHangar.CL-s02e.CP-163", true, "[Any%] Armory (PSG1) ⮞ Tank Hangar");
    //F.AddSetting("OL-TankHangar.CL-s02e.CP-163", true, "Cell or Armory ⮞ Tank Hangar"); // psg1
    F.AddSetting("OL-TankHangar.CL-s02e.CP-ABEscape", true, "[All Bosses] Cell ⮞ Tank Hangar");
    
    F.AddSetting("OL-s02e.CL-s05a.CP-163", true, "Tank Hangar ⮞ Canyon");
    F.AddSetting("OL-s05a.CL-s06a.CP-163", true, "Canyon ⮞ Nuke Building 1F");
    F.AddSetting("OL-NukeBuilding.CL-s07a.CP-163", true, "Nuke Building 1F ⮞ Nuke Building B1");
    F.AddSetting("OL-s07a.CL-s07b.CP-163", true, "Nuke Building B1 ⮞ Commander's Room");
    F.AddSetting("OL-s07b.CL-s09a.CP-163", true, "Commander's Room ⮞ Cave");
    F.AddSetting("OL-s09a.CL-s10a.CP-163", true, "Cave ⮞ Underground Passage");
    F.AddSetting("OL-s10a.CL-s11a.CP-AfterEscape", true, "Underground Passage ⮞ Comms Tower A"); // CP not needed?
    F.AddSetting("OL-s11a.CL-s11b.CP-DefeatCTAChase", true, "Comms Tower A ⮞ Comms Tower A Roof or Walkway"); // CP not needed?
    F.AddSetting("OL-s11g.CL-s11d", true, "Comms Tower A Roof ⮞ Comms Tower A Wall");
    F.AddSetting("OL-s11d.CL-s11i", true, "Rappel");
    F.AddSetting("OL-s11i.CL-s11c.CP-180", true, "Walkway ⮞ Comms Tower B");
    F.AddSetting("OL-s11c.CL-s11h.CP-BeforeHind", true, "[AB/C-Any%] Comms Tower B ⮞ Comms Tower B Roof");
    F.AddSetting("CP-ReachHind", true, "[AB] Comms Tower B Roof ⮞ Hind D"); // maybe only 186?
    F.AddSetting("OP-186", true, "[AB] Hind D");
    F.AddSetting("OL-s11h.CL-s11c.CP-CommTowerB", true, "Comms Tower B Roof ⮞ Comms Tower B"); // test progress after hind for ab
    F.AddSetting("OL-s11c.CL-s11e.CP-AfterHind", true, "[C-AB] Comms Tower B ⮞ Elevator (Guard Encounter)");
    F.AddSetting("CP-195", true, "[C-AB] Guard Encounter");
    F.AddSetting("OL-s11c.CL-s12a.CP-CommTowerB", true, "Comms Tower B ⮞ Snowfield"); // CP not needed?
    F.AddSetting("CP-197", true, "Snowfield ⮞ Sniper Wolf 2");
    F.AddSetting("OP-197", true, "Sniper Wolf 2");

    F.AddChildCategory("ConsoleAny", true, "[Console Any%]");
      F.AddSetting(F.SettingParent("OL-Snowfield.CL-s11c.CP-204", "Splits.ConsoleAny"), true, "[C-Any%] Snowfield ⮞ Comms Tower B"); // no stinger
      F.AddSetting("OL-s11c.CL-s11i.CP-204", true, "[C-Any%] Comms Tower B ⮞ Comms Tower B Roof"); // no stinger
      F.AddSetting("OL-s11i.CL-s11c.CP-204", true, "[C-Any%] Comms Tower B Roof ⮞ Comms Tower B"); // also check stinger
      F.AddSetting("OL-s11c.CL-Snowfield.CP-204", true, "[C-Any%] Comms Tower B ⮞ Snowfield"); // stinger

    F.AddSettingToolTip(F.SettingParent("OL-s12b.CL-change.CP-204", "Splits"), false, "[Console] Reach disc change", "If you want to split after disc change, select the following split instead."); // todo check loc for change; CP not needed?
    F.AddSetting("OL-Snowfield.CL-s13a.CP-204", true, "Snowfield ⮞ Blast Furnace");
    F.AddSetting("OL-s13a.CL-s14e.CP-204", true, "Blast Furnace ⮞ Cargo Elevator");
    F.AddSetting("CP-206", true, "Cargo Elevator ⮞ Guard Encounter");
    F.AddSetting("CP-207", true, "Guard Encounter");
    F.AddSetting("OL-s14e.CL-s15a.CP-ReachRaven", true, "Cargo Elevator ⮞ Warehouse (Vulcan Raven)"); // 207-211
    F.AddSetting("OP-211", true, "Vulcan Raven");
    F.AddSetting("OL-s15a.CL-s15b.CP-AfterRaven", true, "Warehouse ⮞ Warehouse North");
    F.AddSetting("OL-s15b.CL-s16a.CP-AfterRaven", true, "Warehouse North ⮞ Underground Base 1");
    F.AddSetting("OL-s16a.CL-s16b.CP-221", true, "Underground Base 1 ⮞ Underground Base 2");
    F.AddSetting("OL-s16b.CL-s16c.CP-223", true, "Underground Base 2 ⮞ Underground Base 3");
    F.AddSetting("OL-s16c.CL-s16d.CP-ReachCommandRoom", true, "Underground Base 3 ⮞ Command Room");
    F.AddSetting("OL-s16d.CL-s16c.CP-ReachCommandRoom", true, "Command Room ⮞ Underground Base 3");
    F.AddSetting("OL-s16c.CL-s16b.CP-237", true, "Underground Base 3 ⮞ Underground Base 2");
    F.AddSetting("OL-s16b.CL-s16a.CP-237", true, "Underground Base 2 ⮞ Underground Base 1");
    F.AddChildCategory("NormalPAL", true, "[With Normal PAL Key]");
      F.AddSetting(F.SettingParent("OL-s16a.CL-s16b.CP-238", "Splits.NormalPAL"), true, "Underground Base 1 ⮞ Underground Base 2");
      F.AddSetting("OL-s16b.CL-s16c.CP-238", true, "Underground Base 2 ⮞ Underground Base 3");
      F.AddSetting("OL-s16c.CL-s16d.CP-238", true, "Underground Base 3 ⮞ Command Room");
      F.AddSetting("OP-238", true, "Normal PAL Key"); // 239, maybe 240?
      F.AddSetting("OL-s16d.CL-s16c.CP-240", true, "Command Room ⮞ Underground Base");
      F.AddSetting("OL-s16c.CL-s16b.CP-240", true, "Underground Base 3 ⮞ Underground Base 2");
      F.AddSetting("OL-s16b.CL-s16a.CP-240", true, "Underground Base 2 ⮞ Underground Base 1");
      F.AddSetting("OL-s16a.CL-s15b.CP-240", true, "Underground Base 1 ⮞ Warehouse North");
      F.AddSetting("OL-s15b.CL-s15a.CP-240", true, "Enter Warehouse");
    F.AddChildCategory(F.SettingParent("ColdPAL", "Splits"), true, "[With Cold PAL Key]");
      F.AddSetting(F.SettingParent("OL-s15a.CL-s15b.CP-240", "Splits.ColdPAL"), true, "Warehouse ⮞ Warehouse North"); // DON'T check pal state!
      F.AddSetting("OL-s15b.CL-s16a.CP-240", true, "Warehouse North ⮞ Underground Base 1"); // check s15b_s15a_p240 completed until p241
      F.AddSetting("OL-s16a.CL-s16b.CP-240", true, "Underground Base 1 ⮞ Underground Base 2");
      F.AddSetting("OL-s16b.CL-s16c.CP-240", true, "Underground Base 2 ⮞ Underground Base 3");
      F.AddSetting("OL-s16c.CL-s16d.CP-240", true, "Underground Base 3 ⮞ Command Room");
      F.AddSetting("OP-240", true, "Cold PAL Key"); // 241, maybe 242
      F.AddSetting("OL-s16d.CL-s16c.CP-242", true, "Command Room ⮞ Underground Base 3");
      F.AddSetting("OL-s16c.CL-s16b.CP-242", true, "Underground Base 3 ⮞ Underground Base 2");
      F.AddSetting("OL-s16b.CL-s16a.CP-242", true, "Underground Base 2 ⮞ Underground Base 1");
      F.AddSetting("OL-s16a.CL-s15b.CP-242", true, "Underground Base 1 ⮞ Warehouse North");
      F.AddSetting("OL-s15b.CL-s15c.CP-242", true, "Warehouse North ⮞ Warehouse");
      F.AddSetting("OL-s15c.CL-s14e.CP-242", true, "Warehouse ⮞ Cargo Elevator");
      F.AddSetting("OL-s14e.CL-s13a.CP-HeatingKey", true, "Enter Blast Furnace"); // 242-246
    F.AddChildCategory(F.SettingParent("HotPAL", "Splits"), true, "[With Hot PAL Key]");
      F.AddSetting(F.SettingParent("OL-s13a.CL-s14e.CP-HeatingKey", "Splits.HotPAL"), true, "Blast Furnace ⮞ Cargo Elevator");
      F.AddSetting("OL-s14e.CL-s15c.CP-HeatingKey", true, "Cargo Elevator ⮞ Warehouse"); // check s14e_s13a_HeatingKey to p247
      F.AddSetting("OL-s15c.CL-s15b.CP-HeatingKey", true, "Warehouse ⮞ Warehouse North");
      F.AddSetting("OL-s15b.CL-s16a.CP-HeatingKey", true, "Warehouse North ⮞ Underground Base 1");
      F.AddSetting("OL-s16a.CL-s16b.CP-HeatingKey", true, "Underground Base 1 ⮞ Underground Base 2");
      F.AddSetting("OL-s16b.CL-s16c.CP-HeatingKey", true, "Underground Base 2 ⮞ Underground Base 3");
      F.AddSetting("OL-s16c.CL-s16d.CP-HeatingKey", true, "Underground Base 3 ⮞ Command Room");
      F.AddSetting("CP-247", true, "Hot PAL Key"); // maybe 248, prob not
    F.AddSetting(F.SettingParent("OL-s16d.CL-d16e", "Splits"), true, "Command Room ⮞ Underground Base 3");
    F.AddSetting("CP-252", true, "Underground Base 3 ⮞ Supply Route (Metal Gear REX)");
    F.AddSetting("W.CP-255", true, "Metal Gear REX (Phase 1)");
    F.AddSetting("W.CP-257", true, "Metal Gear REX");
    F.AddSetting("OP-277", true, "Liquid Snake"); // CP-288?
    F.AddSetting("OL-s19a.CL-s19b", true, "Escape Route 1 ⮞ Escape Route 2");
    F.AddSetting("CP-286", true, "Escape");
    F.AddSetting("W.CP-294", true, "Score");

  F.AddSettingToolTip(F.SettingParent("Mods", null), true, "Split Timing Modifiers", "Make certain Split Points occur earlier or later than normal.\nMake sure the related Split Point is ENABLED, or this won't do anything!");
    F.AddSettingToolTip(F.SettingParent("CP-7", "Mods"), false, "[Dock ⮞ Heliport] Split earlier on the elevator", "[Dock] Reached elevator");
    F.AddSetting("CP-153", false, "[UG Passage ⮞ Torture Room] Split immediately when ambushed");
    F.AddSetting("CP-163", false, "[Medi Room ⮞ Cell] Split when running through door");
    F.AddSetting("CP-178", false, "[CTA Roof ⮞ CTA Wall] Split immediately when attaching rope");
    F.AddSetting("CP-179", false, "[CTA Wall ⮞ Walkway] Split immediately when completing rappel");
    F.AddSettingToolTip("W.CL-s15a.CP-240", true, "[Warehouse North ⮞ Warehouse] Split when Warehouse starts", "Console only, will split as normal on PC");
    F.AddSettingToolTip("W.CL-s13a.CP-HeatingKey", true, "[Cargo Elevator ⮞ Blast Furnace] Split when Blast Furnace starts", "Console only, will split as normal on PC");
    F.AddSettingToolTip("W.CL-s19b", true, "[Escape] On Very Easy, split for SRDC RTA rules", "Splits earlier - when the escape timer disappears.\nThis setting has no effect if running on any other difficulty.");
  // startup: Settings definitions END
  

  F.ResetAllVars();
}
// startup END


/****************************************************/
/* init: Runs when the game (PC) or emulator opens
/****************************************************/
init {
  var D = vars.D; var F = D.Funcs; var G = D.Game; var M = D.Mem;
  var New = D.New; var R = D.Run;  var V = D.Vars; var MM = D.ManualMem;
  
  
  /****************************************************/
  /* init: Function definitions
  /* These functions require access to settings/current
  /****************************************************/
  if (!V.InitInitiated) {
    V.InitInitiated = true;
    
    V.LastToggleSetting = new Dictionary<string, bool>() {
      { "Tools", settings["Tools"] },
    };
    
    // Updates [vars.Info] with current boss health data
    F.BossHealthCurrent = (Func<string, int, int, int>)((name, curHP, maxHP) => {
      if (!settings["Opt.ASL.Info.Boss"]) return 0;
      
      if ( (maxHP <= 0) || (curHP > maxHP) ) return 0;
      if (curHP < 0) curHP = 0;
      
      if (!R.LastBoss.Equals(name)) {
        if (curHP == maxHP) R.LastBoss = name;
        else return 0;
      }
      
      string output = string.Format("{0} | {1} ({2}/{3} HP)",
        name, F.Percentage(curHP, maxHP), curHP, maxHP);
      F.Info(output, 2000, M["BossHP"].Changed ? 60 : 10);
      return 0;
    });
    F.BossHealth = (Func<string, int, int>)((name, maxHP) =>
      F.BossHealthCurrent(name, M["BossHP"].Current, maxHP));
    F.ShowBossHealth = (Action<string, int>)((name, maxHP) =>
      F.BossHealth(name, maxHP));

    // TRUE if <key> exists in the settings array and is true
    F.SettingEnabled = (Func<string, bool>)((key) => 
      ( (settings.ContainsKey(key)) && (settings[key]) ) );
    
    // Outputs <message> to debug log and/or Windows stdout (if debug settings are enabled)
    F.Debug = (Action<string>)((message) => {
      string gameTime = ( (!G.VRMissions) && (M.Count != 0) && (M["GameTime"].Current != 0) ) ?
        string.Format("[{0} > {1}] ", M["GameTime"].Old, M["GameTime"].Current) :
        string.Format("[{0}] ", DateTime.Now.ToString("T"));

      message = gameTime + message;
      if (settings["Opt.Debug.File"]) V.DebugLogBuffer.Add(message);
      if (settings["Opt.Debug.StdOut"]) print("[MGS1] " + message);
    });
    
    // On an exception, adds the error message to the buffer to be written to the debug log
    V.EventLog.EntryWritten -= F.EventLogWritten;
    F.EventLogWritten = new EntryWrittenEventHandler((Action<object, EntryWrittenEventArgs>)((sender, e) => {
      var entry = e.Entry;
      if ( (settings["Opt.Debug.File"]) && (entry.Source.Equals("LiveSplit"))
        && (entry.EntryType.ToString().Equals("Error")) ) {
        if ( (entry.TimeGenerated - V.LastError).Seconds > 4 ) {
          V.LastError = DateTime.Now;
          string message = string.Format("[Error at {0}] {1}",
            V.LastError.ToString("T"), entry.Message);
          
          V.DebugLogBuffer.Add(message);
        }
      }
    }));
    V.EventLog.EntryWritten += F.EventLogWritten;
    
    // Update the current set of check/watch codes for location/progress
    F.SetStateCodes = (Action)(() => {
      string CurLoc = (string)M["Location"].Current;
      string OldLoc = (string)M["Location"].Old;
      short CurProg = (short)M["Progress"].Current;
      short OldProg = (short)M["Progress"].Old;
      
      R.CurrentLocations = new HashSet<string>() { CurLoc };
      if (D.Sets.Location.ContainsKey(CurLoc))
        R.CurrentLocations.Add( D.Sets.Location[CurLoc] );
      
      R.OldLocations = new HashSet<string>() { OldLoc };
      if (D.Sets.Location.ContainsKey(OldLoc))
        R.OldLocations.Add( D.Sets.Location[OldLoc] );

      R.CurrentProgress = new HashSet<string>() { CurProg.ToString() };
      if (D.Sets.Progress.ContainsKey(CurProg)) {
        foreach (var p in D.Sets.Progress[CurProg])
          R.CurrentProgress.UnionWith( D.Sets.Progress[CurProg] );
      }
      
      R.OldProgress = new HashSet<string>() { OldProg.ToString() };
      if (D.Sets.Progress.ContainsKey(OldProg)) {
        foreach (var p in D.Sets.Progress[OldProg])
          R.OldProgress.UnionWith( D.Sets.Progress[OldProg] );
      }
      
      var watchCodes = new HashSet<string>();

      foreach (var loc in R.CurrentLocations) {
        foreach (var prog in R.CurrentProgress)
          watchCodes.Add("CL-" + loc + ".CP-" + prog);
        watchCodes.Add("CL-" + loc);
      }
      
      foreach (var prog in R.CurrentProgress)
        watchCodes.Add("CP-" + prog);

      F.ResetActiveWatchers();
      var activeCodes = new List<string>();
      foreach (var c in watchCodes) {
        if (G.CodeMemoryWatchers.ContainsKey(c)) {
          G.CodeMemoryWatchers[c].UpdateAll(game);
          M.AddRange(G.CodeMemoryWatchers[c]);
        }
        string code = "W." + c;
        if (F.Watch.ContainsKey(code))
          activeCodes.Add(code);
      }

      if (activeCodes.Count == 0) R.ActiveWatchCodes = null;
      else {
        F.Debug("Active watcher (" + string.Join(" ", activeCodes) + ")");
        R.ActiveWatchCodes = activeCodes;
      }
    });

    // Instructs all Manual Memory Watchers (MM) to update their value
    F.UpdateMM = (Action<Process>)((g) => {
      foreach (var m in MM)
        m.Value.Update(m.Value, g);
    });
    
    // MM Update function for byte[]
    F.UpdateByteArray = (Action<dynamic, Process>)((m, g) => {
      m.Old = m.Current;
      m.Current = g.ReadBytes((IntPtr)m.Address, (int)m.Length);
    });
    
    // Updates the [current] object with current values for ASL Var Viewer (ASLVV)
    F.UpdateCurrent = (Action)(() => {
      var cur = current as IDictionary<string, object>;
      foreach (var w in G.CurrentMemoryWatchers)
        cur[w.Name] = w.Current;
    });
    
    // Updates [vars.Stats] for ASLVV
    F.UpdateASLStats = (Action)(() => {
      var a = M["Alerts"].Current;
      var c = M["Continues"].Current;
      var k = M["Kills"].Current;
      var r = M["RationsUsed"].Current;
      var s = M["Saves"].Current;
      var stats = new List<string>();
      if ( (settings["Opt.ASL.Stats.Alerts"]) && (a != 0) )
        stats.Add(a + " Alert" + ((a == 1) ? "":"s"));
      if ( (settings["Opt.ASL.Stats.Continues"]) && (c != 0) )
        stats.Add(c + " Continue" + ((c == 1) ? "":"s"));
      if ( (settings["Opt.ASL.Stats.Kills"]) && (k != 0) )
        stats.Add(k + " Kill" + ((k == 1) ? "":"s"));
      if ( (settings["Opt.ASL.Stats.Rations"]) && (r != 0) )
        stats.Add(r + " Ration" + ((r == 1) ? "":"s"));
      if ( (settings["Opt.ASL.Stats.Saves"]) && (s != 0) )
        stats.Add(s + " Save" + ((s == 1) ? "":"s"));
      F.SetVar("Stats", string.Join(", ", stats));
    });
    
    // Updates [vars.Info] with common info for ASLVV
    F.UpdateASLInfo = (Action)(() => {
      var diaz = M["DiazepamTimer"];
      var chaff = M["ChaffTimer"];
      var o2 = M["O2Timer"];
      var life = M["Life"];
      var maxLife = M["MaxLife"];
      
      if ( (settings["Opt.ASL.Info.Life"]) && (life.Changed) ) {
        string lifePercent = F.Percentage(life.Current, maxLife.Current);
        string lifeCurrent = string.Format("{0} ({1}/{2} HP)",
          lifePercent, life.Current, maxLife.Current);
        if (M["GameTime"].Current > 300)
          F.Info("Life: " + lifeCurrent, 3000, 50);
      }
      else if ( (settings["Opt.ASL.Info.O2"]) && (o2.Current > 0) && (o2.Current < 1024) ) {
        decimal o2PerSec = ((decimal)F.CurrentO2Rate() / 4096 * F.FramesPerSecond());
        string o2Percent = F.Percentage(o2.Current, 1024);
        string o2Current = (o2PerSec == 0) ? o2Percent :
          string.Format("{0} ({1:0.0} left)", o2Percent, ((decimal)o2.Current / o2PerSec));
        F.Info("O2: " + o2Current, 200, 40);
      }
      else if ( (settings["Opt.ASL.Info.Chaff"]) && (chaff.Changed) && (chaff.Current > 0) ) {
        string chaffCurrent = F.FramesToSeconds(chaff.Current);
        string chaffPercent = F.Percentage(chaff.Current, 300);
        F.Info("Chaff: " + chaffPercent + " (" + chaffCurrent + " left)", 200, 30); 
      }
      else if ( (settings["Opt.ASL.Info.Diazepam"]) && (diaz.Current > 0) ) {
        string diazCurrent = F.FramesToSeconds(diaz.Current);
        string diazPercent = F.Percentage(diaz.Current, 1200);
        F.Info("Diazepam: " + diazPercent + " (" + diazCurrent + " left)", 200, 20);
      }
    });
    
    // Returns the current rate of O2 loss, where 4096 is equivalent to 1/frame
    F.CurrentO2Rate = (Func<int>)(() => {
      int result;
      if (M["Progress"].Current > 247) result = D.Sets.O2Rates["s16d-ambush"];
      else D.Sets.O2Rates.TryGetValue(M["Location"].Current, out result);

      int divisor = 1;
      if (M["EquippedItem"].Current == 7)
        D.Sets.O2MaskDivisors.TryGetValue(M["Location"].Current, out divisor);

      if (result == 0) result = 2048;
      if (divisor == 0) divisor = 1;

      return (int)((decimal)result / divisor);
    });
    
    // Sets [vars.Info] to <message> and starts a timer for <timeout> milliseconds
    // Only happens if the <priority> is equal/higher than the current message
    F.Info = (Action<string, int, int>)((message, timeout, priority) => {
      if ( (settings["Opt.ASL.Info"]) && (priority >= V.InfoPriority) ) {
        vars.Info = message;
        V.InfoTimeout = DateTime.Now.AddMilliseconds(timeout);
        V.InfoPriority = priority;
      }
    });
    
    F.SetVar = (Action<string, object>)((key, val) => {
      var varsDict = vars as IDictionary<string, object>;
      varsDict[key] = val;
      if (settings["Opt.ASL.Info.Alt." + key]) {
        V.InfoFallback = val;
        if (V.InfoPriority == -1)
          vars.Info = val;
      }
    });
    
    // Resets [vars.Info] to an empty string or to the fallback
    // once the info timeout has elapsed
    F.CheckInfoTimeout = (Action)(() => {
      if (settings["Opt.ASL.Info"]) {
        if ( (V.InfoTimeout != null) && (V.InfoTimeout < DateTime.Now) ) {
          vars.Info = (settings["Opt.ASL.Info.Alt"]) ? V.InfoFallback : String.Empty;
          V.InfoTimeout = null;
          V.InfoPriority = -1;
        }
      }
    });

    // Adds an entry to the FPS log and update the display of [vars.FPS]
    F.UpdateFPSCounter = (Action)(() => {
      var curTime = DateTime.UtcNow;
      var curFrames = M["Frames"].Current;
      
      // Remove a minute of logs when it gets bigger than 3 minutes
      // (keeping the opening few logs intact for the whole-run entry)
      int fpsCt = G.FpsLog.Count;
      if (fpsCt > 180) {
        G.FpsLog.RemoveRange(5, 60);
        fpsCt -= 60;
      }
      
      G.FpsLog.Add( new Tuple<DateTime, uint>(curTime, curFrames) );
      
      var fpsResults = new List<string>();
      string fpsFormat = settings["Opt.ASL.FPS.2DP"] ? "0.00" : "0.0";
      
      var periods = new int[] { 1, 5, 15, 60, -1 };
      foreach (var p in periods) {
        if (!settings["Opt.ASL.FPS." + p]) continue;
        
        Tuple<DateTime, uint> thisFps;
        string stringFormat = "{0:" + fpsFormat + "} ";
        if (p == -1) {
          // Use a later starting log because the 1st few get hit hard by 60fps running
          thisFps = G.FpsLog[4]; 
          stringFormat += "(Run)";
        }
        else {
          if (fpsCt <= p) break;
          thisFps = G.FpsLog[fpsCt - p];
          stringFormat += "({1}s)";
        }
        
        double fpsResult = ((curFrames - thisFps.Item2) / ((double)(curTime - thisFps.Item1).Ticks / 10000000));
        fpsResults.Add( string.Format(stringFormat, fpsResult, p) );
      }
      
      F.SetVar("FPS", string.Join(", ", fpsResults));
    });
    
    // Returns true if the setting <key> has changed
    F.ToolSettingToggled = (Func<string, bool>)((key) => {
      string extra;
      if (key == null) {
        extra = "";
        key = "Tools";
      }
      else extra = "." + key;
      
      bool result = ( (settings["Tools" + extra]) != V.LastToggleSetting[key] );
      V.LastToggleSetting[key] = settings["Tools" + extra];
      return result;
    });
    
    // Returns the contents for a new custom settings config file
    // using the current list of settings as source
    F.CustomSettingTemplate = (Func<string>)(() => {
      string output = "";
      foreach (var s in V.AllSettings) {
        output += F.SettingEnabled(s) ? "+" : "-";
        output += s + "\n";
      }
      return output;
    });
    
    // Show the form for the split file generator
    F.ShowMajorSplitsForm = (Action)(() => {
      var leftRight = AnchorStyles.Left | AnchorStyles.Right;
      var stretch = leftRight | AnchorStyles.Top | AnchorStyles.Bottom;
      
      using (var majorSplitsForm = new Form() {
        Size = new System.Drawing.Size(540, 500),
        FormBorderStyle = FormBorderStyle.FixedSingle,
        MaximizeBox = false,
        Text = "Build Split Files for Current Settings",
      }) {
        
        var flp = new TableLayoutPanel() {
          Width = majorSplitsForm.Width - 20,
          Height = majorSplitsForm.Height - 20,
          ColumnCount = 2,
          RowCount = 6,
          Padding = new Padding(10),
        };
        flp.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 55));
        flp.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 45));
        
        var chkVeryEasy = new CheckBox() {
          Text = "Build additional files for Very Easy difficulty",
          Anchor = leftRight,
        };

        var chkTemplate = new CheckedListBox() {
          Anchor = stretch,
          Height = 300,
          Enabled = false,
        };

        var lblSelected = new ListBox() {
          Anchor = stretch,
          Height = 300,
          Enabled = false,
        };
        
        var chkCreateSubsplits = new CheckBox() {
          Text = @"Build additional ""Subsplits"" files (splits organised into sections, requires Subsplits layout component)",
          Anchor = leftRight,
        };
        chkCreateSubsplits.CheckedChanged += (EventHandler)((sender, e) => {
          chkTemplate.Enabled = lblSelected.Enabled = ((CheckBox)sender).Checked;
        });
        
        var lblSubsplitsInfo = new Label() {
          Text = "All new Split Files will only contain splits that are part of the category, even if they're enabled in settings.",
          Anchor = stretch,
        };
        
        var isChecked = new Dictionary<string, bool>();
        if (File.Exists(V.MajorSplitsFile)) {
          string[] majorSplits = File.ReadAllLines(V.MajorSplitsFile);
          foreach (string line in majorSplits) {
            isChecked[line] = true;
          }
        }
        
        chkTemplate.DisplayMember = "Value";
        chkTemplate.ValueMember = "Key";
        chkTemplate.CheckOnClick = true;

        foreach (var split in D.Sets.AllSplits) {
          if (F.SettingEnabled(split)) {
            string splitName = D.Names.SplitSetting.ContainsKey(split) ?
              D.Names.SplitSetting[split] : "Unknown splitname";
            bool splitChecked = (F.DictIsTrue(isChecked, split));
            chkTemplate.Items.Add(
              new KeyValuePair<string, string>(split, splitName), splitChecked);
          }
        }
        
        var updateLblSelected = (Action)(() => {
          lblSelected.Items.Clear();
          foreach (KeyValuePair<string, string> checkedItem in chkTemplate.CheckedItems)
            lblSelected.Items.Add(checkedItem.Value);
        });
        updateLblSelected();
        chkTemplate.SelectedIndexChanged += (EventHandler)((sender, e) =>
          updateLblSelected() );
        
        var btnConfirm = new Button() {
          Text = "Save To Folder",
          Width = 100,
          Anchor = AnchorStyles.Top | AnchorStyles.Right,
        };
        btnConfirm.Click += (EventHandler)((sender, e) => {
          var enabledMajors = new List<string>();
          foreach (KeyValuePair<string, string> majorSplit in chkTemplate.CheckedItems)
            enabledMajors.Add(majorSplit.Key);
          
          F.GenerateSplitFiles(enabledMajors, chkCreateSubsplits.Checked, chkVeryEasy.Checked);
        });
        
        var txtSelectHeader = new Label() {
          Text = "Subsplits: Last split for each section",
          TextAlign = System.Drawing.ContentAlignment.BottomCenter,
          Anchor = leftRight,
        };
        txtSelectHeader.Font = new System.Drawing.Font(txtSelectHeader.Font, System.Drawing.FontStyle.Bold);
        
        var txtSelectedHeader = new Label() {
          Text = "Selected sections",
          TextAlign = System.Drawing.ContentAlignment.BottomCenter,
          Anchor = leftRight,
        };
        txtSelectedHeader.Font = new System.Drawing.Font(txtSelectedHeader.Font, System.Drawing.FontStyle.Bold);
        
        flp.Controls.Add(lblSubsplitsInfo);
        flp.SetColumnSpan(lblSubsplitsInfo, 2);
        flp.Controls.Add(chkVeryEasy);
        flp.SetColumnSpan(chkVeryEasy, 2);
        flp.Controls.Add(chkCreateSubsplits);
        flp.SetColumnSpan(chkCreateSubsplits, 2);
        flp.Controls.Add(txtSelectHeader);
        flp.Controls.Add(txtSelectedHeader);
        flp.Controls.Add(chkTemplate);
        flp.Controls.Add(lblSelected);
        flp.Controls.Add(btnConfirm);
        flp.SetColumnSpan(btnConfirm, 2);
        
        majorSplitsForm.Controls.Add(flp);
        majorSplitsForm.ShowDialog();
      }
    });
    
    // Generates and save a set of split files for the current settings
    // Called by F.ShowMajorSplitsForm
    F.GenerateSplitFiles = (Action<List<string>, bool, bool>)(
      (enabledMajors, createSubsplits, createVeryEasy) => {
      
      bool save = false;
      using(var fbd = new FolderBrowserDialog()) {
        fbd.Description = "Building a custom set of split files matching your settings.\nSave split files to:";
        fbd.SelectedPath = V.SplitFileDir;
        DialogResult result = fbd.ShowDialog();
        if (result == DialogResult.OK && !string.IsNullOrWhiteSpace(fbd.SelectedPath))
        {
          save = true;
          V.SplitFileDir = fbd.SelectedPath;
        }
      }
      
      if (save) {
        
        F.WriteFile(V.MajorSplitsFile, string.Join("\n", enabledMajors), false);
                
        string splitFileWrapper = @"<?xml version=""1.0"" encoding=""UTF-8""?>
<Run version=""1.7.0"">
  <GameIcon />
  <GameName>Metal Gear Solid</GameName>
  <CategoryName>{0}</CategoryName>
  <Metadata>
    <Run id="""" />
    <Platform usesEmulator=""{1}""></Platform>
    <Region>
    </Region>
    <Variables>
    </Variables>
  </Metadata>
  <Offset>00:00:00</Offset>
  <AttemptCount>0</AttemptCount>
  <AttemptHistory />
  <Segments>
{2}
  </Segments>
  <AutoSplitterSettings />
</Run>";

  string splitFileEntry = @"    <Segment>
      <Name>{0}</Name>
      <Icon />
      <SplitTimes>
        <SplitTime name=""Personal Best"" />
      </SplitTimes>
      <BestSegmentTime />
      <SegmentHistory />
    </Segment>
";

        var filesToWrite = new Dictionary<string, string>();
        var filesToClobber = new HashSet<string>();

        var addFileToList = (Action<string, string>)((fileName, fileContent) => {
          fileName = V.SplitFileDir + "\\Metal Gear Solid - " + fileName + ".lss";
          filesToWrite.Add(fileName, fileContent);
          if (File.Exists(fileName))
            filesToClobber.Add(fileName);
        });
      
        foreach (var category in D.Sets.Category) {
          
          var catName = category.Key;
          string usesEmu = catName.Substring(0, 7).Equals("Console") ? "True" : "False";
          var splits = new List<string>();
          string output = String.Empty;
          string output2 = String.Empty;
          string output1VE = String.Empty;
          string output2VE = String.Empty;
          
          foreach (var split in category.Value)
            splits.AddRange(D.Sets.Split[split]);
            
          foreach (var split in splits) {
            if (settings[split]) {
              string splitName = D.Names.Split[split];
              if (splitName.Equals("Score")) {
                output1VE = output;
                output2VE = output2;
              }
              output2 += string.Format(splitFileEntry, splitName);
              
              if (enabledMajors.Contains(split)) {
                string majorCode = "M." + split;
                if (D.Names.Split.ContainsKey(majorCode))
                  splitName = D.Names.Split[majorCode];
              }
              else splitName = "-" + splitName;
              output += string.Format(splitFileEntry, splitName);
            }
          }
          
          output = string.Format(splitFileWrapper, catName, usesEmu, output);
          output2 = string.Format(splitFileWrapper, catName, usesEmu, output2);
          output1VE = string.Format(splitFileWrapper, catName, usesEmu, output1VE);
          output2VE = string.Format(splitFileWrapper, catName, usesEmu, output2VE);
          
          addFileToList(catName, output2);
          if (createVeryEasy)
            addFileToList(catName + " (Very Easy)", output2VE);
          
          if (createSubsplits) {
            addFileToList(catName + " (Subsplits)", output);
            if (createVeryEasy)
              addFileToList(catName + " (Very Easy + Subsplits)", output1VE);
          }
        }
        
        if (filesToWrite.Count != 0) {
          bool clobberFiles = true;
        
          if (filesToClobber.Count != 0) {
            string clobberString = string.Join("\n", filesToClobber);
            var clobberResult = MessageBox.Show("These files already exist and will be overwritten. Continue?\n\n" + clobberString, "Overwrite existing files?", MessageBoxButtons.OKCancel, MessageBoxIcon.Warning);
            clobberFiles = (clobberResult == DialogResult.OK);
          }
          
          if (clobberFiles) {
            foreach (var file in filesToWrite)
              F.WriteFile(file.Key, file.Value, false);
              
            F.Debug("Wrote " + filesToWrite.Count() + " split files:\n" + string.Join("\n", filesToWrite.Keys));
        
            var goToNewFiles = MessageBox.Show("Built split files at " + V.SplitFileDir + ".\n\nOpen this directory?", "Custom split files created", MessageBoxButtons.YesNo, MessageBoxIcon.Information);
            if (goToNewFiles == DialogResult.Yes)
              F.OpenExplorer(filesToWrite.First().Key, true);
          }
        }
        
      }
    });
    
    // Scans for a valid game within the current emulator process
    // and set up the list of memory watchers for that game
    F.ScanForGameInEmulator = (Func<Process, Process, ProcessModuleWow64Safe[], bool>)((g, mem, mod) => {
      if (G.BaseAddress == IntPtr.Zero) {

        foreach (var emulator in G.Emulators) {

          if (emulator.CheckMappedMemory) {
            foreach (var page in g.MemoryPages(true)) {
              if ((page.RegionSize != (UIntPtr)0x200000) || (page.Type != MemPageType.MEM_MAPPED))
                continue;
              G.BaseAddress = page.BaseAddress;
              break;
            }

            if (G.BaseAddress != IntPtr.Zero) {
              if (emulator.Platform != null) vars.Platform = emulator.Platform;
              break;
            }
          }

          if (emulator.ModuleNames != null) {
            foreach (var module in emulator.ModuleNames) {
              emulator.Module = mod.Where(m => m.ModuleName == module).FirstOrDefault();
              if (emulator.Module != null) break;
            }
          }

          if (emulator.Module == null) continue;

          if (emulator.BaseOffset != null) {
            G.BaseAddress = IntPtr.Add(emulator.Module.BaseAddress, emulator.BaseOffset);
            break;
          }

          if (!game.Is64Bit()) continue;
          if (emulator.Signature == null) continue;

          var sigTarget = new SigScanTarget(emulator.SignatureOffset, emulator.Signature);
          var sigScanner = new SignatureScanner(g, emulator.Module.BaseAddress, (int)emulator.Module.ModuleMemorySize);
          IntPtr codeOffset = sigScanner.Scan(sigTarget);

          if (emulator.DerefLevel == 0) {
            G.BaseAddress = (IntPtr)mem.ReadValue<int>(codeOffset);
          }
          else {
            int memoryReference = (int)((long)mem.ReadValue<int>(codeOffset) + (long)codeOffset + 4 -(long)emulator.Module.BaseAddress);

            var deepPointer = (emulator.DerefLevel == 1) ?
              new DeepPointer(emulator.Module.ModuleName, memoryReference) :
              new DeepPointer(emulator.Module.ModuleName, memoryReference, 0);

            IntPtr outOffset;
            deepPointer.DerefOffsets(g, out outOffset);
            G.BaseAddress = outOffset;
          }

          if (G.BaseAddress != IntPtr.Zero) {
            if (emulator.Platform != null) vars.Platform = emulator.Platform;
            break;
          }
        }
        
        if (G.BaseAddress == IntPtr.Zero) return false;
        
        if (G.BaseAddress != G.OldBaseAddress)
          F.Debug("Found " + vars.Platform + " PSX MainRAM at " + G.BaseAddress.ToString("X"));
      }

      // Should have found the emu by now
      
      string productCode = null;
      string productName = null;
      string strHeader = null;
      byte[] memHeader = mem.ReadBytes((IntPtr)F.Addr(0x10000), 0x30);
      if (memHeader != null) {
        strHeader = System.Text.Encoding.UTF8.GetString(memHeader);
        
        foreach (var v in D.Names.PSXVersion) {
          if (strHeader.IndexOf(v.Key) != -1) {
            productCode = v.Key;
            break;
          }
        }
      }
      
      if (productCode == null) {
        G.ProductCode = null;
        G.OldBaseAddress = G.BaseAddress;
        G.BaseAddress = IntPtr.Zero;
        return false;
      }
      
      // Check for PSX Integral VR
      if (productCode.Equals("SLPM-86247")) {
        if (strHeader.Substring(0, 11).Equals("SLPM_862.49"))
          productCode = "SLPM-86249";
      }
      
      // We definitely have a supported game at this point

      if (!productCode.Equals(G.ProductCode)) {
        // Game has changed, or first time we found a game
        
        // Check for PSX MGS JP
        // (difficulty always Easy so we don't have to look for boss max health)
        if (productCode.Equals("SLPM-86111"))
          G.JP = true;
        
        // Check for an EU game (50Hz for timing adjustments)
        if ( productCode.Equals("SLES-01370") || productCode.Equals("SLES-02136") )
          G.EU = true;
        
        G.ProductCode = productCode;
        vars.Version = D.Names.PSXVersion[productCode];
        var addrs = D.Sets.PSXAddresses[productCode];
        
        F.Debug("Found supported game " + vars.Version);

        if (addrs.ContainsKey("Score")) {
          G.VRMissions = true;
          
          G.CurrentMemoryWatchers = new MemoryWatcherList() {
            new StringWatcher(F.Addr(addrs["Location"]), 8) { Name = "Location" },
            new MemoryWatcher<int>(F.Addr(addrs["Score"])) { Name = "Score" },
          };
          G.HiddenMemoryWatchers = new MemoryWatcherList() {
            new MemoryWatcher<uint>(F.Addr(addrs["Frames"])) { Name = "Frames" },
            new MemoryWatcher<byte>(F.Addr(addrs["LevelState"])) { Name = "LevelState" },
          };
          G.CodeMemoryWatchers = new Dictionary<string, MemoryWatcherList>();
        }
        else {
          G.CurrentMemoryWatchers = new MemoryWatcherList() {
            new MemoryWatcher<short>(F.Addr(addrs["Alerts"])) { Name = "Alerts" },
            new MemoryWatcher<short>(F.Addr(addrs["Kills"])) { Name = "Kills" },
            new MemoryWatcher<short>(F.Addr(addrs["RationsUsed"])) { Name = "RationsUsed" },
            new MemoryWatcher<short>(F.Addr(addrs["Continues"])) { Name = "Continues" },
            new MemoryWatcher<short>(F.Addr(addrs["Saves"])) { Name = "Saves" },

            new MemoryWatcher<uint>(F.Addr(addrs["GameTime"])) { Name = "GameTime" },
            new MemoryWatcher<sbyte>(F.Addr(addrs["Difficulty"])) { Name = "Difficulty" },
            new MemoryWatcher<short>(F.Addr(addrs["Progress"])) { Name = "Progress" },
            new MemoryWatcher<short>(F.Addr(addrs["Life"])) { Name = "Life" },
            new MemoryWatcher<short>(F.Addr(addrs["MaxLife"])) { Name = "MaxLife" },
            new StringWatcher(F.Addr(addrs["Location"]), 8) { Name = "Location" },
          };

          G.HiddenMemoryWatchers = new MemoryWatcherList() {
            new MemoryWatcher<sbyte>(F.Addr(addrs["InMenu"])) { Name = "InMenu" },
            new MemoryWatcher<sbyte>(F.Addr(addrs["VsRex"])) { Name = "VsRex" },
            new MemoryWatcher<uint>(F.Addr(addrs["ControllerInput"])) { Name = "ControllerInput" },
            new MemoryWatcher<uint>(F.Addr(addrs["Frames"])) { Name = "Frames" },
            new MemoryWatcher<byte>(F.Addr(addrs["NoControl"])) { Name = "NoControl" },
            new MemoryWatcher<short>(F.Addr(addrs["DiazepamTimer"])) { Name = "DiazepamTimer" },
            new MemoryWatcher<short>(F.Addr(addrs["ChaffTimer"])) { Name = "ChaffTimer" },
            new MemoryWatcher<short>(F.Addr(addrs["O2Timer"])) { Name = "O2Timer" },
            new MemoryWatcher<byte>(F.Addr(addrs["EquippedItem"])) { Name = "EquippedItem" },
          };
          
          MM.Clear();
          MM.Add("WeaponData", New.ByteArray(F.Addr(addrs["WeaponData"]), 22));
          MM.Add("ItemData", New.ByteArray(F.Addr(addrs["ItemData"]), 46));
       
          G.CodeMemoryWatchers = new Dictionary<string, MemoryWatcherList>() {
            { "CP-6", new MemoryWatcherList() { // Dock
              new MemoryWatcher<short>(F.Addr(addrs["ElevatorTimer"])) { Name = "ElevatorTimer" } } },
            { "CP-38", new MemoryWatcherList() { // Ocelot
              new MemoryWatcher<short>(F.Addr(addrs["OcelotHP"])) { Name = "BossHP" } } },
            { "CP-77", new MemoryWatcherList() { // Ninja
              new MemoryWatcher<short>(F.Addr(addrs["NinjaHP"])) { Name = "BossHP" } } },
            { "CP-129", new MemoryWatcherList() { // Mantis
              new MemoryWatcher<short>(F.Addr(addrs["MantisHP"])) { Name = "BossHP" } } },
            { "CL-s10a.CP-150", new MemoryWatcherList() { // Wolf 1
              new MemoryWatcher<short>(F.Addr(addrs["Wolf1HP"])) { Name = "BossHP" } } },
            { "CP-186", new MemoryWatcherList() { // Hind
              new MemoryWatcher<short>(F.Addr(addrs["HindHP"])) { Name = "BossHP" } } },
            { "CP-197", new MemoryWatcherList() { // Wolf 2
              new MemoryWatcher<short>(F.Addr(addrs["Wolf2HP"])) { Name = "BossHP" } } },
            { "CP-211", new MemoryWatcherList() { // Raven
              new MemoryWatcher<short>(F.Addr(addrs["RavenHP"])) { Name = "BossHP" } } },
            { "CP-255", new MemoryWatcherList() { // Rex 1
              new MemoryWatcher<short>(F.Addr(addrs["Rex1HP"])) { Name = "BossHP" } } },
            { "CP-257", new MemoryWatcherList() { // Rex 2
              new MemoryWatcher<short>(F.Addr(addrs["Rex2HP"])) { Name = "BossHP" } } },
            { "CP-277", new MemoryWatcherList() { // Liquid
              new MemoryWatcher<short>(F.Addr(addrs["LiquidHP"])) { Name = "BossHP" } } },
            { "CL-s19b", new MemoryWatcherList() { // Escape 2
              new MemoryWatcher<short>(F.Addr(addrs["EscapeHP"])) { Name = "BossHP" },
              new MemoryWatcher<byte>(F.Addr(addrs["RadarState"])) { Name = "RadarState" } } },
            { "CP-294", new MemoryWatcherList() { // Score
              new MemoryWatcher<byte>(F.Addr(addrs["ScoreState"])) { Name = "ScoreState" } } },
          };
          
          foreach (var boss in new Dictionary<string, string>() {
            { "CP-129", "Mantis" }, { "CP-211", "Raven" }, { "CP-255", "Rex" },
            { "CP-257", "Rex" }
          }) {
            string key = boss.Value + "MaxHP";
            if (addrs.ContainsKey(key))
              G.CodeMemoryWatchers[boss.Key].Add(
                new MemoryWatcher<short>(F.Addr(addrs[key])) { Name = "BossMaxHP" }
              );
          }
        }
        
        F.ResetMemoryVars();
        F.ResetRunVars();
        
      }
      
      return true;
    });
    // init: Function definitions END
    
    
    /****************************************************/
    /* init: Split Checkers and Watchers
    /* Checkers add extra restrictions on a split
    /*  * TRUE = split, FALSE = no split
    /* Watchers run every frame while a signature is active
    /*  * 1 = split, 0 = no split, -1 = don't retry
    /****************************************************/
    
    // Define Checkers for the basic Split Modifiers
    // These change a regular Split Point to use a different signature
    // The original Split Point must still be enabled
    foreach (var m in D.Sets.SplitModifiers) {
      F.Check.Add(m.Key, (Func<bool>)(() => F.SettingEnabled(m.Value)));
      F.Check.Add(m.Value, (Func<bool>)(() => !F.SettingEnabled(m.Key)));
    }
    
    Func<string, bool> backtrackSplit = (undoKey) => {
      if ( (!settings["Opt.Behaviour.UndoPAL"]) || (!settings[undoKey]) ||
        (!R.LatestSplits.Peek().Equals(undoKey)) )
        return true;
      F.UndoSplit("Undoing split for " + undoKey + " (backtrack)");
      R.LatestSplits.Pop();
      R.CompletedSplits.Remove(undoKey);
      return false;
    };
    
    // Dock: Add elevator timer to [vars.Info]
    F.Watch.Add("W.CP-6", (Func<int>)(() => {
      if (!settings["Opt.ASL.Info.Dock"]) return 0;

      var cur = M["ElevatorTimer"].Current;
      int max = G.JP ? 3150 : 3600;
      int delta = (M["ElevatorTimer"].Old - cur);

      // When the timer goes up, check if it's near the max
      // If so, set a variable to 1 to enable info (and vice versa)
      if (delta < 0)
        R.EscapeRadarTimes = (F.Between(cur, max - 30, max)) ? 1 : 0;
      if (R.EscapeRadarTimes == 0) return 0;

      string seconds = F.FramesToSeconds(cur);
      string percent = F.Percentage((max - cur), max);
      F.Info("Elevator: " + percent + " (" + seconds + " left)", 1000, 10);

      // Show 100% for one iteration, then disable info
      if (cur == 0) R.EscapeRadarTimes = 0;

      return 0;
    }));
    
    // Cell (All Bosses): Split entering vent to Darpa Chief
    F.Watch.Add("W.CL-s03a.CP-18", (Func<int>)(() => 
      ( (M["NoControl"].Current & 0x40) == 0x40 ) ? 1 : 0));
      
    // Cell (vent clip): Undo the AB split if that happened accidentally
    F.Check.Add("OL-s03a.CL-s03c.CP-VentClip", (Func<bool>)(() =>
      backtrackSplit("W.CL-s03a.CP-18") || true ));

    // Helpers for Nikita unlock status
    Func<bool> hasNikita = () => F.HasWeapon(4);
    Func<bool> hasNoNikita = () => !F.HasWeapon(4);
    
    // Nuke Building B2: Must have Nikita (except if we're doing area reloading)
    F.Check.Add("CL-s08a.CP-69", (Func<bool>)(() =>
      ( (!G.Emulator) && (M["CheatsEnabled"].Current) ) ? true : hasNikita() ));

    // Nuke Building B1: Undo any B2 split if we don't have Nikita yet
    F.Check.Add("CL-s07a.CP-69", (Func<bool>)(() => {
      if (hasNoNikita()) backtrackSplit("CL-s08a.CP-69");
      return true;
    }));

    // Helpers for PSG1 unlock status
    Func<bool> hasPSG1 = () => F.HasWeapon(10);
    Func<bool> hasNoPSG1 = () => !F.HasWeapon(10);

    // Return to Sniper Wolf 1: Must have PSG1
    F.Check.Add("OL-s04a.CL-s02e.CP-150", (Func<bool>)(() =>
      !R.CompletedSplits.ContainsKey("OL-s03a.CL-s02e.CP-150") && hasPSG1() )); // Armory -> Tank Hangar
    F.Check.Add("OL-s03a.CL-s02e.CP-150", (Func<bool>)(() =>
      !R.CompletedSplits.ContainsKey("OL-s04a.CL-s02e.CP-150") && hasPSG1() )); // Cell -> Tank Hangar
    F.Check.Add("OL-s02e.CL-s05a.CP-150", hasPSG1); // Tank Hangar -> Canyon
    F.Check.Add("OL-s05a.CL-s06a.CP-150", hasPSG1); // Canyon -> NB1F
    F.Check.Add("OL-NukeBuilding.CL-s07a.CP-150", hasPSG1); // NB1F -> NBB1
    F.Check.Add("OL-s07a.CL-s07b.CP-150", hasPSG1); // NBB1 -> Cmdr's Room
    F.Check.Add("OL-s07b.CL-s09a.CP-150", hasPSG1); // Cmdr's Room -> Cave
    F.Check.Add("OL-s09a.CL-s10a.CP-150", hasPSG1); // Cave -> UG Passage
    
    // Leave Cell after Escape: Require extra Armory trip in Any% to collect PSG1
    F.Check.Add("OL-TankHangar.CL-s04a.CP-163", hasNoPSG1); // Cell -> Armory
    F.Check.Add("OL-TankHangar.CL-s02e.CP-163", (Func<bool>)(() =>
      ( hasPSG1() && (R.CompletedSplits.ContainsKey("OL-TankHangar.CL-s04a.CP-163")) ) )); // Cell/Armory -> Tank Hangar
    
    // Cell/Armory -> Tank Hangar: All Bosses version
    F.Check.Add("OL-TankHangar.CL-s02e.CP-ABEscape", (Func<bool>)(() =>
      ( hasPSG1() && (!R.CompletedSplits.ContainsKey("OL-TankHangar.CL-s04a.CP-163")) ) ));

    // CTA Boba skip: Skip the splits for CTA Roof and Rappel if necessary
    F.Check.Add("OL-s11a.CL-s11i.CP-AfterEscape", (Func<bool>)(() => {
      string name;

      if (settings["Opt.Behaviour.KevinSkipSplits"]) {
  
        foreach (var split in D.Sets.Split["CommTowerA-Rappel"]) {
          if (F.SettingEnabled(split)) {
            name = (D.Names.Split.ContainsKey(split)) ?
              " (" + F.StripSubsplitFormatting(D.Names.Split[split]) + ")" : "";
            F.SkipSplit("Skipping split for " + split + name + " (Boba skip)");
          }
        }

      }

      string originalCode = "OL-s11a.CL-s11b.CP-DefeatCTAChase";
      if (F.SettingEnabled(originalCode)) {
        name = (D.Names.Split.ContainsKey(originalCode)) ?
          " (" + F.StripSubsplitFormatting(D.Names.Split[originalCode]) + ")" : "";
        F.ManualSplit("Splitting for " + originalCode + name + " (Boba skip)");
      }

      return false;
    }));
    
    // Helpers for Stinger unlock status
    Func<bool> hasStinger = () => F.HasWeapon(5);
    Func<bool> hasNoStinger = () => !F.HasWeapon(5);
    Func<bool> hasStingerInConsoleAny = () => (R.CompletedSplits.ContainsKey("OL-s11c.CL-s11i.CP-204") && F.HasWeapon(5));

    // CTB Roof -> CTB, before Hind: Only split in Console Any%
    F.Check.Add("OL-s11h.CL-s11c.CP-CommTowerB", (Func<bool>)(() => (
      (hasNoStinger()) || (M["Progress"].Current.Equals(190)) ) ));

    // Console Any% Stinger collection after Sniper Wolf 2
    F.Check.Add("OL-Snowfield.CL-s11c.CP-204", hasNoStinger); // Snowfield -> CTB
    F.Check.Add("OL-s11c.CL-s11i.CP-204", hasNoStinger); // CTB -> CTB Roof
    F.Check.Add("OL-s11i.CL-s11c.CP-204", hasStingerInConsoleAny); // CTB Roof -> CTB
    F.Check.Add("OL-s11c.CL-Snowfield.CP-204", hasStingerInConsoleAny); // CT -> Snowfield
    
    // Helpers for PAL Card status
    Func<bool> wasInColdRoom = () => R.CompletedSplits.ContainsKey("OL-s15a.CL-s15b.CP-240");
    Func<bool> wasInHotRoom = () => R.CompletedSplits.ContainsKey("OL-s13a.CL-s14e.CP-HeatingKey");

    // Warehouse North -> Warehouse (PAL Key): Split on Warehouse start (later)
    // On Console with Split Modifier only
    F.Watch.Add("W.CL-s15a.CP-240", (Func<int>)(() => {
      if ( (!G.Emulator) || (!F.SettingEnabled("OL-s15b.CL-s16a.CP-240") )) return -1;
      return (M["VsRex"].Current == 1) ? 1 : 0;
    }));
    F.Check.Add("OL-s15b.CL-s15a.CP-240", (Func<bool>)(() => {
      if (!backtrackSplit("OL-s15a.CL-s15b.CP-240")) return false;
      return ( (!G.Emulator) || (!F.SettingEnabled("W.CL-s15a.CP-240")) );
    }));
    
    // Travel with Cold PAL: Split only if was previously in Warehouse
    F.Check.Add("OL-s15b.CL-s16a.CP-240", wasInColdRoom); // Warehouse North -> UGB1
    F.Check.Add("OL-s16a.CL-s16b.CP-240", wasInColdRoom); // UGB1 -> UGB2
    F.Check.Add("OL-s16b.CL-s16c.CP-240", wasInColdRoom); // UGB2 -> UGB3
    F.Check.Add("OL-s16c.CL-s16d.CP-240", wasInColdRoom); // UGB3 -> Command Room
    
    // Travel with Cold PAL: Undo splits if going back to previous areas
    // todo automate same as split mods
    F.Check.Add("OL-s16a.CL-s15b.CP-240", (Func<bool>)(() => 
      backtrackSplit("OL-s15b.CL-s16a.CP-240"))); // UGB1 -> Warehouse North
    F.Check.Add("OL-s16b.CL-s16a.CP-240", (Func<bool>)(() => 
      backtrackSplit("OL-s16a.CL-s16b.CP-240"))); // UGB2 -> UGB1
    F.Check.Add("OL-s16c.CL-s16b.CP-240", (Func<bool>)(() => 
      backtrackSplit("OL-s16b.CL-s16c.CP-240"))); // UGB3 -> UGB2
    F.Check.Add("OL-s16d.CL-s16c.CP-240", (Func<bool>)(() => 
      backtrackSplit("OL-s16c.CL-s16d.CP-240"))); // Command Room -> UGB3

    // Cargo Elevator -> Blast Furnace (PAL Key): Split on Warehouse start (later)
    // On Console with Split Modifier only
    F.Watch.Add("W.CL-s13a.CP-HeatingKey", (Func<int>)(() => {
      if ( (!G.Emulator) || (!F.SettingEnabled("OL-s14e.CL-s13a.CP-HeatingKey")) )
        return -1;
      return (M["VsRex"].Current == 1) ? 1 : 0;
    }));
    F.Check.Add("OL-s14e.CL-s13a.CP-HeatingKey", (Func<bool>)(() => {
      if (!backtrackSplit("OL-s13a.CL-s14e.CP-HeatingKey")) return false;
      return ( (!G.Emulator) || (!F.SettingEnabled("W.CL-s13a.CP-HeatingKey")) );
    }));

    // Helper for PAL Key
    Func<bool> hasPal = () => F.HasItem(16);
    
    // Travel with Hot PAL: Split only if was previously in Blast Furnace
    F.Check.Add("OL-s14e.CL-s15c.CP-HeatingKey", wasInHotRoom); // Cargo Elevator -> Warehouse
    F.Check.Add("OL-s15c.CL-s15b.CP-HeatingKey", wasInHotRoom); // Warehouse -> Warehouse North
    F.Check.Add("OL-s15b.CL-s16a.CP-HeatingKey", wasInHotRoom); // Warehouse North -> UGB1
    F.Check.Add("OL-s16a.CL-s16b.CP-HeatingKey", wasInHotRoom); // UGB1 -> UGB2
    F.Check.Add("OL-s16b.CL-s16c.CP-HeatingKey", wasInHotRoom); // UGB2 -> UGB3
    F.Check.Add("OL-s16c.CL-s16d.CP-HeatingKey", wasInHotRoom); // UGB3 -> Command Room
    
    // Travel with Hot PAL: Undo splits if going back to previous areas
    F.Check.Add("OL-s15c.CL-s14e.CP-HeatingKey", (Func<bool>)(() => 
      backtrackSplit("OL-s14e.CL-s15c.CP-HeatingKey"))); // Command Room -> UGB3
    F.Check.Add("OL-s15b.CL-s15c.CP-HeatingKey", (Func<bool>)(() => 
      backtrackSplit("OL-s15c.CL-s15b.CP-HeatingKey"))); // UGB3 -> UGB2
    F.Check.Add("OL-s16a.CL-s15b.CP-HeatingKey", (Func<bool>)(() => 
      backtrackSplit("OL-s15b.CL-s16a.CP-HeatingKey"))); // UGB2 -> UGB1
    F.Check.Add("OL-s16b.CL-s16a.CP-HeatingKey", (Func<bool>)(() => 
      backtrackSplit("OL-s16a.CL-s16b.CP-HeatingKey"))); // UGB1 -> Warehouse North
    F.Check.Add("OL-s16c.CL-s16b.CP-HeatingKey", (Func<bool>)(() => 
      backtrackSplit("OL-s16b.CL-s16c.CP-HeatingKey"))); // Warehouse North -> Warehouse
    F.Check.Add("OL-s16d.CL-s16c.CP-HeatingKey", (Func<bool>)(() => 
      backtrackSplit("OL-s16c.CL-s16d.CP-HeatingKey"))); // Warehouse -> Cargo Elevator

    // Metal Gear REX Phase 1: [vars.Info] boss health and custom split
    F.Watch.Add("W.CP-255", (Func<int>)(() => {
      var cur = M["VsRex"].Current;
      var prev = M["VsRex"].Old;
      int maxHP = G.JP ? 1500 : M["BossMaxHP"].Current;

      if (cur == 1)
        F.BossHealth("Metal Gear REX", maxHP);
      
      if (G.Emulator)
        return ( ((cur == -1) || (cur == 0) || (cur == 2)) && (prev == 1) ) ? 1 : 0;
      return ( (cur == 0) && (prev == 1) ) ? 1 : 0;
    }));
    
    // Metal Gear REX Phase 2: [vars.Info] boss health and custom split
    F.Watch.Add("W.CP-257", (Func<int>)(() => {
      var cur = M["VsRex"].Current;
      var prev = M["VsRex"].Old;
      int maxHP = G.JP ? 1500 : M["BossMaxHP"].Current;

      if (cur == 1)
        F.BossHealth("Metal Gear REX", maxHP);
      
      if (G.Emulator)
        return ( ((cur == -1) || (cur == 0)) && (prev == 3) ) ? 1 : 0;
      return ( (cur == 0) && (prev == 1) ) ? 1 : 0;
    }));
    
    // Helper to manually split at a different signature if a split was missed
    F.BackupSplitCheck = (Func<string, string, bool>)((thisCode, originalCode) => {
      if ( (settings[originalCode]) && (!R.CompletedSplits.ContainsKey(originalCode)) ) {
        string name = (D.Names.Split.ContainsKey(originalCode)) ?
          " (" + F.StripSubsplitFormatting(D.Names.Split[originalCode]) + ")" : "";
        F.ManualSplit("Splitting for " + originalCode + name + " (backup at " + thisCode + ")");
        R.CompletedSplits.Add(originalCode, true);
        R.LatestSplits.Push(originalCode);
      }
      return false;
    });
    
    // Backup for Rex 2 if split is missed
    // This comes after the cutscene afterwards, so it's not perfect
    F.Check.Add("OP-257", (Func<bool>)(() => F.BackupSplitCheck(V.CurrentCheck, "W.CP-257")));
    
    // VE Escape
    F.Watch.Add("W.CL-s19b", (Func<int>)(() => {
      if ( (settings["Opt.ASL.Info.Boss"]) && (R.EscapeRadarTimes == 1) ) {
        int hp = M["BossHP"].Current;

        int diff = M["Difficulty"].Current;
        if (diff == -1) diff = 0;
        int hpPerPhase = (3 + diff);

        int phase = 16 - (hp & 0xf);
        int phaseRemain = 5 - phase;

        int maxHP = 5 * hpPerPhase;
        int curHP = (phaseRemain == -1) ? 0 : ((hpPerPhase * phaseRemain) + (hp >> 6) + 1);

        F.BossHealthCurrent("Liquid Snake", curHP, maxHP);
      }
      
      if ( (M["RadarState"].Current == 0x20) && (M["RadarState"].Old == 0) ) {
        F.Debug("Escape timer disappeared (" + ++R.EscapeRadarTimes + ")");
        if ( (!settings["CP-286"]) || (M["Difficulty"].Current != -1) ) return 0;
        if (R.EscapeRadarTimes == 2) return 1;
      }
      return 0;
    }));
    
    // VE Escape: Reset the radar disappearance count if continue
    F.Check.Add("OL-s19b-CL-s19a", (Func<bool>)(() => {
      R.EscapeRadarTimes = 0;
      return false;
    }));
    
    // Regular Escape
    F.Check.Add("CP-286", (Func<bool>)(() => 
      (!settings["W.CL-s19b"]) || (M["Difficulty"].Current != -1) ));
      
    // Score
    F.Watch.Add("W.CP-294", (Func<int>)(() => {
      var score = M["ScoreState"];
      if (G.Emulator)
        return ((score.Current == 7) && (score.Old != 7)) ? 1 : 0;
      var score2 = M["ScoreState2"].Current;
      return ( (score.Changed) && ((score.Current % 4) == M["Difficulty"].Current) && (score.Current == score2) ) ? 1 : 0;
    }));
    
    F.Watch.Add("W.CP-38", (Func<int>)(() => F.BossHealth("Revolver Ocelot", 1024)));
    F.Watch.Add("W.CP-77", (Func<int>)(() => F.BossHealth("Ninja", 255)));
    F.Watch.Add("W.CP-129", (Func<int>)(() => F.BossHealth("Psycho Mantis", G.JP ? 904 : M["BossMaxHP"].Current)));
    F.Watch.Add("W.CL-s10a.CP-150", (Func<int>)(() => F.BossHealth("Sniper Wolf", 1024)));
    F.Watch.Add("W.CP-186", (Func<int>)(() => F.BossHealth("Hind D", 1024)));
    F.Watch.Add("W.CP-197", (Func<int>)(() => F.BossHealth("Sniper Wolf", 1024)));
    F.Watch.Add("W.CP-211", (Func<int>)(() => F.BossHealth("Vulcan Raven", G.JP ? 600 : M["BossMaxHP"].Current)));
    F.Watch.Add("W.CP-277", (Func<int>)(() => F.BossHealth("Liquid Snake", 255)));
    // init: Split Checkers and Watchers END

  }
  
  
  F.ResetAllVars();
  
  string aslEnablePrompt = "Enable this in settings";;
  if (!settings["Opt.ASL.Info"]) vars.Info = aslEnablePrompt;
  if (!settings["Opt.ASL.Stats"]) vars.Stats = aslEnablePrompt;
  if (!settings["Opt.ASL.FPS"]) vars.FPS = aslEnablePrompt;
  if (!settings["Opt.ASL.Location"]) vars.Location = aslEnablePrompt;
  
  var emu = New.EmulatorSpec();
  var processName = game.ProcessName.ToLowerInvariant();

  if ((processName.Length > 10) && (processName.Substring(0, 11) == "duckstation")) {
    emu.CheckMappedMemory = true;
    vars.Platform = "DuckStation";
  }
  else switch (processName) {
    case "mgsi":
      G.Emulator = false;
      G.BaseAddress = (IntPtr)0x400000;
      G.ProductCode = "MGSI PC";
      vars.Platform = "PC";
      vars.Version = "MGS Integral (PC)";
      break;
    case "mgsvr":
      G.VRMissions = true;
      G.Emulator = false;
      G.BaseAddress = (IntPtr)0x400000;
      G.ProductCode = "MGSI PC";
      vars.Platform = "PC";
      vars.Version = "MGS Integral VR-Disc (PC)";
      break;
    case "epsxe":
      emu.Module = modules.First();
      emu.BaseOffset = 0xA82020;
      vars.Platform = "ePSXe";
      break;
    case "emuhawk":
      emu.ModuleNames = new string[] { "octoshock.dll" };
      emu.Signature = "49 03 c9 ff e1 48 8d 05 ?? ?? ?? ?? 48 89 02";
      emu.SignatureOffset = 8;
      emu.DerefLevel = 1;
      vars.Platform = "BizHawk (Mednafen)";
      break;
    case "mednafen":
      emu.Module = modules.First();
      emu.Signature = "48 c7 44 24 ?? ?? ?? ?? ?? 48 c7 44 24 ?? ?? ?? ?? ?? c7 44 24 ?? 00 00 20 00";
      emu.SignatureOffset = 5;
      vars.Platform = "Mednafen";
      break;
    case "retroarch":
      emu.ModuleNames = new string[] { "mednafen_psx_libretro.dll", "mednafen_psx_hw_libretro.dll" };
      emu.Platform = "RetroArch (Mednafen)";
      emu.Signature = "48 83 EC 28 85 C9 74 18 83 F9 02 B8 00 00 00 00 48 0F 44 05 ?? ?? ?? ?? 48 83 C4 ?? C3";
      emu.SignatureOffset = 20;
      emu.DerefLevel = 2;
      vars.Platform = "RetroArch";
      break;
    default:
      break;
  }

  F.Debug("Connected to platform " + vars.Platform);

  if (G.Emulator) {
    G.Emulators.Add(emu);
    return true;
  }
  
  // PC memwatchers
  if (G.VRMissions) {
    G.CurrentMemoryWatchers = new MemoryWatcherList() {
      new StringWatcher(F.Addr(0x25E4D0), 8) { Name = "Location" },
      new MemoryWatcher<int>(F.Addr(0x5A414C)) { Name = "Score" },
    };    
    G.HiddenMemoryWatchers = new MemoryWatcherList() {
      new MemoryWatcher<uint>(F.Addr(0x2CE5D8)) { Name = "Frames" },
      new MemoryWatcher<byte>(F.Addr(0x5A4150)) { Name = "LevelState" },
    };
    G.CodeMemoryWatchers = new Dictionary<string, MemoryWatcherList>();
  }
  else {
    G.CurrentMemoryWatchers = new MemoryWatcherList() {
      new MemoryWatcher<short>(F.Addr(0x38E87C)) { Name = "Alerts" },
      new MemoryWatcher<short>(F.Addr(0x38E87E)) { Name = "Kills" },
      new MemoryWatcher<short>(F.Addr(0x38E88C)) { Name = "RationsUsed" },
      new MemoryWatcher<short>(F.Addr(0x38E88E)) { Name = "Continues" },
      new MemoryWatcher<short>(F.Addr(0x38E890)) { Name = "Saves" },

      new MemoryWatcher<uint>(F.Addr(0x595344)) { Name = "GameTime" },
      new MemoryWatcher<sbyte>(F.Addr(0x38E7E2)) { Name = "Difficulty" },
      new MemoryWatcher<short>(F.Addr(0x38D7CA)) { Name = "Progress" },
      new MemoryWatcher<short>(F.Addr(0x38E7F6)) { Name = "Life" },
      new MemoryWatcher<short>(F.Addr(0x38E7F8)) { Name = "MaxLife" },
      new StringWatcher(F.Addr(0x2504CE), 8) { Name = "Location" },
    };

    G.HiddenMemoryWatchers = new MemoryWatcherList() {
      new MemoryWatcher<sbyte>(F.Addr(0x31D180)) { Name = "InMenu" },
      new MemoryWatcher<sbyte>(F.Addr(0x388630)) { Name = "VsRex" },
      new MemoryWatcher<uint>(F.Addr(0x3919C0)) { Name = "ControllerInput" },
      new MemoryWatcher<uint>(F.Addr(0x2BFF00)) { Name = "Frames" },
      new MemoryWatcher<byte>(F.Addr(0x32279F)) { Name = "NoControl" },
      new MemoryWatcher<bool>(F.Addr(0x5942B8)) { Name = "TimerActive" }, // maybe 594304 (opposite)
      new MemoryWatcher<short>(F.Addr(0x38E872)) { Name = "DiazepamTimer" },
      new MemoryWatcher<short>(F.Addr(0x391A28)) { Name = "ChaffTimer" },
      new MemoryWatcher<short>(F.Addr(0x595348)) { Name = "O2Timer" },
      new MemoryWatcher<byte>(F.Addr(0x38E7EA)) { Name = "ScoreState" },
      new MemoryWatcher<byte>(F.Addr(0x5942EC)) { Name = "ScoreState2" },
      new MemoryWatcher<bool>(F.Addr(0x31687C)) { Name = "CheatsEnabled" },
      new MemoryWatcher<byte>(F.Addr(0x38E7FE)) { Name = "EquippedItem" }, // equipped weapon 2B earlier
    };
    
    MM.Clear();
    MM.Add("WeaponData", New.ByteArray(F.Addr(0x38E800), 22));
    MM.Add("ItemData", New.ByteArray(F.Addr(0x38E82A), 46));
    
    G.CodeMemoryWatchers = new Dictionary<string, MemoryWatcherList>() {
      { "CP-6", new MemoryWatcherList() { // Dock
        new MemoryWatcher<short>(F.Addr(0x4F56AC)) { Name = "ElevatorTimer" } } },
      { "CP-38", new MemoryWatcherList() { // Ocelot
        new MemoryWatcher<short>(
          new DeepPointer(F.Addr(0x594124), 0x830) ) { Name = "BossHP" } } },
      { "CP-77", new MemoryWatcherList() { // Ninja
        new MemoryWatcher<short>(
          new DeepPointer(F.Addr(0x2BFD8C), 0x19E4) ) { Name = "BossHP" } } },
      { "CP-129", new MemoryWatcherList() { // Mantis
        new MemoryWatcher<short>(
          new DeepPointer(F.Addr(0x2BFE58), 0x900) ) { Name = "BossHP" },
        new MemoryWatcher<short>(F.Addr(0x283A58)) { Name = "BossMaxHP" } } },
      { "CL-s10a.CP-150", new MemoryWatcherList() { // Wolf 1
        new MemoryWatcher<short>(
          new DeepPointer(F.Addr(0x504464), 0xA40) ) { Name = "BossHP" } } },
      { "CP-186", new MemoryWatcherList() { // Hind
        new MemoryWatcher<short>(
          new DeepPointer(F.Addr(0x390BB8), 0x654) ) { Name = "BossHP" } } },
      { "CP-197", new MemoryWatcherList() { // Wolf 2
        new MemoryWatcher<short>(
          new DeepPointer(F.Addr(0x2BFD8C), 0xA40) ) { Name = "BossHP" } } },
      { "CP-211", new MemoryWatcherList() { // Raven
        new MemoryWatcher<short>(F.Addr(0x4E9A20)) { Name = "BossHP" },
        new MemoryWatcher<short>(F.Addr(0x4E97C8)) { Name = "BossMaxHP" } } },
      { "CP-255", new MemoryWatcherList() { // Rex 1
        new MemoryWatcher<short>(F.Addr(0x323906)) { Name = "BossHP" },
        new MemoryWatcher<short>(
          new DeepPointer(F.Addr(0x2BFDD0), new int[] { 0x5C4 }) ) { Name = "BossMaxHP" } } },
      { "CP-257", new MemoryWatcherList() { // Rex 2
        new MemoryWatcher<short>(F.Addr(0x323906)) { Name = "BossHP" },
        new MemoryWatcher<short>(F.Addr(0x38DBEE)) { Name = "BossMaxHP" } } },
      { "CP-277", new MemoryWatcherList() { // Liquid
        new MemoryWatcher<short>(F.Addr(0x50B978)) { Name = "BossHP" } } },
      { "CL-s19b", new MemoryWatcherList() { // Escape 2
        new MemoryWatcher<short>(F.Addr(0x3238BE)) { Name = "BossHP" },
        new MemoryWatcher<byte>(F.Addr(0x32279D)) { Name = "RadarState" } } },
    };
  }
  
  F.ResetMemoryVars();
  F.ResetRunVars();
}
// init END


/****************************************************/
/* update - Runs every frame while process is open
/****************************************************/
update {
  var D = vars.D; var F = D.Funcs; var G = D.Game; var M = D.Mem;
  var New = D.New; var R = D.Run;  var V = D.Vars; var MM = D.ManualMem;
  
  if (F.ToolSettingToggled(null))
    F.ShowToolsForm();

  F.CheckInfoTimeout();

  if (F.Increment()) { // F.Increment returns true if the second has changed
    refreshRate = settings["Opt.Behaviour.HalfFrameRate"] ? (V.BaseFPS / 2) : V.BaseFPS;

    if ( (settings["Opt.Debug.File"]) && (V.DebugLogBuffer.Count > 0) ) {
      F.WriteFile(V.DebugLogPath, string.Join("\n", V.DebugLogBuffer), true);
      V.DebugLogBuffer.Clear();
    }

    if (G.Emulator)
      if (!F.ScanForGameInEmulator(game, memory, modules)) return false;
  }
  
  if (G.BaseAddress == IntPtr.Zero) return false;
  
  if ( (settings["Opt.ASL.FPS"]) && (V.SecondIncremented) )
    F.UpdateFPSCounter();
  
  M.UpdateAll(game);
  F.UpdateMM(game);
  F.UpdateCurrent();
  
  if (G.VRMissions) return true;
  
  if (settings["Opt.ASL.Info"])
    F.UpdateASLInfo();

  if ( (settings["Opt.ASL.Stats"]) && (F.StatsChanged()) )
    F.UpdateASLStats();
    
}
// update END


/****************************************************/
// start - Runs when timer is stopped & decides when to start
/****************************************************/
start {
  var D = vars.D; var G = D.Game; var M = D.Mem;

  var Loc = M["Location"];
  if (G.VRMissions)
    return ( (Loc.Changed) && (!Loc.Current.Equals("vrtitle")) && (Loc.Old.Equals("selectvr")) );
  
  var Prog = M["Progress"]; var Menu = M["InMenu"];
  if ( (Prog.Current.Equals(1)) && (Prog.Changed) )
    return true;
  if ( (settings["Opt.Behaviour.StartOnLoad"]) && (Menu.Current.Equals(0)) && (Menu.Old.Equals(1)) )
    return true;
  
  return false;
}
// start END


/****************************************************/
// reset - Runs when timer is started & decides when to reset
/****************************************************/
reset {
  var D = vars.D; var G = D.Game; var M = D.Mem;

  var Loc = M["Location"];
  if (G.VRMissions)
    return ( (Loc.Changed) && (Loc.Current.Equals("vrtitle")) );

  var Menu = M["InMenu"];
  return ( (Menu.Changed) && (Menu.Current.Equals(1)) && (!M["Progress"].Current.Equals(294)) );
}
// reset END


/****************************************************/
// split - Runs when timer is started & decides when to split
/****************************************************/
split {
  var D = vars.D; var F = D.Funcs; var G = D.Game; var M = D.Mem;
  var New = D.New; var R = D.Run; var V = D.Vars; var MM = D.ManualMem;
  
  var Loc = M["Location"];

  // Check for level completion or location change in VR and split if necessary
  if (G.VRMissions) {
    if ( (R.VrSplitOnExit) && (Loc.Changed) ) {
      R.VrSplitOnExit = false;
      F.ManualSplit("VR Mission complete: " + Loc.Old);
      return false;
    }
    var VrScore = M["Score"];
    var VrState = M["LevelState"];
    bool VrSplit = false;
    if ( (VrScore.Current != 0) && (VrScore.Old == 0) ) VrSplit = true;
    else if (G.Emulator) {
      if ( (VrState.Current == 4) && (VrState.Old == 0) ) VrSplit = true;
    }
    else if ( (VrState.Current == 2) && (VrState.Old == 1) ) VrSplit = true;
    if (VrSplit) {
      if (settings["Opt.Behaviour.VR.InstaSplit"]) F.ManualSplit("VR Mission complete: " + Loc.Current);
      else R.VrSplitOnExit = true;
    }
    return false;
  }
  // VR Missions processing ends here
  
  // Create list of current signatures when location or progress changes
  var Prog = M["Progress"];
  if (Prog.Changed || Loc.Changed)
    F.SetStateCodes();
  
  var validCodes = new List<string>();
  
  // Create list of check signatures when progress changes
  if (Prog.Changed) {
    
    if (settings["Opt.Test.SplitOnProgress"]) return F.ManualSplit("Splitting for progress change");
    
    foreach (var prog in R.CurrentProgress)
      validCodes.Add("CP-" + prog);
      
    foreach (var prog in R.OldProgress)
      validCodes.Add("OP-" + prog);
      
    F.Debug("Progress (" + string.Join(" ", validCodes) + ")");

  }

  // Create list of check signatures when location changes
  if (Loc.Changed) {
    
    if (settings["Opt.ASL.Location"]) F.SetVar("Location", F.LocationName((string)Loc.Current));
    if (settings["Opt.Test.SplitOnLocation"]) return F.ManualSplit("Splitting for location change");

    foreach (var dep in R.OldLocations) {
      foreach (var dest in R.CurrentLocations) {
        if (dep.Equals(dest)) continue;
        string movement = "OL-" + dep + ".CL-" + dest;
        validCodes.Add(movement);
        foreach (var prog in R.CurrentProgress)
          validCodes.Add(movement + ".CP-" + prog);
      }
      validCodes.Add("OL-" + dep);
      foreach (var prog in R.CurrentProgress)
        validCodes.Add("OL-" + dep + ".CP-" + prog);
    }
    
    foreach (var dest in R.CurrentLocations) {
      validCodes.Add("CL-" + Loc.Current);
      foreach (var prog in R.CurrentProgress)
        validCodes.Add("CL-" + dest + ".CP-" + prog);
    }
    
    F.Debug("Location (" + string.Join(" ", validCodes) + ")");

  }

  // Stop splits from happening from the main menu
  // This can happen if the timer is already started
  if ( Loc.Current.Equals("title") || Loc.Current.Equals("abst") )
    return false;

  // Stop splits from happening during loads
  // Currently triggers at over 5 secs game time difference from previous frame
  if ( (Math.Abs(M["GameTime"].Current - M["GameTime"].Old)) > (5 * (G.EU ? 25 : 30)) ) {
    G.FpsLog.Clear();
    return false;
  }

  // Run any checkers for current signatures, and trigger split
  // as long as computer doesn't say no
  // But do nothing when dying (particularly to bosses) and going backwards
  if ( (validCodes.Any()) && (Prog.Current >= Prog.Old) ) {
    foreach (var code in validCodes) {
      V.CurrentCheck = code;
      if ( (F.Check.ContainsKey(code)) && (!F.Check[code]()) ) continue;
      if (!settings.ContainsKey(code)) continue;
      if (F.Split(code)) return true;
    }
  }

  // Run any watchers for current signatures, and trigger split if one returns 1
  if (R.ActiveWatchCodes != null) {
    foreach (var code in R.ActiveWatchCodes) {
      int result = F.Watch[code]();
      if (result == 0) continue;
      R.ActiveWatchCodes.Remove(code);
      if (result == 1) return F.Split(code);
      if (result == -1) return false;
    }
  }

  // Watch for Testing Mode button presses and manual split if detected
  if (settings["Opt.Test"]) {
    if ( (settings["Opt.Test.SplitOnStart"]) && (F.ButtonPress(0x800)) )
      return F.ManualSplit("Splitting on Start button");
    if ( (settings["Opt.Test.SplitOnR3"]) && (F.ButtonPress(0x400)) )
      return F.ManualSplit("Splitting on R3 button");
  }

}
// split END


/****************************************************/
/* gameTime: Send Game Time to LiveSplit
/****************************************************/
gameTime {
  var D = vars.D; var G = D.Game; var M = D.Mem;
  
  // Only functional in the main game; uses Real Time in VR
  if (G.VRMissions) return null;
  
  // Suspend this when the timer stops for an elevator on PC
  if ( (!G.Emulator) && (!M["TimerActive"].Current) ) return null;
  
  int fps = G.EU ? 50 : 60;
  return TimeSpan.FromMilliseconds(M["GameTime"].Current * 1000 / fps);
}
// gameTime END


/****************************************************/
/* isLoading: Stop LiveSplit attempting to elapse Game Time on its own
/****************************************************/
isLoading {
  var D = vars.D; var G = D.Game; var M = D.Mem;
  
  // Does nothing in VR
  if (G.VRMissions) return false;
  
  // Emulators are fine
  if (G.Emulator) return true;
  
  // Also do nothing when the time stops on an elevator on PC
  return (M["TimerActive"].Current);
}
// isLoading END


/****************************************************/
/* exit: Clean up to pre-init state when game process is closed
/****************************************************/
exit {
  vars.D.Funcs.ResetAllVars();
}
// exit END


/****************************************************/
/* shutdown: Remove event handlers when the autosplitter is closed
/****************************************************/
shutdown {
  var D = vars.D; var F = D.Funcs; var V = D.Vars;
  timer.OnReset -= F.TimerOnReset;
  timer.OnStart -= F.TimerOnStart;
  
  V.EventLog.EntryWritten -= F.EventLogWritten;
}
// shutdown END