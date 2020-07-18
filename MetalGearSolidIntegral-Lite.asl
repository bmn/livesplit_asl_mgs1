/* Autosplitter-lite for Metal Gear Solid: Integral (PC) */

state("mgsi") {
  uint   GameTime:    0x595344;
  sbyte  RoomCode:    0x28CE34;
  ushort Progress:    0x38D7CA;
  bool   InMenu:      0x31D180;
  bool   VsRex:       0x388630;
  bool   Psg1Locked:  0x38E815;
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
  if ( (current.Progress == 1) && (current.Progress != vars.D.old.Progress) ) {
    vars.D.InitVars();
    return true;
  }
  return false;
} 

startup {
  vars.D = new ExpandoObject();
  dynamic D = vars.D;
  
  D.Initialised = false;
  D.Except = new Dictionary< string, Func<bool> >();
  D.Watch = new Dictionary< string, Func<bool> >();
  
  D.SplitTimes = new Dictionary<string, uint> { { "Rex1", 0 }, { "Rex2", 0 }, { "Results", 0 } };
  Action InitVars = delegate() {
    var Keys = new List<string>(D.SplitTimes.Keys);
    foreach ( string Key in Keys ) D.SplitTimes[Key] = 0;
  };
  D.InitVars = InitVars;
  
  settings.Add("basic", true, "Split Points");
  settings.SetToolTip("basic", "Same split behaviour as Basic Splits Mode in the full version");
    settings.Add("b_p_7", false, "Dock Elevator", "basic");
    settings.Add("b_p_29", true, "Guard Encounter", "basic");
    settings.Add("b_p_39", true, "Revolver Ocelot", "basic");
    settings.Add("b_p_68", true, "M1 Tank", "basic");
    settings.Add("b_p_78", true, "Ninja", "basic");
    settings.Add("b_p_133", true, "Psycho Mantis", "basic");
    settings.Add("b_w_psg1", false, "Collect PSG-1", "basic");
    settings.Add("b_p_151", true, "Sniper Wolf", "basic");
    settings.Add("b_p_158", false, "Enter Prison Cell", "basic");
    settings.Add("b_p_163", false, "Prison Escape", "basic");
    settings.Add("b_p_174", false, "Comms Tower Chase", "basic");
    settings.Add("b_p_179", false, "Comms Tower Rappel", "basic");
    settings.Add("b_p_188", true, "Hind D", "basic");
    settings.Add("b_p_195", false, "Comms Tower Elevator Ambush", "basic");
    settings.Add("b_p_198", true, "Sniper Wolf 2", "basic");
    settings.Add("b_p_207", false, "Cargo Elevator Ambush", "basic");
    settings.Add("b_p_212", true, "Vulcan Raven", "basic");
    settings.Add("b_p_238", false, "Retrieved PAL Key", "basic");
    settings.Add("b_p_239", false, "Normal PAL Key", "basic");
    settings.Add("b_p_241", false, "Cold PAL Key", "basic");
    settings.Add("b_p_247", false, "Hot PAL Key", "basic");
    settings.Add("b_p_255", false, "Metal Gear REX (Phase 1)", "basic");
    settings.Add("b_p_257", true, "Metal Gear REX", "basic");
    settings.Add("b_p_278", true, "Liquid Snake", "basic");
    settings.Add("b_p_286", true, "Escape", "basic");
    settings.Add("b_p_287", false, "Ending Codec", "basic");
    settings.SetToolTip("b_p_287", "The final split on Very Easy");
    settings.Add("b_p_294", true, "Score", "basic");
  
  print("Startup complete");
}

update {
  dynamic D = vars.D;
  D.old = old;
  
  if (!D.Initialised) {
  
    // Rex Phase 1
    Func<bool> WatRex1 = delegate() {
      if ( (D.SplitTimes["Rex1"] > 0) || (current.VsRex) || (!D.old.VsRex) ) return false;
      D.SplitTimes["Rex1"] = current.GameTime;
      return true;
    };
    D.Watch.Add("p_255", WatRex1);
    
    // Rex Phase 2
    Func<bool> WatRex2 = delegate() {
      if ( (D.SplitTimes["Rex2"] > 0) || (current.VsRex) ) return false;
      D.SplitTimes["Rex2"] = current.GameTime;
      return true;
    };
    D.Watch.Add("p_257", WatRex2);
    
    // Results
    Func<bool> WatResults = delegate() {
      if ( (D.SplitTimes["Results"] > 0) || (current.RoomCode == -1) || (D.old.RoomCode != -1) ) return false;
      D.SplitTimes["Results"] = current.GameTime;
      return true;
    };
    D.Watch.Add("p_294", WatResults);
    
    D.Initialised = true;
  }
  
  if ( (!current.InMenu) && (old.InMenu) ) D.InitVars();
  return true;
}

split {
  dynamic D = vars.D;
  
  if ( (settings["b_w_psg1"]) && (old.Psg1Locked) && (!current.Psg1Locked) ) return true;

  string ProgressCode = "b_p_" + current.Progress;
  if ( (!settings.ContainsKey(ProgressCode)) || (!settings[ProgressCode]) ) return false;
  if (D.Watch.ContainsKey(ProgressCode)) return D.Watch[ProgressCode]();
  if (current.Progress == old.Progress) return false;
  if (D.Except.ContainsKey(ProgressCode)) return D.Except[ProgressCode]();
  return true;
}