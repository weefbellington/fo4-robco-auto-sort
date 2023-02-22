# fo4-robco-smart-sort
Source code for the Robco Smart Sort item sorting mod for Fallout 4.

## Requirements

- Install the [Fallout 4 Script Extender](https://f4se.silverlock.org/) (F4SE).
- This project also uses a F4SE extension called [F4DS](https://www.nexusmods.com/fallout4/mods/53089). The .dll and scripts are bundled with the mod.

## xEdit tools

Included in the source code are several scripts for xEdit/FO4Edit.
xEdit uses Delphi (a dialect of Object Pascal) as its scripting language.
The IDE can be downloaded here: https://www.embarcadero.com/products/rad-studio

There are two main scripts:

### CreateSmartSortActivators

This scripts are used to duplicate the containers in an .esm/.esp/.esm file into a Smart Sort activator.
It automatically attaches the correct scripts and adds properties to the object.
This script will also create Constructable Objects and FormLists, if appropriate.

If your mod has custom containers, you can run this on your mod plugin file to generate Smart Sort containers for them.

### AddSortingModuleConstructableObjects

If you add a new Sorting Module, run this script on the record to generate a Constructable Object.
This object will be constructable through the RobCo vending machine.

## Acknowledgements

- Many thanks to Kinggath for his [Youtube video tutorial series](https://www.youtube.com/c/kinggath). It's a great entry point into Creation Kit modding.
- Thank you to mod author DLinny_Lag on NexusMods for his [Fallout 4 Data Structures](https://www.nexusmods.com/fallout4/mods/53089) (F4DS) utility. It's a really great tool for Payprus, which doesn't include data structures out of the box.
- Shout-out to Sinal for inspiration on creating the vending machine! Check out his [Usable Vending Machines](https://www.nexusmods.com/fallout4/mods/10224) mod, I used it as a reference.
