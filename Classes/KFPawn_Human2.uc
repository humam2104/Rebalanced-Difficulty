class KFPawn_Human2 extends KFPawn_Human;

function bool IsPistolWeapon(KFWeapon CurrentWeapon)
{
	if (CurrentWeapon != none)
		return (CurrentWeapon.class.name == 'KFWeap_Pistol_9mm' || CurrentWeapon.class.name == 'KFWeap_Pistol_Dual9mm');
}

function bool IsKnifeWeapon(KFWeapon CurrentWeapon)
{
	if (KFWeap_Edged_Knife(CurrentWeapon) != none)
		return true;
	return false;
}

/**
 * Reset/update GroundSpeed based on perk/weapon selection.  GroundSpeed is used instead of
 * MaxSpeedModifier() so that other physics code reacts properly (e.g. bLimitFallAccel)
 * Network: Server Only
 */
function UpdateGroundSpeed()
{
	local KFInventoryManager InvM;
	local float WeightMod, HealthMod, WeaponMod;
    local KFGameInfo KFGI;
	local KFWeapon CurrentWeapon;
	local KFPlayerController KFPC;
	local float CurrentPerkGroundSpeed;
	local float CustomWeaponMod;

	if ( Role < ROLE_Authority )
		return;
	if (Weapon != none)
	{
		CurrentWeapon = KFWeapon(Weapon);
		CustomWeaponMod = CurrentWeapon.MovementSpeedMod;
		if (GetPerk() != none) GetPerk().ModifySpeed( CurrentPerkGroundSpeed );

		if (IsPistolWeapon(CurrentWeapon))
		{
			CustomWeaponMod = 1.15;
		}
		else if (IsKnifeWeapon(CurrentWeapon))
		{
			CustomWeaponMod = 1.25;
		}
		if (GetPerk() != none && CurrentPerkGroundSpeed > default.GroundSpeed)
		{
			CustomWeaponMod = CurrentPerkGroundSpeed;
		}


		InvM = KFInventoryManager(InvManager);
		WeightMod = (InvM != None) ? InvM.GetEncumbranceSpeedMod() : 1.f;
		HealthMod = GetHealthMod();
		// some weapons can change a player's movement speed during certain states
		WeaponMod = (CurrentWeapon != None) ? CustomWeaponMod : 1.f;

	    //Grab new defaults
		GroundSpeed = default.GroundSpeed;
	    SprintSpeed = default.SprintSpeed;

	    //Allow game info modifiers
	    KFGI = KFGameInfo(WorldInfo.Game);
	    if (KFGI != none)
	    {
	        KFGI.ModifyGroundSpeed(self, GroundSpeed);
	        KFGI.ModifySprintSpeed(self, SprintSpeed);
	    }

		//Add pawn modifiers
		GroundSpeed = GroundSpeed * WeightMod * HealthMod * WeaponMod;
	    SprintSpeed = SprintSpeed * WeightMod * HealthMod * WeaponMod;

		// Ask our perk to set the new ground speed based on weapon type
		if( GetPerk() != none  && !IsKnifeWeapon(CurrentWeapon) && !IsKnifeWeapon(CurrentWeapon))
		{
			GetPerk().ModifySpeed( GroundSpeed );
			GetPerk().ModifySprintSpeed( SprintSpeed );
	        GetPerk().FinalizeSpeedVariables();
		    if (KfPerk_Demolitionist( GetPerk() ) != none)
			{
				GroundSpeed *= 1.25;
				SprintSpeed *= 1.25;
				InvM.MaxCarryBlocks = 20;
			}
		}

		// Ask the current power up to set new ground speed
		KFPC = KFPlayerController(Controller);
		if( KFPC != none && KFPC.GetPowerUp() != none )
		{
			KFPC.GetPowerUp().ModifySpeed( GroundSpeed );
			KFPC.GetPowerUp().ModifySprintSpeed( SprintSpeed );
	        KFPC.GetPowerUp().FinalizeSpeedVariables();
		}

		if (CurrentWeapon != None)
		{
			if (CurrentWeapon.OverrideGroundSpeed >= 0.0f)
			{
				GroundSpeed = CurrentWeapon.OverrideGroundSpeed;
			}

			if (CurrentWeapon.OverrideSprintSpeed >= 0.0f)
			{
				SprintSpeed = CurrentWeapon.OverrideSprintSpeed;
			}
		}
	}


}

/** Checks if we are surrounded and notifies the game conductor */
function Timer_CheckSurrounded()
{
	local KFGameInfo KFGI;

	// Only check surrounded if we still have only one player and if we are below the health threshold
	if( GetHealthPercentage() < MinHealthPctToTriggerSurrounded && IsSurrounded(true, MinEnemiesToTriggerSurrounded, 250.f) )
	{
		KFGI = KFGameInfo( WorldInfo.Game );
		if( KFGI != none && KFGI.GameConductor != none )
		{
			KFGI.GameConductor.NotifySoloPlayerSurrounded();
		}
	}
}
function float GetHealthMod()
{
	//When low on health, the character moves even quicker (because they're scared of dying!)
    return 1.f + LowHealthSpeedPenalty;
}



defaultproperties
{
	BatteryRechargeRate=100.f
	BatteryDrainRate=0.f
	NVGBatteryDrainRate=0.f
	JumpZ=900.f
	AirControl=+0.65
}
