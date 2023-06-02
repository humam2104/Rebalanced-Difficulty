class KFGameDifficultyInfo2 extends KFGameDifficultyInfo;

var byte NumofAlivePlayers;

/** Returns adjusted total num AI modifier for this wave's player num */
function float GetPlayerNumMaxAIModifier( byte NumLivingPlayers )
{
	NumofAlivePlayers = NumLivingPlayers;
	return GetNumPlayersModifier( NumPlayers_WaveSize, NumLivingPlayers );
}

/**	Scales the damage this Zed deals by the difficulty level */
function float GetAIDamageModifier(KFPawn_Monster P, float GameDifficulty, bool bSoloPlay)
{
    local float PerZedDamageMod, SoloPlayDamageReductionFactor, DifficultyDifference,SoloPlayDamageMod;

    // default if no InMonsterInfo
    PerZedDamageMod = 1.0;
    SoloPlayDamageReductionFactor = 1.0;

    if( P.DifficultySettings != none )
    {
    	if ( GameDifficulty >= `DIFFICULTY_HELLONEARTH )
    	{
    		PerZedDamageMod = P.DifficultySettings.default.HellOnEarth.DamageMod * 0.85f;
            SoloPlayDamageReductionFactor = P.DifficultySettings.default.HellOnEarth.SoloDamageMod;
    	}
    	else if ( GameDifficulty >= `DIFFICULTY_SUICIDAL )
    	{
    		PerZedDamageMod = P.DifficultySettings.default.Suicidal.DamageMod * 0.85f;
            SoloPlayDamageReductionFactor = P.DifficultySettings.default.Suicidal.SoloDamageMod;
    	}
    	else if ( GameDifficulty >= `DIFFICULTY_HARD )
    	{
    		PerZedDamageMod = P.DifficultySettings.default.Hard.DamageMod;
            SoloPlayDamageReductionFactor = P.DifficultySettings.default.Hard.SoloDamageMod;
    	}
    	else
    	{
            PerZedDamageMod = P.DifficultySettings.default.Normal.DamageMod;
            SoloPlayDamageReductionFactor = P.DifficultySettings.default.Normal.SoloDamageMod;
    	}
		SoloPlayDamageMod = PerZedDamageMod * SoloPlayDamageReductionFactor;

		//Linearly changes the difficulty of coop from solo to 6p difficulty
		DifficultyDifference = abs(PerZedDamageMod - SoloPlayDamageMod) * float(NumofAlivePlayers) / 6;
		return (SoloPlayDamageMod + DifficultyDifference);
	}
	
}


DefaultProperties
{
	
}


