# livesplit_asl_mgs1
A LiveSplit autosplitter for Metal Gear Solid on PC and emulator

⚠ This is version 2 of the autosplitter. [Click here for version 1 (pre-May 2021).](https://github.com/bmn/livesplit_asl_mgs1/tree/v1)

⚠ **Do not** use a *Scriptable Auto Splitter* and an activated *Splits Editor autosplitter* at the same time - this will cause repeated splits.

⚠ If using a Split File labelled *Subsplits*, you should have a *Subsplits* component in your layout, **not** the default *Splits* layout.

# Versions Supported
## Games
* Metal Gear Solid (PSX JP)
* Metal Gear Solid (PSX US)
* Metal Gear Solid (PSX EU English)
* Metal Gear Solid (PSX EU Spanish)
* Metal Gear Solid Integral (PC)
* Metal Gear Solid Integral (PSX JP)
* Metal Gear Solid Integral VR-Disc (PC)
* Metal Gear Solid Integral VR-Disc (PSX JP)
* Metal Gear Solid VR Missions (PSX US)
* Metal Gear Solid Special Missions (PSX EU English)
* Metal Gear Solid - Master Collection Version (PC) for the above PSX games
## Emulators
* BizHawk
* DuckStation
* ePSXe
* Mednafen
* RetroArch (Beetle PSX core)

# Getting Started

## Installation
* Click the green button above and select `Download ZIP`, and extract `MetalGearSolid.asl` anywhere.
* In LiveSplit's Layout Editor, add a new `Control > Scriptable Auto Splitter`.
* Double click on the Scriptable Auto Splitter, and browse to `MetalGearSolid.asl`.

## Setting the Default set of Splits
* The first time you run the autosplitter, the `Default Settings Template` window will appear.
  * Selecting one of the templates will define your default splits for every layout you add the autosplitter to in the future.
  * The first three templates offer sensible split sets, depending on how often you want to split.
  * Choose one of the `For Old v1 Split Files` templates if you want to use your old v1 split files without having to add or remove splits.

## Customising your Splits
* In the Scriptable Auto Splitter settings, find the `Split Points` category and open it if necessary.
* Every split supported by the autosplitter is listed here in order.
* Check any split you want to include, and uncheck those you don't.
* You don't need to uncheck splits that aren't in your run - the autosplitter will keep track of which route you're on, and avoid splitting in places that aren't on that route.

## Default Split Files
* If you've customised any of your splits, see `Building Split Files` below.
* Otherwise, prebuilt `split files` are available in the [Split Files](./Split%20Files) folder.

## Building Split Files
* To build a set of split files that matches the selected splits in your settings:
  * Make sure the game, or any of the supported emulators (it's not necessary to launch the game), is already open.
  * In the Scriptable Auto Splitter settings, toggle the top setting `MGS Autosplitter Toolbox` on or off, to open the toolbox.
  * Click the button for `Build Split File for current settings`, to open the split file builder.
  * Change any of the settings if needed, click `Save To Folder`, and select the target folder.
* Split files will be created for the following categories:
  * Any% (PC)
  * All Bosses (PC)
  * Glitchless (PC)
  * Any% (Console)
  * All Bosses (Console)

# ASL Var Viewer ("Variables") Support
* MGS Autosplitter provides a set of data variables about the game and run, that you can add to your LiveSplit layout.
* You must install the [ASL Var Viewer](https://github.com/hawkerm/LiveSplit.ASLVarViewer) component by hawkerm first, and restart LiveSplit.

## Adding Variables
* Make sure the game is open before starting.
* For each variable, in the Layout Editor, add an `Info > ASL Var Viewer` component and double click it.
* Select either `Current State` or `Variables`, and select a variable from the dropdown box below.

## Current State
* The `Current State` variables are raw data taken from the game, usually simple strings and numbers.
* These variables are provided:
  * `Alerts`: The number of times you've entered an Alert state when seen by the enemy.
  * `Continues`: The number of Continues you've taken.
  * `Difficulty`: A number representing the difficulty, where `-1` is Very Easy, `0` is Normal, etc.
  * `GameTime`: The number of frames elapsed since you started a run. Timed at 30 per second.
  * `Kills`: The number of guards you've killed.
  * `Life`: Snake's current HP.
  * `Location`: A string representing the current game area, e.g. `s00a` is Dock.
  * `MaxLife`: Snake's current maximum HP.
  * `Progress`: A number representing your progress through the game. The end of the game is at `294`.
  * `RationsUsed`: The number of Rations you've eaten.
  * `Saves`: The number of times you've saved the game.

## Variables
* The `Variables` variables are calculated by the autosplitter using game and run data, and are usually "friendlier" than the Current State variables.
* These variables are provided:
  * `D`: This is a data store for the autosplitter. It doesn't provide any information and shouldn't be used.
  * `FPS`: A constantly-updating display of the game's rendered frame rate. By default 1-second, 5-second and 15-second periods are displayed.
  * `Info`: A general-purpose variable that shows contextual information whenever it becomes available. These are provided:
    * HP for Snake
    * HP for the current boss
    * Countdown timer for Chaff Grenade
    * Countdown timer for O2 when in water/gas
    * Countdown timer for Diazepam
    * Countdown timer for the elevator in Dock
  * `Location`: The name of the area you're currently in.
  * `Platform`: The name of the emulator currently in use, or `PC` if using the PC version of the game.
  * `Stats`: A single line showing every game stat (e.g. Alerts) that is 1 or higher.
  * `Version`: The name of the current version of Metal Gear Solid.
  
