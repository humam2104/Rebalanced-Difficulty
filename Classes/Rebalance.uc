class Rebalance extends KFMutator;

var KFGameInfo KFGI;
var float MagSizeMultiplier;
var float HitDamageMultiplier;
var float PickupScaleMultiplier;
var LinearColor CustomEnragedGlowColor;

function InitMutator(string Options, out string ErrorMessage)
{
	local String CurrentError;
	super.InitMutator( Options, ErrorMessage );
	CurrentError = ErrorMessage;
	`log("********  Rebalance Mutator initialized ********");
		if (CurrentError != "")
		{
			`log("******** Error Encountered: ********");
			`log(CurrentError);
			`log("******** Error End ********");
		}
}



//Prevents the game from adding this mutator multiple times
function AddMutator(Mutator M)
{
	if( M != Self)
	{
		if(M.Class==Class)
			M.Destroy();
		else Super.AddMutator(M);
	}
}

function PostBeginPlay()
{
	SetGameConductor();
}


function SetGameConductor()
{
	
	KFGI = KFGameInfo(WorldInfo.Game);
	KFGI.GameLengthDoshScale[0]=1.85; // Short
	KFGI.GameLengthDoshScale[1]=1.40;  // Medium
	KFGI.GameLengthDoshScale[2]=1.1;  // Long
	KFGI.bPauseable = true;
	`log("*** Dosh Scale Modified ***");
	KFGI.GameConductorClass = class'Rebalanced-Difficulty.KFGameConductor2';
	KFGI.DifficultyInfoClass=class'Rebalanced-Difficulty.KFGameDifficultyInfo2';
	KFGI.DefaultPawnClass=class'Rebalanced-Difficulty.KFPawn_Human2';
}

	
	


simulated function bool IsBossPawn(KfPawn P)
{
	if (KFPawn_MonsterBoss(P) != None)
	{
		return true;
	} 
	return false;
}

function bool IsTraderWave()
{
	if (KFGI.MyKFGRI.bTraderIsOpen)
	{
		return true;
	}
	else if (KFGI.MyKFGRI.bTraderIsOpen == false)
	{
		return false;
	}
}
	
function ModifyAIEnemy(AIController AI, Pawn Enemy)
{
	local int i;
	local KFPawn_Monster Zed_HealthModded;
	local KFPawn_Monster Zed_HeadModded;
	local KFPawn_Monster Zed_ResistModded;
	local KFPawn_Monster Zed_SpeedModded;
	local KFAIPluginRage_Fleshpound AI_FleshPound;
	local KFAIController AI_NoTeleport;
	local KFAIController_ZedMatriarch NerfedBossMatriarch;
	super.ModifyAIEnemy(AI, Enemy);
	if (AI != None && Enemy != None)
	{
		//Increase Fleshpound rage Timer 14 + Random Value
		if (KFAIController_ZedFleshpound(AI).RagePlugin != None)
		{
			AI_FleshPound = KFAIController_ZedFleshpound(AI).RagePlugin;
			AI_FleshPound.RageFrustrationBaseTime = 14;
			AI_FleshPound.RageFrustrationTime = AI_FleshPound.RageFrustrationBaseTime + RandRange(1.f,5.f);
			AI_FleshPound.SetRageTime();
		}

		//Reduce Rioter Health
		if (KFPawn_ZedClot_AlphaKing(KFAIController(AI).Pawn) != None)
		{
			Zed_HealthModded = KFPawn_Monster(KFAIController(AI).Pawn);
			Zed_HealthModded.Health = 175;
		}
		//Stalkers, Gorefiends, and Rioters aren't allowed to teleport to player
		if (KFAIController_ZedStalker(AI) != None || 
			KFAIController_ZedGorefastDualBlade(AI) != None ||
			 KFAIController_ZedClot_AlphaKing(AI) != None)
		{
			AI_NoTeleport = KFAIController(AI);
			AI_NoTeleport.bCanTeleportCloser = false;
		}

		if (KFAIController_ZedMatriarch(AI) != None)
		{
			NerfedBossMatriarch = KFAIController_ZedMatriarch(AI);
			NerfedBossMatriarch.GlobalCooldownTimer = 7.5f;
		}

		//Reduce Gorefiend/Siren Head Health
		if (KFPawn_ZedGorefastDualBlade(KFAIController(AI).Pawn) != None 
			|| KFPawn_ZedSiren(KFAIController(AI).Pawn) != None ||
			KFPawn_ZedDAR(KFAIController(AI).Pawn) != None )
		{
			Zed_HeadModded = KFPawn_Monster(KFAIController(AI).Pawn);
			if (KFPawn_ZedDAR(Zed_HeadModded) == None)
				Zed_HeadModded.HitZones[HZI_HEAD].GoreHealth = 100;
			else if (KFPawn_ZedBloat(Zed_HeadModded) == None)
				Zed_HeadModded.HitZones[HZI_HEAD].DmgScale = 1.1;
			else if (KFPawn_ZedDAR(Zed_HeadModded) != None)
				Zed_HeadModded.HitZones[3].DmgScale = 5.5f;
		}
		if ( KFPawn_ZedGorefastDualBlade(KFAIController(AI).Pawn) != None )
		{
			Zed_SpeedModded = KFPawn_Monster(KFAIController(AI).Pawn);
			Zed_SpeedModded.GroundSpeed=345.f;
			Zed_SpeedModded.SprintSpeed=460.f;
		}		
		//Reduce Stalker/Crawler Body Resistance to SMGs
		if (KFPawn_ZedStalker(KFAIController(AI).Pawn) != None || 
			KFPawn_ZedCrawler(KFAIController(AI).Pawn) != None)
		{
			Zed_ResistModded = KFPawn_Monster(KFAIController(AI).Pawn);

			for (i=0;i<4;i++)
			{
				Zed_ResistModded.DamageTypeModifiers[0].DamageScale[0] = 3.0f;
			}
		}
		//Nerf FP
		if (KFPawn_ZedFleshpound(KFAIController(AI).Pawn) != None)
		{
			Zed_ResistModded = KFPawn_Monster(KFAIController(AI).Pawn);
			Zed_ResistModded.DamageTypeModifiers[0].DamageScale[0] = 0.75f;
			Zed_ResistModded.DamageTypeModifiers[1].DamageScale[0] = 0.75f;
			KFPawn_ZedFleshpound(Zed_ResistModded).DefaultGlowColor = CustomEnragedGlowColor;
		}			
	}
	
}

reliable server function ReduceWeaponRecoil(KFWeapon CurKFW,float RecoilMultiplier)
	{
			//Reduce Hip-Fire Recoil
			CurKFW.maxRecoilPitch *= RecoilMultiplier;
			CurKFW.minRecoilPitch *= RecoilMultiplier;
			CurKFW.maxRecoilYaw *= RecoilMultiplier;
			CurKFW.minRecoilYaw *= RecoilMultiplier;
			//Reduce Iron-Sight Recoil
			CurKFW.RecoilISMaxYawLimit *= RecoilMultiplier;
			CurKFW.RecoilISMinYawLimit *= RecoilMultiplier;
			CurKFW.RecoilISMaxPitchLimit *= RecoilMultiplier;
			CurKFW.RecoilISMinPitchLimit *= RecoilMultiplier;
			CurKFW.RecoilRate *= RecoilMultiplier;
			//CurKFW.HandleRecoil();
			`log("PerkBuff:- Weapon Recoil " $ CurKFW.class.name $ " is Modified");
	}

function bool IsKnifeWeapon(KFWeapon CurrentWeapon)
{
	if (KFWeap_Edged_Knife(CurrentWeapon) != none)
		return true;
	return false;
}


function UpgradeMedicWeapon(KFWeapon CurKFW, int UpgradeIndex)
{
	if (KFWeap_MedicBase(CurKFW) != none)
	{
		KFWeap_MedicBase(CurKFW).HealAmount *= 1.2f;
		KFWeap_MedicBase(CurKFW).HealFullRechargeSeconds *= 0.8f;
	}
}

function ModifyUpgradedWeapons()
{
	local KFWeapon CurKFW;
	local PlayerController C;
	local KFPawn_Human CurKFPH;
	local KFPerk CurKFP;
	local int PerkMagSize;
	foreach WorldInfo.AllControllers( class'PlayerController', C)
	    {
	    	CurKFPH = KFPawn_Human(C.AcknowledgedPawn);
	    	CurKFP = CurKFPH.GetPerk();
	    	if ( IsActivePlayer(C) )
	    	{
	    		ForEach CurKFPH.InvManager.InventoryActors(class'KFWeapon', CurKFW)
				{
					PerkMagSize = CurKFW.default.MagazineCapacity[0];
					CurKFP.ModifyMagSizeAndNumber(CurKFW, PerkMagSize);
					PerkMagSize *= (MagSizeMultiplier ** CurKFW.CurrentWeaponUpgradeIndex);
					if (CurKFW.InventoryGroup == IG_Equipment)
					{
						if ( IsKnifeWeapon(CurKFW) )
						{
							KFWeap_Edged_Knife(CurKFW).ParryDamageMitigationPercent = 0.5;
							KFWeap_Edged_Knife(CurKFW).BlockDamageMitigation = 0.5;
						}
						continue;
					}
					else if (CurKFW.CurrentWeaponUpgradeIndex > 0 && CurKFW.MagazineCapacity[0] 
						< PerkMagSize)
					{
						CurKFW.MagazineCapacity[0] *= MagSizeMultiplier;
						CurKFW.MagazineCapacity[1] *= MagSizeMultiplier;
						CurKFW.InstantHitDamage[2] *= HitDamageMultiplier;
						CurKFW.InstantHitMomentum[2] *= 1.5f;
						CurKFW.AmmoPickupScale[0] *= PickupScaleMultiplier;
						CurKFW.AmmoPickupScale[1] *= PickupScaleMultiplier;
						CurKFW.Spread[0] *= 0.75f;
						ReduceWeaponRecoil(CurKFW,0.85f);
						CurKFW.PenetrationPower[0] += 1.0;
						UpgradeMedicWeapon(CurKFW, CurKFW.CurrentWeaponUpgradeIndex);
					}
					else
					{
						CurKFW.BobDamping = 1;
					}
					
					//`log("CurKFW.MagazineCapacity[0] is: " $ CurKFW.MagazineCapacity[0]);
					//`log("PerkMagSize is: " $ PerkMagSize);
			    }
	    	}

		}
}


function ModifyPlayer(Pawn P) // Function to modify the player
{
	super.ModifyPlayer(P);
	SetTimer(15, true, nameof(ModifyUpgradedWeapons));
}

function bool IsActivePlayer(PlayerController C)
{
	if(C.bIsPlayer == false || KFPawn_Human(C.AcknowledgedPawn) == None) //This small check will help loop through all zeds and players quicker
		    		return false;
			    else if( C.bIsPlayer
	        	&& C.PlayerReplicationInfo != none
	        	&& C.PlayerReplicationInfo.bReadyToPlay
	        	&& !C.PlayerReplicationInfo.bOnlySpectator
	        	&& C.GetTeamNum() == 0 ) //Checks for a human player
				{
					return true;
				}
}

defaultproperties
{
	MagSizeMultiplier = 1.15f
	HitDamageMultiplier = 2.25f
	PickupScaleMultiplier = 1.5f
	CustomEnragedGlowColor = (R=0.62f,G=0.47,B=0.93)
}