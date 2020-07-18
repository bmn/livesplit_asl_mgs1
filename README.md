# livesplit_asl_mgsi
A LiveSplit autosplitter for Metal Gear Solid Integral on PC

## Basic Usage
* Extract the autosplitter to a convenient location.
  * Your LiveSplit folder is recommended (e.g. `LiveSplit\livesplit_asl_mgsi\MetalGearSolidIntegral.asl` etc.).
* Have LiveSplit open as Administrator
  * This is needed for the autosplitter to be able to see the game's memory.
* In LiveSplit's Layout Editor, add a `Scriptable Auto Splitter` component, open it and point it at the splitter of your choice.
  * Alternatively, open one of the provided layouts, which will include a component with a appropriate set of defaults.
    * You might still need to point the Scriptable Auto Splitter to the correct file, depending on your install location.
* Tweak the autosplitter settings to your liking.
  * A set of split files is provided that match common setups. You can customise these further if you like.

## Variants
### Autosplitter Lite
`MetalGearSolidIntegral-Lite.asl` is a simple autosplitter that provides in-game-time (IGT), automatic start and reset, and a core set of splits (primarily bosses) which can be individually disabled. If you need more than this, consider:
### Full Autosplitter
`MetalGearSolidIntegral.asl` is a more complex autosplitter that includes everything Autosplitter Lite does, and adds more powerful and flexibile split options and information.

The information below pertains to the Full Autosplitter only.

## ASL Var Viewer support
[ASL Var Viewer](https://github.com/hawkerm/LiveSplit.ASLVarViewer) integration is provided (ASLVV must be installed first), offering:

* Core stats such as Alerts, Kills etc. (in the Current State section)
* The current difficulty and area (in the Variables section)
* A `Stats` variable, which shows your current stats along with your current codename (Big Boss etc.)
* An `Info` variable, which shows contextual information including Chaff/O2 timers and Boss health data

See the settings for customisability options.

## Split Points
The Split Points settings are a list of every possible point that the Full Autosplitter can trigger a split at. Each can be enabled or disabled so you can fully customise your list of splits - remove splits you don't care about, or add new ones you consider important.

There are five categories of Split Points. By default only the Boss Completion splits are enabled (offering a similar selection to Autosplitter Lite), but you can enable multiple categories if desired. If two categories have splits that occur at the same time, or in the same cutscene sequence, only the first of these splits will occur.

You can enable/disable all splits, or return to default settings, by right-clicking a category and selecting one of those options.

* Boss Completion Splits
  * *Enabled by default*
  * These occur when you defeat a major boss.
  * There is also a split at the Score screen. If on Very Easy, this will split instead on the first codec in the ending, as per speedrun.com rules.
* Other Event Splits
  * *Disabled by default. Recommended to only enable specific entries here and add those to your split list.*
  * These occur at other notable occasions, such as when you arrive at a boss or complete minor set pieces. Of particular note are:
    * Breaking into prison with the vent clip.
    * Retrieving the PAL Key from the rat, and the use of each key in the control room.
* Weapon/Item Unlock Splits
  * *Disabled by default. Recommended to only enable specific entries here and add those to your split list.*
  * These occur the first time you collect a weapon or item.
* Area Movement Splits
  * *Disabled by default, but enabled in the example layouts that include "Locations".*
  * These occur when you move from one area to another.
  * They're organised by *Departure Area > Destination Area > Game Progress*, offering fine control of when you want to split.
  * The default settings will split once only, on each movement that occurs during a typical speedrun. You can disable specific settings to remove them from your splits.
  * Movements that don't occur in a typical speedrun will not have any child settings for game progress. In this case, enabling that movement is equivalent to selecting the "always" setting.
  
