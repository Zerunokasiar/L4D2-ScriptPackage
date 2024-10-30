//Convars.SetValue("survivor_incapacitated_cycle_time", 0.3)
//Convars.SetValue("survivor_incapacitated_reload_multiplier", 1)
Convars.SetValue("survivor_incapacitated_accuracy_penalty", 0)
Convars.SetValue("survivor_allow_crawling", 1)

ZeruM60Fix <- {}

ZeruM60Fix.OnGameEvent_player_use <- function ( params )
{
    local Player = GetPlayerFromUserID( params.userid );
    local entity = params.targetid;

    function FindAIndex()
    {    
        for(local ent = null; ( ent = Entities.FindByClassname( ent , "weapon_ammo_spawn" ) ) != null; )
        {
            if(ent != null && ent.IsValid()) 
            {
                yield ent;
            }
        }
    }

    if(Player != null && Player.IsValid())
    {
        local invTable = {}
        GetInvTable(Player, invTable)

        if("slot0" in invTable)
        {
            local AWeapon = invTable.slot0
            local AweaponClass = invTable.slot0.GetClassname()

            local ammoType = NetProps.GetPropInt(AWeapon , "m_iPrimaryAmmoType");
            local ammo = NetProps.GetPropIntArray(Player , "m_iAmmo", ammoType);

            if(AWeapon != null && AWeapon.IsValid())
            {
                foreach(AIndex in FindAIndex())
                {
                    if(AIndex.GetEntityIndex() == entity)
                    {
                        if(AweaponClass == "weapon_rifle_m60") // Prevent Refill spamming , Check Clip1()
                        {
                            if(IsPlayerABot(Player))
                            {
                                NetProps.SetPropInt(AWeapon,"m_iClip1", AWeapon.GetMaxClip1());
                                local M60_reservemax = Convars.GetFloat("ammo_assaultrifle_max");
                                NetProps.SetPropIntArray(Player , "m_iAmmo",  M60_reservemax , ammoType);
                            }
                            else if(!IsPlayerABot(Player))
                            {
                                local M60_reservemax = Convars.GetFloat("ammo_assaultrifle_max") + (AWeapon.GetMaxClip1() - AWeapon.Clip1());
                                NetProps.SetPropIntArray(Player , "m_iAmmo",  M60_reservemax , ammoType);
                                EmitSoundOnClient("BaseCombatCharacter.AmmoPickup", Player)
                            }
                        }
                    }
                }
            }
        }
    }
}


ZeruM60Fix.OnGameEvent_weapon_fire <- function ( params ) // Reliable Optimized event to check below ammo count for Clip1()
{
    local Player = GetPlayerFromUserID( params.userid );
    local AWeapon = Player.GetActiveWeapon()
    local WeaponName = params.weapon

    if(Player != null && Player.IsValid())
    {
        if(AWeapon != null && AWeapon.IsValid() && WeaponName == "rifle_m60")
        {
            if(AWeapon.Clip1() <= 1)
            {
                switch(NetProps.GetPropInt(AWeapon, "m_upgradeBitVec"))
                {
                    case 4:
                    {
                        NetProps.SetPropInt(AWeapon, "m_upgradeBitVec" , 4)
                    }
                    case 5:
                    {
                        NetProps.SetPropInt(AWeapon, "m_upgradeBitVec" , 4)
                    }
                    case 6:
                    {
                        NetProps.SetPropInt(AWeapon, "m_upgradeBitVec" , 4)
                    }
                }
                
                NetProps.SetPropInt(AWeapon, "m_nUpgradedPrimaryAmmoLoaded" , 0);
                NetProps.SetPropEntity(AWeapon,"m_iClip1", 0);

                local ammoType = NetProps.GetPropInt(AWeapon , "m_iPrimaryAmmoType");
                local ammo = NetProps.GetPropIntArray(Player , "m_iAmmo", ammoType);
                printl(ammo)
                if(ammo > 0)
                {
                    NetProps.SetPropIntArray(Player , "m_iAmmo",  ammo + 1 , ammoType);
                    NetProps.SetPropInt(Player , "m_afButtonForced", 8192)
                    DoEntFire("!self", "RunScriptCode", @"NetProps.SetPropInt(self , ""m_afButtonForced"" , NetProps.GetPropInt(self , ""m_afButtonForced"") & ~8192)" , 0.1, null, Player);
                }
            }
        }
    }
} 

__CollectGameEventCallbacks(ZeruM60Fix)