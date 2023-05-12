class KFGameConductor2 extends KFGameConductor;

 var private float SoloLowHealthThreshold;

/** Called when a zed does an attack to give an opportunity to scale their attack cooldowns */
function UpdateOverallAttackCoolDowns(KFAIController KFAIC)
{
    local bool bAllowLowZedIntensity;

    //Bypass difficulty check, allow Low Zed Intensity for all difficulties
    bAllowLowZedIntensity = true;

    if( !bBypassGameConductor && bAllowLowZedIntensity )
    {
        if( GameConductorStatus == GCS_ForceLull || OverallRankAndSkillModifier == 0 )
        {
            KFAIC.SetOverallCooldownTimer(KFAIC.LowIntensityAttackCooldown);
        }
        else
        {
            KFAIC.SetOverallCooldownTimer(0.0);
        }
    }

}

function NotifySoloPlayerSurrounded()
{
    if( GameConductorStatus != GCS_ForceLull )
    {
        `log("Human solo player surrounded, forcing a lull for "$SoloPlayerSurroundedForceLullLength$" seconds!", bLogGameConductor);
        GameConductorStatus = GCS_ForceLull;
        SoloPlayerSurroundedForceLullTime = WorldInfo.TimeSeconds;
    }

}

/** Calculate the overall status of the player's rank and performance */
function UpdateOverallStatus()
{
    local float PerkRankModifier;
    local float SkillModifier;
    local float LifeSpanModifier;
    local float HighlySkilledAccuracy, LessSkilledAccuracy;
    local float HighlySkilledZedLifespan, LessSkilledZedLifespan;
    local bool bPlayerHealthLow;
    local int i;

    // Take us out of a forced lull if the time is up
    if( GameConductorStatus == GCS_ForceLull
        && `TimeSince(PlayerDeathForceLullTime) > PlayerDeathForceLullLength
        && `TimeSince(SoloPlayerSurroundedForceLullTime) > SoloPlayerSurroundedForceLullLength )
    {
        GameConductorStatus = GCS_Normal;
        `log("Forced lull completed", bLogGameConductor);
    }

    MyKFGRI.CurrentGameConductorStatus = GameConductorStatus;
    MyKFGRI.CurrentParZedLifeSpan = GetParZedLifeSpan();

    for( i = 0; i < (ArrayCount(MyKFGRI.OverallRankAndSkillModifierTracker) - 1); i++ )
    {
        MyKFGRI.OverallRankAndSkillModifierTracker[i] = MyKFGRI.OverallRankAndSkillModifierTracker[i+1];
    }

    // Bypassing making game conductor adjustments
    if( bBypassGameConductor )
    {
        OverallRankAndSkillModifier = 0.5;
        `log("Bypassing GameConductor adjustment OverallRankAndSkillModifier = "$OverallRankAndSkillModifier, bLogGameConductor);
        MyKFGRI.OverallRankAndSkillModifierTracker[ArrayCount(MyKFGRI.OverallRankAndSkillModifierTracker) -1] = OverallRankAndSkillModifier;
        return;
    }

    // Forced lull, or most of the team dead, or single player nearly dead, so slow things down
    if (WorldInfo.Game.NumPlayers != 1)
    {
        bPlayerHealthLow = PlayersHealthStatus < PlayersLowHealthThreshold;
    }
    else
    {
        bPlayerHealthLow = PlayersHealthStatus < SoloLowHealthThreshold;
    }
    if( GameConductorStatus == GCS_ForceLull
        || (bPlayerHealthLow && (LullCooldownStartTime == 0.f || `TimeSince(LullCooldownStartTime) > LullSettings[GameDifficulty].Cooldown)) )
    {
        OverallRankAndSkillModifier = 0.0;
        `log("Players low on health PlayersHealthStatus: "$PlayersHealthStatus$" chilling things out, OverallRankAndSkillModifier= "$OverallRankAndSkillModifier, bLogGameConductor);
        MyKFGRI.OverallRankAndSkillModifierTracker[ArrayCount(MyKFGRI.OverallRankAndSkillModifierTracker) -1] = OverallRankAndSkillModifier;

        // Start the lull timer. Don't allow lulls to last too long
        if( bPlayerHealthLow && !MyKFGRI.IsTimerActive(nameOf(Timer_EndLull), self) )
        {
            MyKFGRI.SetTimer( LullSettings[GameDifficulty].MaxDuration, false, nameOf(Timer_EndLull), self );
        }

        return;
    }

    // No longer in a lull, reset duration timer
    MyKFGRI.ClearTimer( nameOf(Timer_EndLull), self );

    if( WithinRange(TargetPerkRankRange[GameDifficulty],AveragePlayerPerkRank) )
    {
        PerkRankModifier = GetRangePctByValue( TargetPerkRankRange[GameDifficulty], AveragePlayerPerkRank );
    }
    else if( AveragePlayerPerkRank < TargetPerkRankRange[GameDifficulty].X )
    {
        PerkRankModifier = 0;
    }
    else
    {
        PerkRankModifier = 1;
    }

    // Evaluate player skill if its greater than 15 seconds into the match,
    // so you have some data to go by
    if( MyKFGRI != none && MyKFGRI.ElapsedTime > 15 && AggregatePlayerSkill != 0 )
    {
        HighlySkilledAccuracy = BaseLinePlayerShootingSkill * HighlySkilledAccuracyMod;
        LessSkilledAccuracy = BaseLinePlayerShootingSkill * LessSkilledAccuracyMod;

        if( AggregatePlayerSkill > HighlySkilledAccuracy )
        {
            // Highly skilled players
            SkillModifier = Lerp(0.51,1.0, FMin(1.0,(AggregatePlayerSkill - HighlySkilledAccuracy)/((BaseLinePlayerShootingSkill * HighlySkilledAccuracyModMax) - HighlySkilledAccuracy)));
        }
        else if( AggregatePlayerSkill < LessSkilledAccuracy )
        {
            // Less skilled players
            SkillModifier = Lerp(0.49,0.0, FMax(0,(LessSkilledAccuracy - AggregatePlayerSkill)/(LessSkilledAccuracy - (BaseLinePlayerShootingSkill * LessSkilledAccuracyModMin))));
        }
        else
        {
            // Standard skilled players
            SkillModifier = 0.5;
        }
    }
    else
    {
        // Standard skilled players
        SkillModifier = 0.5;
    }

    if( RecentZedVisibleAverageLifeSpan > 0 )
    {
        HighlySkilledZedLifespan = GetParZedLifeSpan() * ZedLifeSpanHighlySkilledThreshold;
        LessSkilledZedLifespan = GetParZedLifeSpan() * ZedLifeSpanLessSkilledThreshold;

        if( RecentZedVisibleAverageLifeSpan < HighlySkilledZedLifespan )
        {
            // Highly skilled players
            LifeSpanModifier = Lerp(0.51,1.0, FMin(1.0,(HighlySkilledZedLifespan - RecentZedVisibleAverageLifeSpan)/( HighlySkilledZedLifespan - (GetParZedLifeSpan() * ZedLifeSpanHighlySkilledThresholdMin))));

        }
        else if( RecentZedVisibleAverageLifeSpan > LessSkilledZedLifespan )
        {
            // Less skilled players
            LifeSpanModifier = Lerp(0.49,0.0, FMin(1.0,(RecentZedVisibleAverageLifeSpan - LessSkilledZedLifespan)/((GetParZedLifeSpan() * ZedLifeSpanLessSkilledThresholdMax) - LessSkilledZedLifespan)));
        }
        else
        {
            // Standard skilled players
            LifeSpanModifier = 0.5;
        }
    }
    else
    {
        // Standard skilled players
        LifeSpanModifier = 0.5;
    }

    OverallRankAndSkillModifier = PerkRankModifier * PerkRankPercentOfOverallSkill + SkillModifier * AccuracyPercentOfOverallSkill + LifeSpanModifier * ZedLifeSpanPercentOfOverallSkill;
    MyKFGRI.OverallRankAndSkillModifierTracker[ArrayCount(MyKFGRI.OverallRankAndSkillModifierTracker) -1] = OverallRankAndSkillModifier;

    `log("PerkRankModifier = "$PerkRankModifier$" SkillModifier = "$SkillModifier$" LifeSpanModifier = "$LifeSpanModifier$" OverallRankAndSkillModifier= "$OverallRankAndSkillModifier$" GetParZedLifeSpan() = "$GetParZedLifeSpan(), bLogGameConductor);
}

defaultproperties
{
PlayersLowHealthThreshold = 0.65
SoloLowHealthThreshold = 0.35
}
