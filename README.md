# Roblox Farming Game Script

Harvest Haven is a Roblox farming game script for creating a playable farming experience in Roblox Studio. It provides multiplayer farms, crop planting and harvesting, seed purchasing, a crop-selection UI, tractor dealerships, and drivable tractors with speed upgrades.

## Install

1. Open your Roblox Studio experience.
2. In `ServerScriptService`, create a `Script` named `FarmingGame` and paste in the contents of `ServerScriptService/FarmingGame.server.lua`.
3. In `StarterPlayer > StarterPlayerScripts`, create a `LocalScript` named `FarmingUI` and paste in the contents of `StarterPlayer/StarterPlayerScripts/FarmingUI.client.lua`.
4. Press Play. The server script creates the farming plots, seed shop, tractor dealership, tractor display, drivable tractor, and `FarmingAction` RemoteEvent at runtime.

## Use

1. Select a crop in the on-screen panel. Each player starts with five wheat seeds and 100 coins.
2. Go to an empty plot and activate its prompt to plant the selected crop. Crops use different seed amounts and take 20 to 75 seconds to grow.
3. Activate the prompt on a ripe crop to harvest it and receive its listed coin reward.
4. Buy three seeds for five coins using the on-screen button or the seed shop prompt. The seed shop prompt also cycles through crops.
5. Use the tractor dealership prompt to browse and purchase Compact, Utility, or HeavyDuty tractors. Use the second dealership prompt to upgrade the selected owned tractor's speed.
6. Sit in your farm's tractor DriverSeat. Drive with W/S and steer with A/D, or use the corresponding gamepad controls.

Player progress, seeds, coins, tractor ownership, and upgrades are held in memory and reset when the server closes.

---

More Roblox script projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/2378e440-3fa9-43f0-9822-0ff956a7da17?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=2378e440-3fa9-43f0-9822-0ff956a7da17
