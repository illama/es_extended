function StartPayCheck()
    CreateThread(function()
        while true do
            Wait(Config.PaycheckInterval)
            for player, xPlayer in pairs(ESX.Players) do
                local jobLabel = xPlayer.job.label
                local job = xPlayer.job.grade_name
                local salary = xPlayer.job.grade_salary
                local job2Label = xPlayer.job2.label
                local job2 = xPlayer.job2.grade_name
                local salary2 = xPlayer.job2.grade_salary

                -- Traitement du job principal
                if xPlayer.paycheckEnabled and salary > 0 then
                    ProcessPaycheck(xPlayer, player, {
                        name = xPlayer.job.name,
                        label = jobLabel,
                        grade_name = job,
                        grade_salary = salary
                    })
                end

                -- Traitement du job secondaire
                if xPlayer.paycheckEnabled and salary2 > 0 then
                    ProcessPaycheck(xPlayer, player, {
                        name = xPlayer.job2.name,
                        label = job2Label,
                        grade_name = job2,
                        grade_salary = salary2
                    })
                end
            end
        end
    end)
end

function ProcessPaycheck(xPlayer, player, job)
    -- Cas du chômage
    if job.grade_name == "unemployed" then
        xPlayer.addAccountMoney("bank", job.grade_salary, "Welfare Check")
        TriggerClientEvent("esx:showAdvancedNotification", player, 
            TranslateCap("bank"), 
            TranslateCap("received_paycheck"), 
            TranslateCap("received_help", job.grade_salary), 
            "CHAR_BANK_MAZE", 
            9
        )
        LogPaycheck(xPlayer, "Aide de l'état", job.grade_salary)
        return
    end

    -- Cas d'un emploi avec société
    if Config.EnableSocietyPayouts then
        TriggerEvent("esx_society:getSociety", job.name, function(society)
            if society ~= nil then
                -- Vérification du compte de la société
                TriggerEvent("esx_addonaccount:getSharedAccount", society.account, function(account)
                    if account.money >= job.grade_salary then
                        -- Paiement depuis le compte de la société
                        xPlayer.addAccountMoney("bank", job.grade_salary, "Paycheck")
                        account.removeMoney(job.grade_salary)
                        LogPaycheck(xPlayer, job.label, job.grade_salary)

                        TriggerClientEvent("esx:showAdvancedNotification", player,
                            TranslateCap("bank"),
                            TranslateCap("received_paycheck"),
                            TranslateCap("received_salary", job.grade_salary),
                            "CHAR_BANK_MAZE",
                            9
                        )
                    else
                        -- Notification si la société n'a pas assez d'argent
                        TriggerClientEvent("esx:showAdvancedNotification", player,
                            TranslateCap("bank"),
                            "",
                            TranslateCap("company_nomoney"),
                            "CHAR_BANK_MAZE",
                            1
                        )
                    end
                end)
            else
                -- Cas d'un emploi sans société
                xPlayer.addAccountMoney("bank", job.grade_salary, "Paycheck")
                LogPaycheck(xPlayer, job.label, job.grade_salary)
                
                TriggerClientEvent("esx:showAdvancedNotification", player,
                    TranslateCap("bank"),
                    TranslateCap("received_paycheck"),
                    TranslateCap("received_salary", job.grade_salary),
                    "CHAR_BANK_MAZE",
                    9
                )
            end
        end)
    else
        -- Cas d'un emploi générique
        xPlayer.addAccountMoney("bank", job.grade_salary, "Salaire")
        LogPaycheck(xPlayer, "Général", job.grade_salary)
        
        TriggerClientEvent("esx:showAdvancedNotification", player,
            TranslateCap("bank"),
            TranslateCap("received_paycheck"),
            TranslateCap("received_salary", job.grade_salary),
            "CHAR_BANK_MAZE",
            9
        )
    end
end

function LogPaycheck(xPlayer, jobType, amount)
    if Config.LogPaycheck then
        ESX.DiscordLogFields("Salaire", "Salaire - " .. jobType, "green", {
            { name = "Joueur", value = xPlayer.name, inline = true },
            { name = "ID", value = xPlayer.source, inline = true },
            { name = "Montant", value = amount, inline = true },
        })
    end
end