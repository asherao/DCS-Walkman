# DCS-Walkman

<img src="https://github.com/asherao/DCS-Walkman/blob/main/GithubImages/pic02.jpg">  

*Listen to your favorite tunes while in DCS, in all planes, whenever you want, even in the Mission Editor.*  


## Features
- Works across Single Player, Multiplayer, Mission Editor, Main Menu, and Loading Screens
- VR and Flatscreen Friendly
- Intregity Check Safe
- Customizable Hotkeys for all functions
- Adjustable window
- "Now Playing" titlebar
- OGG or WAV files
  - Use FlicFlac to easily convert from mp3 (https://github.com/DannyBen/FlicFlac)
- Not effected by ingame time acceleration
- DCS update safe
- 
## Download and install
1. Download DCS-Walkman, which can be found at the ED User Files *(currently pending approval)*
2. Once downloaded, extract the files via your preferred zip software
3. Click and Drag the unzipped `Scripts` folder into your `C:/Users/Profile/Saved Games/DCS` folder
4. (After reading the rest of this readme) You are now ready to use DCS-Walkman!
5. Use FlicFlac to easily convert from mp3 (https://github.com/DannyBen/FlicFlac)

## Acknowledgements
- Based on the framework created by rkusa's DCS-Scratchpad (https://github.com/rkusa/dcs-scratchpad/blob/main/Scripts/Hooks/scratchpad-hook.lua)
- Readme music from IC3PEAK (link)
- If you are feeling charitable, please feel free to donate. All donations go to supporting the creation of even more free apps and mods for DCS, just like this one! https://www.paypal.com/paypalme/asherao
- Join Bailey's VoiceAttack Discord Here https://discord.gg/PbYgC5e
- See more of my mods here https://www.digitalcombatsimulator.com/en/files/filter/user-is-baileywa/apply/?PER_PAGE=100
- Thank you for reading the readme

## Tips and Tricks
- Determine if DCS-Walkman starts shown or hidden by changing the *hideOnLaunch* value on the config file to `true` or `false`
- You can add and remove songs whenever you like, no DCS restart necessary
- You can have multiple folders in your music folder. DCS-Walkman will only play the songs **not** in folders. Think of it as changing the CD in your walkman!
- You can change the folder that DCS-Walkman uses for the songs by changing `local playListDir = (lfs.writedir() .. "Config\\DCS-Walkman")` to `local playListDir = [[C:\Users\Bailey\Music\DCSAudio]]` in `Saved Games\DCS\Scripts\Hooks\walkman-hook.lua`, for example
- You can change the default hotkeys by editing the Config file located in `Saved Games/DCS/Config/DCS-Walkman/DCS-WalkmanConfig.lua`. You can also use a 3rd party program like Voice Attack to bind these keys to your HOTAS, controller, buttonbox, VR controller, Stream Deck whatever you like! The VAP is here: 
  - Stop (Ctrl+Shift+1)
  - Previous Song (Ctrl+Shift+2)
  - Play (Ctrl+Shift+3)
  - Next song (Ctrl+Shift+4)
  - Random Song (Ctrl+Shift+5)
  - Volume Down (Ctrl+Shift+6)
  - Volume up (Ctrl+Shift+7)
  - Hide/Show (Ctrl+Shift+8)
- If you can't find the App on the screen, you may have dragged it off the screen. To get it back change `windowPosition.x` and `windowPosition.y` in `DCS-WalkmanConfig.lua` or delete the file to generate a new one.
- *DCS-Walkman will **not** automatically play tracks back-to-back*
- The GUI is limited to DCSism. If you need assistance while using it in VR you can pause the game to position the cursor.
