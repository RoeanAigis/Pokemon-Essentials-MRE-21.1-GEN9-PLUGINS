#===============================================================================
# Hardcoded Midbattle Scripts
#===============================================================================
# You may add Midbattle Handlers here to create custom battle scripts you can
# call on. Unlike other methods of creating battle scripts, you can use these
# handlers to freely hardcode what you specifically want to happen in battle
# instead of the other methods which require specific values to be inputted.
#
# This method requires fairly solid scripting knowledge, so it isn't recommended
# for inexperienced users. As with other methods of calling midbattle scripts,
# you may do so by setting up the "midbattleScript" battle rule.
#
# 	For example:  
#   setBattleRule("midbattleScript", :demo_capture_tutorial)
#
#   *Note that the symbol entered must be the same as the symbol that appears as
#    the second argument in each of the handlers below. This may be named whatever
#    you wish.
#-------------------------------------------------------------------------------

################################################################################
# Demo scenario vs. wild Rotom that shifts forms.
################################################################################

MidbattleHandlers.add(:midbattle_scripts, :demo_wild_rotom,
  proc { |battle, idxBattler, idxTarget, trigger|
    foe = battle.battlers[1]
    case trigger
    when "RoundStartCommand_1_foe"
      battle.pbDisplayPaused(_INTL("{1} emited a powerful magnetic pulse!", foe.pbThis))
      battle.pbAnimation(:CHARGE, foe, foe)
      pbSEPlay("Anim/Paralyze3")
      battle.pbDisplayPaused(_INTL("Your Poké Balls short-circuited!\nThey cannot be used this battle!"))
      battle.disablePokeBalls = true
    when "RoundEnd_foe"
      next if !battle.pbTriggerActivated?("TargetWeakToMove_foe")
      battle.pbAnimation(:NIGHTMARE, foe.pbDirectOpposing(true), foe)
      form = battle.pbRandom(1..5)
      foe.pbSimpleFormChange(form, _INTL("{1} possessed a new appliance!", foe.pbThis))
      foe.pbRecoverHP(foe.totalhp / 4)
      foe.pbCureAttract
      foe.pbCureConfusion
      foe.pbCureStatus
      if foe.ability_id != :MOTORDRIVE
        battle.pbShowAbilitySplash(foe, true, false)
        foe.ability = :MOTORDRIVE
        battle.pbReplaceAbilitySplash(foe)
        battle.pbDisplay(_INTL("{1} acquired {2}!", foe.pbThis, foe.abilityName))
        battle.pbHideAbilitySplash(foe)
      end
      if foe.item_id != :CELLBATTERY
        foe.item = :CELLBATTERY
        battle.pbDisplay(_INTL("{1} equipped a {2} it found in the appliance!", foe.pbThis, foe.itemName))
      end
    when "TargetHPHalf_foe"
      next if battle.pbTriggerActivated?(trigger)
      battle.pbAnimation(:CHARGE, foe, foe)
      if foe.effects[PBEffects::Charge] <= 0
        foe.effects[PBEffects::Charge] = 5
        battle.pbDisplay(_INTL("{1} began charging power!", foe.pbThis))
      end
      if foe.effects[PBEffects::MagnetRise] <= 0
        foe.effects[PBEffects::MagnetRise] = 5
        battle.pbDisplay(_INTL("{1} levitated with electromagnetism!", foe.pbThis))
      end
      battle.pbStartTerrain(foe, :Electric)
    when "UserMoveEffective_player"
      battle.pbDisplayPaused(_INTL("{1} emited an electrical pulse out of desperation!", foe.pbThis))
      battler = battle.battlers[idxBattler]
      if battler.pbCanInflictStatus?(:PARALYSIS, foe, true)
        battler.pbInflictStatus(:PARALYSIS)
      end
    end
  }
)


################################################################################
# Demo scenario vs. Rocket Grunt in a collapsing cave.
################################################################################

MidbattleHandlers.add(:midbattle_scripts, :demo_collapsing_cave,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
	battler = battle.battlers[idxBattler]
    case trigger
    when "RoundStartCommand_1_foe"
      pbSEPlay("Mining collapse")
      battle.pbDisplayPaused(_INTL("The cave ceiling begins to crumble down all around you!"))
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("I am not letting you escape!"))
      battle.pbDisplayPaused(_INTL("I don't care if this whole cave collapses down on the both of us...haha!"))
      scene.pbForceEndSpeech
      battle.pbDisplayPaused(_INTL("Defeat your opponent before time runs out!"))
    when "RoundEnd_player"
      pbSEPlay("Mining collapse")
      battle.pbDisplayPaused(_INTL("The cave continues to collapse all around you!"))
    when "RoundEnd_2_player"
      battle.pbDisplayPaused(_INTL("{1} was struck on the head by a falling rock!", battler.pbThis))
      battle.pbAnimation(:ROCKSMASH, battler.pbDirectOpposing(true), battler)
      old_hp = battler.hp
      battler.hp -= (battler.totalhp / 4).round
      scene.pbHitAndHPLossAnimation([[battler, old_hp, 0]])
      if battler.fainted?
        battler.pbFaint(true)
      elsif battler.pbCanConfuse?(battler, false)
        battler.pbConfuse
      end
    when "RoundEnd_3_player"
      battle.pbDisplayPaused(_INTL("You're running out of time!"))
      battle.pbDisplayPaused(_INTL("You need to escape immediately!"))
    when "RoundEnd_4_player"
      battle.pbDisplayPaused(_INTL("You failed to defeat your opponent in time!"))
      scene.pbRecall(idxBattler)
      battle.pbDisplayPaused(_INTL("You were forced to flee the battle!"))
      pbSEPlay("Battle flee")
      battle.decision = 3
    when "LastTargetHPLow_foe"
      next if battle.pbTriggerActivated?(trigger)
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("My {1} will never give up!", battler.name))
      scene.pbForceEndSpeech
      battle.pbAnimation(:BULKUP, battler, battler)
      battler.displayPokemon.play_cry
      battler.pbRecoverHP(battler.totalhp / 2)
      battle.pbDisplayPaused(_INTL("{1} is standing its ground!", battler.pbThis))
      showAnim = true
      [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStage(stat, 2, battler, showAnim)
        showAnim = false
      end
    when "BattleEndForfeit"
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Haha...you'll never make it out alive!"))
    end
  }
)