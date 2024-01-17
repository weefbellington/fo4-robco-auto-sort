### A mod for Fallout 4 by ~weefbellington
---
# RobCo Auto Sort - Automated Sorting Containers

This repository contains the source code for the Robco Auto Sort mod, available on NexusMods: https://www.nexusmods.com/fallout4/mods/77199

This work is free software under the MIT license. You may modify and redistribute it according to your needs, but as a courtesy to the author I ask that you please provide attribution when doing so.

## How to build the project
### 1. Dependencies
- [Fallout 4 Script Extender](https://www.nexusmods.com/fallout4/mods/42147) (F4SE)
- [Fallout 4 Data Structures](https://www.nexusmods.com/fallout4/mods/53089?tab=files&file_id=245583&nmm=1) (F4DS)
### 2. Development environment setup
- Ensure that Archive2 and PapyrusCompiler are set on your system's path.
- Set the `$FALLOUT4_PATH` environment variable in `robco-auto-sort.code-workspace`.
- Copy or symlink `./RobcoAutoSort.esp` to `<Path:Fallout4>/Data`.
- Copy or symlink `./Data/Scripts/Source/User/RobcoAutoSort` to `<Path:Fallout4>/Data/Scripts/User`.
- Copy or symlink `./Data/Meshes/RobcoAutoSort` to `<Path:Fallout4>/Data/Meshes`.
### 2. Compiling files
- Run `.compile.ps1` (Powershell script)
- This script compiles .psc scripts into .pex files and places them in the `build` directory.
### 3. Building the .ba2 archive
- Run `archive2.ps1` (Powershell script)
- This script archives any .pex files in the `[build]` folder into a .ba2.
- Meshes inside the `[meshes]` folder are also included in the .ba2.
- The debug archive is output to `[FOMOD/filesets/base/debug]`.
- The release archive is output to `[FOMOD/filesets/base/release]`.
- A copy of the debug archive is also output to `[Fallout 4/Data]`.
### 4. Final steps
- Copy all .esp files to the appropriate FOMOD fileset
- Double check that the .ba2 is not missing any scripts
- Create a .zip from the contents of the FOMOD directory
- Test the FOMOD installer by using "Install From File" in Vortex
## Acknowledgments
Special thanks to mod author DLinnyLag for his Fallout 4 Data Structures (F4DS) project. This mod would not have been possible without his hard work.
