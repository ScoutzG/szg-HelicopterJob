local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('sz_pegasusjob:server:Payment', function(jobsDone)
	local src = source
    local payment = math.random(2000, 3000)
	local Player = QBCore.Functions.GetPlayer(source)
    jobsDone = tonumber(jobsDone)
 
        Player.Functions.AddMoney("cash", payment)
        TriggerClientEvent("QBCore:Notify", source, "You received $"..payment, "success")

end)



