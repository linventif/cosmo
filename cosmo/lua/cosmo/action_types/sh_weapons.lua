local WEAPONS = Cosmo.ActionType.New("weapons")

local function giveWeapons(ply, weaponClasses, isPermanent)
    if not istable(weaponClasses) then return end

    for _, wepClass in ipairs(weaponClasses) do
        local wep = ply:Give(wepClass)
        
        if isPermanent then
            if wepClass == "boost_health" then
                ply:ChatPrint("Active Boost : Health")
                ply:SetMaxHealth(200)
                ply:SetHealth(200)
            elseif wepClass == "boost_armor_50" then
                ply:ChatPrint("Active Boost : Armor")
                ply:SetArmor(50)
            elseif wepClass == "boost_armor_100" then
                ply:ChatPrint("Active Boost : Armor")
                ply:SetArmor(100)
            elseif wepClass == "boost_ammo" then
                ply:ChatPrint("Active Boost : Ammo")
                for i = 1, 100 do -- higher the number if you don't have all ammo type give
                    ply:SetAmmo(9999, i)
                end
            elseif wepClass == "boost_speed" then
                ply:SetSlowWalkSpeed(ply:GetSlowWalkSpeed() * 1.2)
                ply:SetWalkSpeed(ply:GetWalkSpeed() * 1.2)
                ply:SetRunSpeed(ply:GetRunSpeed() * 1.2)
                ply:SetMaxSpeed(ply:GetMaxSpeed() * 1.2)
            else
                ply:ChatPrint("Active Weapon : " .. wepClass)
                wep.__cosmo = true
            end
        end
    end
end

function WEAPONS:HandlePurchase(action, order, ply)
    local weaponClasses = action.data.classes or {}
    local isPermanent = action.data.perm == "1"

    giveWeapons(ply, weaponClasses, isPermanent)

    if isPermanent then
        ply.__cosmoWeapons = ply.__cosmoWeapons or {}
        table.insert(ply.__cosmoWeapons, action)
    end

    return true
end

function WEAPONS:HandleExpiration(action, order, ply)
    local actionId = action.id
    if not actionId then return false end

    for i, wAction in pairs(ply.__cosmoWeapons) do
        if actionId == wAction.id then
            ply.__cosmoWeapons[i] = nil
            break
        end
    end

    return true
end

hook.Add("PlayerInitialSpawn", "Cosmo.Store.Weapons", function(ply)
    Cosmo.Log.Debug("(WEAPONS)", "Retrieving weapons for", ply:Nick())
    
    Cosmo.Http:DoRequest("GET", "/store/weapons/" .. ply:SteamID64())
        :Then(function(data)
            if not IsValid(ply) or not istable(data) then return end

            local wepClasses = {}

            for _, action in ipairs(data) do
                if action.data.perm ~= "1" then continue end
                if not istable(action.data.classes) then continue end

                giveWeapons(ply, action.data.classes, true)

                table.insert(wepClasses, action)
            end

            ply.__cosmoWeapons = wepClasses
        end)
        :Catch(function(reason)
            Cosmo.Log.Warning("(WEAPONS)", "Failed to load permanent weapons for player:", ply:SteamID64())
        end)
end)

hook.Add("PlayerLoadout", "Cosmo.Store.Weapons", function(ply)
    if not ply.__cosmoWeapons then return end

    for _, action in pairs(ply.__cosmoWeapons) do
        giveWeapons(ply, action.data.classes, true)
    end
end)

hook.Add("canDropWeapon", "Cosmo.Store.Weapons", function(ply, weapon)
    if weapon.__cosmo then return false end
end)

Cosmo.ActionType.Register(WEAPONS)