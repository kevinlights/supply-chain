# Supply Chain
Supply Chain is a small simulation game that aims to explore and prompt discussion on how highly optimised, just-in-time supply chains can be susceptible to disruption.

In this file, you can find:

* Licence information for code, assets and third party assets
* Instructions for playing/running the game
* Instructions for running modified versions of the game's data files
* Instructions for editing the game in the Godot editor
* Notes on how to navigate the game's codebase and resources

I hope you find something useful from playing Supply Chain and exploring its code!

-Cheese


## Licences
All source code within this repository is licenced under the MIT Licence, allowing you to use, share, and modify any or all parts of the codebase so long as any derivative works retain the copyright notice from LICENCE.txt. See the file LICENCE.txt for the full licence. Yay!

Excluding the files noted below, all assets are were created for this project and released into the public domain via the [Creative Commons 0](http://creativecommons.org/publicdomain/zero/1.0/) dedication. Under these terms, you are free to do whatever you like with the assets in this repository (the items noted below are subject to their own licence requirements - or not, they're all CC0 too!). Yay!

### Third Party Fonts
* [Montserrat](https://github.com/JulietaUla/Montserrat) Copyright 2011 The Montserrat Project Authors, licenced under the [SIL Open Font Licence 1.1](http://scripts.sil.org/OFL)



## Play Instructions
To play, use the provided sliders to adjust each supply point's resupply threshold or production rate and ensure that the Home supply point can consume while avoiding wastage.



## Running The Game
If you have downloaded a pre-packaged version of the game for Linux, Mac OS or Windows from the Supply Chain [Itch.io page](http://cheeseness.itch.io/supply-chain), extract the relevant archive for your platform and run it!

If you have downloaded [the game's source](https://gitlab.com/Cheeseness/supply-chain), you can select its folder from the _Godot Project Manager_ and click the _Run_ button on the right to run it.



## Running The Game With Modified Json Files
Modified versions of the Supply Chain's data files can be used without using the Godot editor. The game will prioritise json files stored in the following locations (which can also be opened by clicking the "Open User Folder" button in the settings menu):

  Linux: ~/.local/share/supplychain/json/ (note that this respects XDG_DATA_HOME)
  Mac: ~/Library/Application Support/supplychain/json/
  Windows: %APPDATA%/supplychain/json/

A template json folder is included with prebuilt versions of the game from the Supply Chain [Itch.io page](http://cheeseness.itch.io/supply-chain), and can be copied to the custom json folder manually.

When the "Debug shortcuts" setting is enabled in a standalone build, the in-game event editor will save to this folder.



## Editing The Game In Godot
If you have downloaded [the game's source](https://gitlab.com/Cheeseness/supply-chain) to experiment with yourself, you can select its folder from the _Godot Project Manager_ and click the _Edit_ button on the right to open Supply Chain in the Godot editor.



## Understanding The Godot Project and Source Code
Here are some notes to help you navigate Supply Chain's codebase and resources. At the time of writing, the codebase is only partially commented (this may change in the future!).

### Folder Structure

* The **./** folder contains the Godot project files needed to open the game in the Godot editor
* The **fonts** folder contains the Godot DynamicFont resources used by the game
* The **fonts/Montserrat** folder contains the TTF fonts used by the game's DynamicFont resources
* The **game_entities** folder contains a Godot scenes and script that initialises and runs the main game loop
* The **game_entities/supply_point** folder contains Godot scenes and dependencies for the generic supply point UI
* The **game_entities/supply_point/visual_indicators** folder and subfolders contain Godot scenes and dependencies for each supply point's visual representation
* The **game_entities/transit_vehicle** folder contains Godot scenes and dependencies for vehicles
* The **gui** folder contains Godot scenes and dependencies for the game's main menu, settings menu, and credits screen
* The **gui/event** folder contains Godot scenes and dependencies for the game's events and event editor
* The **gui/event/images** folder contains PNG images used by events
* The **gui/how_to_play** folder contains Godot scenes and dependencies for the How To Play scene
* The **gui/report** folder contains Godot scenes and dependencies for the game's periodical reports
* The **json** folder contains json resources
* The **music** folder contains a Godot scene and dependencies for the game's music player and the OGG file for the main menu's music
* The **music/tracks** folder contains OGG files that are played during gameplay


### Code Files
The scripts and other dependencies for each scene are stored in the same folder as the relevant scene.
