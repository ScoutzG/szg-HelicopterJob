# pegasusjob
A pegasus Delivery Script for QBCore.

Install Guide:
Drag And Drop File in your resources folder
Go to your Server Cfg and write: ensure sz-pegasusjob

Config: 
Config.Payment is just there and changing the number does not affect the payout.
Go into server/server.lua and adjust the payment price there on (LINE 5) local payment = math.random(2000, 3000)

client Line 151: ``` QBCore.Functions.Progressbar("knock", "Delivering package", 7000, false, false, {``` Config Time takes to knock the door.
server Line 5: ``` local payment = 3000``` Config Payment Per delivery.
