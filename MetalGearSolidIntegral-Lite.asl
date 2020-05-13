/* Autosplitter-lite for Metal Gear Solid: Integral (PC) */

state("mgsi") {
  uint   GameTime: 0x595344;
  byte   RoomCode: 0x28CE34;
  ushort Progress: 0x38D7CA;
  bool   InMenu:   0x31D180;
  bool   VsRex:    0x388630;
}

isLoading {
  return true;
}

gameTime {
  return TimeSpan.FromMilliseconds((current.GameTime) * 1000 / 60);
}

reset {
  // Don't reset from the credits
  return ( (current.InMenu) && (current.InMenu != old.InMenu) && (current.Progress != 294) );
}

start {
  return ( (current.Progress == 1) && (current.Progress != vars.old.Progress) );
} 

startup {
  vars.Except = new Dictionary< string, Func<bool> >();
  vars.Watch = new Dictionary< string, Func<bool> >();
  vars.Initialised = false;
  
  Action InitVars = delegate() {
    vars.SplitTimes = new Dictionary<string, uint> { { "Rex1", 0 }, { "Rex2", 0 }, { "Results", 0 } };
  };
  vars.InitVars = InitVars;
  InitVars();
  
  settings.Add("splits", true, "Split Points");
    settings.Add("s_29", true, "Guard Encounter", "splits");
    settings.Add("s_39", true, "Revolver Ocelot", "splits");
    settings.Add("s_68", true, "M1 Tank", "splits");
    settings.Add("s_78", true, "Ninja", "splits");
    settings.Add("s_133", true, "Psycho Mantis", "splits");
    settings.Add("s_151", true, "Sniper Wolf", "splits");
    settings.Add("s_158", true, "Enter Prison Cell", "splits");
    settings.Add("s_163", false, "Prison Escape", "splits");
    settings.Add("s_174", false, "Communications Tower Chase", "splits");
    settings.Add("s_179", false, "Communications Tower Rappel", "splits");
    settings.Add("s_188", true, "Hind D", "splits");
    settings.Add("s_195", false, "Comms Tower Elevator Ambush", "splits");
    settings.Add("s_198", true, "Sniper Wolf 2", "splits");
    settings.Add("s_207", false, "Cargo Elevator Ambush", "splits");
    settings.Add("s_212", true, "Vulcan Raven", "splits");
    settings.Add("s_238", false, "Retrieved PAL Key", "splits");
    settings.Add("s_239", false, "Normal PAL Key", "splits");
    settings.Add("s_241", false, "Cold PAL Key", "splits");
    settings.Add("s_247", false, "Hot PAL Key", "splits");
    settings.Add("s_255", false, "Rex Phase 1", "splits");
    settings.Add("s_257", true, "Rex Phase 2", "splits");
    settings.Add("s_278", true, "Liquid Snake", "splits");
    settings.Add("s_286", true, "Escape", "splits");
    settings.Add("s_294", true, "Results", "splits");
  
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
    vars.Watch.Add("s_255", WatRex1);
    
    // Rex Phase 2
    Func<bool> WatRex2 = delegate() {
      if ( (vars.SplitTimes["Rex2"] > 0) || (current.VsRex) ) return false;
      vars.SplitTimes["Rex2"] = current.GameTime;
      return true;
    };
    vars.Watch.Add("s_257", WatRex2);
    
    // Results
    Func<bool> WatResults = delegate() {
      if ( (vars.SplitTimes["Results"] > 0) || (current.RoomCode == 255) ) return false;
      vars.SplitTimes["Results"] = current.GameTime;
      return true;
    };
    vars.Watch.Add("s_294", WatResults);
    
    vars.Initialised = true;
  }
  
  if (current.GameTime < vars.SplitTimes["Rex1"]) vars.InitVars();
  return true;
}

split {
  string Code = "s_" + current.Progress;
  if (vars.Watch.ContainsKey(Code)) return vars.Watch[Code]();
  if (current.Progress == old.Progress) return false;
  if ( (!settings.ContainsKey(Code)) || (!settings[Code]) ) return false;
  if (vars.Except.ContainsKey(Code)) return vars.Except[Code]();
  return true;
}