/* Autosplitter-lite for Metal Gear Solid: Integral (PC) */

state("mgsi") {
  uint   GameTime:    0x595344;
  byte   RoomCode:    0x28CE34;
  ushort Progress:    0x38D7CA;
  bool   InMenu:      0x31D180;
  bool   VsRex:       0x388630;
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
    vars.InitVars();
    return true;
  }
  return false;
}

start {
  if ( (current.Progress == 1) && (current.Progress != vars.old.Progress) ) {
    vars.InitVars();
    return true;
  }
  return false;
} 

startup {
  vars.Except = new Dictionary< string, Func<bool> >();
  vars.Watch = new Dictionary< string, Func<bool> >();
  vars.Initialised = false;
  
  vars.SplitTimes = new Dictionary<string, uint> { { "Rex1", 0 }, { "Rex2", 0 }, { "Results", 0 } };
  Action InitVars = delegate() {
    foreach ( string Key in vars.SplitTimes.Keys.ToList() ) vars.SplitTimes[Key] = 0;
  };
  vars.InitVars = InitVars;
  
  settings.Add("splits", true, "Split Points");
    settings.Add("p_7", false, "Dock Elevator", "splits");
    settings.Add("p_27", false, "Exit DARPA Chief's cell", "splits");
    settings.Add("p_29", true, "Guard Encounter", "splits");
    settings.Add("p_39", true, "Revolver Ocelot", "splits");
    settings.Add("p_68", true, "M1 Tank", "splits");
    settings.Add("p_78", true, "Ninja", "splits");
    settings.Add("p_126", false, "Stun Meryl", "splits");
    settings.Add("p_133", true, "Psycho Mantis", "splits");
    settings.Add("p_151", true, "Sniper Wolf", "splits");
    settings.Add("p_158", true, "Enter Prison Cell", "splits");
    settings.Add("p_163", false, "Prison Escape", "splits");
    settings.Add("p_174", false, "Communications Tower Chase", "splits");
    settings.Add("p_179", false, "Communications Tower Rappel", "splits");
    settings.Add("p_188", true, "Hind D", "splits");
    settings.Add("p_195", false, "Comms Tower Elevator Ambush", "splits");
    settings.Add("p_198", true, "Sniper Wolf 2", "splits");
    settings.Add("p_207", false, "Cargo Elevator Ambush", "splits");
    settings.Add("p_212", true, "Vulcan Raven", "splits");
    settings.Add("p_238", false, "Retrieved PAL Key", "splits");
    settings.Add("p_239", false, "Normal PAL Key", "splits");
    settings.Add("p_241", false, "Cold PAL Key", "splits");
    settings.Add("p_247", false, "Hot PAL Key", "splits");
    settings.Add("p_255", false, "Rex Phase 1", "splits");
    settings.Add("p_257", true, "Rex Phase 2", "splits");
    settings.Add("p_278", true, "Liquid Snake", "splits");
    settings.Add("p_286", false, "Escape", "splits");
    settings.Add("p_287", true, "Ending Codec", "splits");
    settings.SetToolTip("p_287", "The final split on Very Easy");
    settings.Add("p_294", true, "Results", "splits");
  
  print("Startup complete");
}

update {
  vars.old = old;
  
  if (!vars.Initialised) {
  
    // Rex Phase 1
    Func<bool> WatRex1 = delegate() {
      if ( (vars.SplitTimes["Rex1"] > 0) || (current.VsRex) || (!vars.old.VsRex) ) return false;
      vars.SplitTimes["Rex1"] = current.GameTime;
      return true;
    };
    vars.Watch.Add("p_255", WatRex1);
    
    // Rex Phase 2
    Func<bool> WatRex2 = delegate() {
      if ( (vars.SplitTimes["Rex2"] > 0) || (current.VsRex) ) return false;
      vars.SplitTimes["Rex2"] = current.GameTime;
      return true;
    };
    vars.Watch.Add("p_257", WatRex2);
    
    // Results
    Func<bool> WatResults = delegate() {
      if ( (vars.SplitTimes["Results"] > 0) || (current.RoomCode == 255) ) return false;
      vars.SplitTimes["Results"] = current.GameTime;
      return true;
    };
    vars.Watch.Add("p_294", WatResults);
    
    vars.Initialised = true;
  }
  
  if (current.GameTime < vars.SplitTimes["Rex1"]) vars.InitVars();
  return true;
}

split {
  string ProgressCode = "p_" + current.Progress;
  if (vars.Watch.ContainsKey(ProgressCode)) return vars.Watch[ProgressCode]();
  if (current.Progress == old.Progress) return false;
  if ( (!settings.ContainsKey(ProgressCode)) || (!settings[ProgressCode]) ) return false;
  if (vars.Except.ContainsKey(ProgressCode)) return vars.Except[ProgressCode]();
  return true;
}