### A mod for Fallout 4 by ~weefbellington~
---
# RobCo Auto Sort - Automated Sorting Containers

This repository contains the source code for the Robco Auto Sort mod, available on NexusMods: https://www.nexusmods.com/fallout4/mods/77199

This work is free software under the MIT license. You may modify and redistribute it according to your needs, but as a courtesy to the author I ask that you please provide attribution when doing so.

## How to build the project
### 1. Dependencies
- [Fallout 4 Script Extender](https://www.nexusmods.com/fallout4/mods/42147) (F4SE)
- [Fallout 4 Data Structures](https://www.nexusmods.com/fallout4/mods/53089?tab=files&file_id=245583&nmm=1) (F4DS)
### 2. Development setup
- Set the `$FALLOUT4_PATH environment` variable in `robco-auto-sort.code-workspace`.
- Copy `RobcoAutoSort.esp` to `[Fallout4/Data]`.
- Copy .psc source files to `[Fallout4/Data/Scripts/Source/User/RobcoAutoSort]`.
- Copy meshes to `[Fallout4/Data/Meshes/RobcoAutoSort]`.
- Symlink this folder to `[papyrus-scripts/Data/Scripts/Source/User]` so you don't have to copy source files back and forth.
### 2. Compiling files
- Run `.compile.ps1` (Powershell script)
- This script compiles .psc scripts into .pex files and places them in the `build` directory.
- It also copies .pex files into the `[Data/Scripts]` directory in your local Fallout 4 game folder.
### 3. Building the .ba2 archive
- Run `archive2.ps1` (Powershell script)
- This script archives any .pex files in the `[build]` folder into a .ba2.
- Meshes inside the `[meshes]` folder are also included in the .ba2.
- The debug archive is output to `[FOMOD/filesets/base/debug]`.
- The release archive is output to `[FOMOD/filesets/base/release]`.
### 4. Final steps
- Copy all .esp files to the appropriate FOMOD fileset
- Double check that the .ba2 is not missing any scripts
- Create a .zip from the contents of the FOMOD directory
- Test the FOMOD installer by using "Install From File" in Vortex
## Project structure
#### `[build]`
- `[debug]` - .pex files compiled with no flags
- `[release]` - .pex files compiled with optimize/release/final flags
#### `[FOMOD]`
- `[filesets]`: files to include for different FOMOD selections
- `[fomod]`: FOMOD configuration files
- `[images]`: FOMOD image files
#### `[meshes]`
- meshes to include in .ba2
#### `[papyrus-scripts]`
- papyrus source files
#### `[xedit-scripts]`
- xedit scripts for copying records
#### `archive2.ps1`
- archive` build script, assembles .ba2
#### compile.ps1
- compile build script, builds .pex from .psc
#### `robco-auto-sort.code-workspace`
- VSCode project
#### `robco-auto-sort.ppj`
- papyrus project file
