#===============================================================================
# Module for storing all midbattle scripts.
#===============================================================================
module MidbattleHandlers
  @@scripts = {}

  def self.add(midbattle, id, proc)
    @@scripts[midbattle] = HandlerHash.new if !@@scripts.has_key?(midbattle)
    @@scripts[midbattle].add(id, proc)
  end

  def self.remove(midbattle, id)
    @@scripts[midbattle]&.remove(id)
  end

  def self.clear(midbattle)
    @@scripts[midbattle]&.clear
  end
  
  def self.exists?(midbattle, id)
    return !@@scripts[midbattle][id].nil?
  end

  def self.trigger(midbattle, id, battle, idxBattler, idxTarget, params)
    return nil if !@@scripts.has_key?(midbattle)
    script_hash = @@scripts[midbattle][id]
    return nil if !script_hash
    return script_hash.call(battle, idxBattler, idxTarget, params)
  end
end


################################################################################
#
# Midbattle utilities.
#
################################################################################

#-------------------------------------------------------------------------------
# Sets a new battler as the focus.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "setBattler",
  proc { |battle, idxBattler, idxTarget, params|
    idxBattler = 0 if idxBattler.nil?
    idxTarget  = 1 if idxTarget.nil?
    default_battler = battle.battlers[idxBattler]
    default_target  = battle.battlers[idxTarget]
    default_target  = default_battler.pbDirectOpposing if default_target.index == default_battler.index
    case params
    when Integer        then next battle.battlers[params] || default_battler
    when :Self          then next default_battler
    when :Ally          then next default_battler.allAllies.first || default_battler
    when :Ally2         then next default_battler.allAllies.last  || default_battler
    when :Opposing      then next default_target
    when :OpposingAlly  then next default_target.allAllies.first  || default_target
    when :OpposingAlly2 then next default_target.allAllies.last   || default_target
    end
    next default_battler
  }
)

#-------------------------------------------------------------------------------
# Pauses any further script commands for a certain duration.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "wait",
  proc { |battle, idxBattler, idxTarget, params|
    pbWait(params)
  }
)

#-------------------------------------------------------------------------------
# Ignores any further script commands until a certain trigger is detected.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "ignoreUntil",
  proc { |battle, idxBattler, idxTarget, params|
    ignore = true
    triggers = battle.activated_triggers
    params = [params] if !params.is_a?(Array)
    params.each { |t| ignore = false if triggers.include?(t) }
    next ignore
  }
)

#-------------------------------------------------------------------------------
# Ignores any further script commands after a certain trigger is detected.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "ignoreAfter",
  proc { |battle, idxBattler, idxTarget, params|
    ignore = false
    triggers = battle.activated_triggers
    params = [params] if !params.is_a?(Array)
    params.each { |t| ignore = true if triggers.include?(t) }
    next ignore
  }
)

#-------------------------------------------------------------------------------
# Toggles the state of a particular game switch.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "toggleSwitch",
  proc { |battle, idxBattler, idxTarget, params|
    if params.is_a?(Integer) && params >= 0
      $game_switches[params] = !$game_switches[params]
    end
  }
)

#-------------------------------------------------------------------------------
# Sets the value of the midbattle variable.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "setVariable",
  proc { |battle, idxBattler, idxTarget, params|
    if params.is_a?(Array)
      battle.midbattleVariable = params.sample
    else
      battle.midbattleVariable = params
    end
    battle.midbattleVariable = 0 if battle.midbattleVariable < 0
  }
)

#-------------------------------------------------------------------------------
# Adds to the value of the midbattle variable.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "addVariable",
  proc { |battle, idxBattler, idxTarget, params|
    if params.is_a?(Array)
      battle.midbattleVariable += params.sample
    else
      battle.midbattleVariable += params
    end
    battle.midbattleVariable = 0 if battle.midbattleVariable < 0
  }
)

#-------------------------------------------------------------------------------
# Multiplies the value of the midbattle variable.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "multVariable",
  proc { |battle, idxBattler, idxTarget, params|
    battle.midbattleVariable *= params
    battle.midbattleVariable.round
    battle.midbattleVariable = 0 if battle.midbattleVariable < 0
  }
)


################################################################################
#
# Text and speech.
#
################################################################################

#-------------------------------------------------------------------------------
# Displays one or more lines of normal battle text.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "text",
  proc { |battle, idxBattler, idxTarget, params|
    battle.scene.pbForceEndSpeech
    params = [params] if !params.is_a?(Array)
    battle.scene.pbProcessText(idxBattler, idxTarget, false, params.clone)
  }
)

#-------------------------------------------------------------------------------
# Displays one or more lines of cinematic speech.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "speech",
  proc { |battle, idxBattler, idxTarget, params|
    params = [params] if !params.is_a?(Array)
    battle.scene.pbProcessText(idxBattler, idxTarget, true, params.clone)
  }
)

#-------------------------------------------------------------------------------
# Sets up data for the next choice option in text/speech.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "setChoices",
  proc { |battle, idxBattler, idxTarget, params|
    battle.midbattleChoices = params.clone
  }
)
	
#-------------------------------------------------------------------------------
# Slides a speaker on screen to begin cinematic speech.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "setSpeaker",
  proc { |battle, idxBattler, idxTarget, params|
    if !battle.scene.pbInCinematicSpeech?
      battle.scene.pbToggleDataboxes 
      battle.scene.pbToggleBlackBars(true)
    end
    battle.scene.pbHideSpeaker
    next if params == :Hide
    params = battle.battlers[idxBattler] if params == :Battler
    battle.scene.pbShowSpeaker(idxBattler, idxTarget, params)
    speaker = battle.scene.pbGetSpeaker
    battle.scene.pbShowSpeakerWindows(speaker)
  }
)

#-------------------------------------------------------------------------------
# Sets a new speaker sprite during speech instead of swapping out speakers.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "editSpeaker",
  proc { |battle, idxBattler, idxTarget, params|
    next if !battle.scene.pbInCinematicSpeech?
    if params.is_a?(Array) && params[0].is_a?(Array)
      speaker, window = params[0], [params[1], params[2]]
    else
      speaker, window = params, []
    end
    if params == :Hide
      battle.scene.pbHideSpeaker
    else
      battle.scene.pbUpdateSpeakerSprite(*speaker)
      speaker = battle.scene.pbGetSpeaker
      if window.empty?
        battle.scene.pbUpdateSpeakerWindows(speaker)
      else
        battle.scene.pbUpdateSpeakerWindows(*window)
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Edits the display of the speaker's text windows during speech.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "editWindow",
  proc { |battle, idxBattler, idxTarget, params|
    next if !battle.scene.pbInCinematicSpeech?
    case params
    when :Hide
      battle.scene.pbHideSpeakerWindows(true)
    when :Show
      speaker = battle.scene.pbGetSpeaker
      battle.scene.pbShowSpeakerWindows(speaker)
    else
      battle.scene.pbShowSpeakerWindows(*params)
    end
  }
)

#-------------------------------------------------------------------------------
# Ends cinematic speech.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "endSpeech",
  proc { |battle, idxBattler, idxTarget, params|
    battle.scene.pbForceEndSpeech
  }
)

################################################################################
#
# Audio and animations.
#
################################################################################

#-------------------------------------------------------------------------------
# Plays a SE.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "playSE",
  proc { |battle, idxBattler, idxTarget, params|
    pbSEPlay(params)
  }
)

#-------------------------------------------------------------------------------
# Plays a Pokemon cry.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "playCry",
  proc { |battle, idxBattler, idxTarget, params|
    idx = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, params)
    if idx.is_a?(Integer)
      next if !battle.battlers[idx]
      battle.battlers[idx].displayPokemon.play_cry
    else
      GameData::Species.play_cry(params)
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the BGM.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeBGM",
  proc { |battle, idxBattler, idxTarget, params|
    if params.is_a?(Array)
      bgm, fade, vol, pitch = params[0], params[1] * 1.0, params[2], params[3]
    else
      bgm, fade, vol, pitch = params, 0.0, nil, nil
    end
    pbBGMFade(fade)
    pbWait(fade)
    pbBGMPlay(bgm, vol, pitch)
  }
)

#-------------------------------------------------------------------------------
# Plays an animation.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "playAnim",
  proc { |battle, idxBattler, idxTarget, params|
    if params.is_a?(Array)
      anim = params[0]
      user = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, params[1])
      target = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, params[2])
    else
      anim, user, target = params, idxBattler, nil
    end
    if target.nil? && GameData::Move.exists?(anim)
      case GameData::Move.get(anim).target
      when :NearAlly
        target = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, :Ally)
      when :Foe, :NearFoe, :RandomNearFoe, :NearOther, :Other
        target = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, :Opposing)
      else
        target = battle.scene.pbConvertBattlerIndex(idxBattler, idxTarget, :Self)
      end
    end
    target = user if !target
    user = battle.battlers[user]
    target = battle.battlers[target]
    case anim
    when "Recall" then battle.scene.pbRecall(target.index || user.index)
    when Symbol   then battle.pbAnimation(anim, user, target)
    when String   then battle.pbCommonAnimation(anim, user, target)
    end
  }
)


################################################################################
#
# Manipulates the usage of battle mechanics.
#
################################################################################

#-------------------------------------------------------------------------------
# Forces a trainer to use an item.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "useItem",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    item = (params.is_a?(Array)) ? params.sample : params
    next if !item || !GameData::Item.exists?(item) 
    battler = battle.battlers[idxBattler]
    if GameData::Item.get(item).is_poke_ball?
      battler = battler.pbDirectOpposing(true) if !battler.opposes?
    end
    next if !battler || battler.fainted?
    ch = battle.choices[battler.index]
    if [:ETHER, :MAXETHER, :LEPPABERRY].include?(item)
      lowest_pp_idx = ch[1]
      lowest_pp = battler.moves[lowest_pp_idx].pp
      battler.pokemon.moves.each_with_index do |m, i|
        next if m.pp >= m.total_pp
        next if m.pp >= lowest_pp
        lowest_pp = m.pp
        lowest_pp_idx = i
      end
      ch[1] = lowest_pp_idx
    end
    next if !ItemHandlers.triggerCanUseInBattle(
      item, battler.pokemon, battler, ch[1], true, battle, battle.scene, false)
    battle.scene.pbForceEndSpeech
    if !GameData::Item.get(item).is_poke_ball?
      trainerName = (battler.wild?) ? battler.name : battle.pbGetOwnerName(battler.index) 
      battle.pbUseItemMessage(item, trainerName)
    end
    if ItemHandlers.hasUseInBattle(item)
      ItemHandlers.triggerUseInBattle(item, battler, battle)
    elsif ItemHandlers.hasBattleUseOnBattler(item)
      ItemHandlers.triggerBattleUseOnBattler(item, battler, battle.scene)
      battler.pbItemOnStatDropped
    elsif ItemHandlers.hasBattleUseOnPokemon(item)
      ItemHandlers.triggerBattleUseOnPokemon(item, battler.pokemon, battler, ch, battle.scene)
    else
      battle.pbDisplay(_INTL("But it had no effect!"))
    end
  }
)

#-------------------------------------------------------------------------------
# Forces a battler to use a specific move on a specific target.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "useMove",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    next if battler.movedThisRound? ||
            battler.effects[PBEffects::ChoiceBand]    ||
            battler.effects[PBEffects::Instructed]    ||
            battler.effects[PBEffects::TwoTurnAttack] ||
            battler.effects[PBEffects::Encore]    > 0 ||
            battler.effects[PBEffects::HyperBeam] > 0 ||
            battler.effects[PBEffects::Outrage]   > 0 ||
            battler.effects[PBEffects::Rollout]   > 0 ||
            battler.effects[PBEffects::Uproar]    > 0 ||
            battler.effects[PBEffects::SkyDrop] >= 0
    ch = battle.choices[battler.index]
    next if ch[0] != :UseMove
    next if ch[2].powerMove?
    if params.is_a?(Array)
      id = params[0]
      target = params[1] || -1
    else
      id, target = params, -1
    end
    target = battle.battlers[target]
    case id
    when Integer
      idxMove = id
    when Symbol
      idxMove = -1
      battler.eachMoveWithIndex { |m, i| idxMove = i if m.id == id }
    when String
      st = id.split("_")
      eligible_moves = []
      battler.eachMoveWithIndex do |m, i|
        case st[0]
        when "Damage" then next if !m.damagingMove?
        when "Status" then next if !m.statusMove? || m.healingMove?
        when "Heal"   then next if !m.healingMove?
        end
        if target && m.damagingMove?
          effect = Effectiveness.calculate(m.pbCalcType(battler), *target.pbTypes(true))
          next if Effectiveness.ineffective?(effect)
          next if Effectiveness.not_very_effective?(effect)
        end
        targ = GameData::Target.get(GameData::Move.get(m.id).target)
        case st[1]
        when "self"
          next if ![:User, :UserOrNearAlly, :UserAndAllies].include?(targ.id)
        when "ally"
          next if targ.num_targets == 0
          next if ![:NearAlly, :UserOrNearAlly, :AllAllies, :NearOther, :Other].include?(targ.id)
        when "foe"
          next if targ.num_targets == 0
          next if !targ.targets_foe
        end
        eligible_moves.push(i)
      end
      idxMove = eligible_moves.sample || -1
    end
    next if !battler.moves[idxMove]
    next if !battle.pbCanChooseMove?(battler.index, idxMove, false)
    battle.scene.pbForceEndSpeech
    targ = GameData::Target.get(battler.moves[idxMove].target)
    if targ.num_targets != 0
      has_target = target && !target.fainted? && target.near?(battler)
      if targ.targets_foe
        if !has_target || target.idxOwnSide == battler.idxOwnSide
          target = battler.pbDirectOpposing(true)
        end
      elsif targ == :NearAlly
        if !has_target || target.idxOwnSide != battler.idxOwnSide
          battler.allAllies.each { |b| target = b if battler.near?(b) }
        end
      end
    else
      target = battler
    end
    ch[1] = idxMove
    ch[2] = battler.moves[idxMove]
    ch[3] = target.index
    battle.pbCalculatePriority(false, [idxBattler]) if ch[2].priority != 0
  }
)

#-------------------------------------------------------------------------------
# Forces a trainer to switch Pokemon.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "switchOut",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battler.wild? || battle.decision > 0
    next if !battle.pbCanSwitchOut?(idxBattler)
    if params.is_a?(Array)
      switch, msg = params[0], params[1]
    else
      switch, msg = params, nil
    end
    newPkmn = nil
    canSwitch = false
    battle.eachInTeamFromBattlerIndex(battler.index) do |pkmn, i|
      next if !battle.pbCanSwitchIn?(idxBattler, i)
      case switch
      when Integer
        next if switch != i
        newPkmn = i
      when Symbol
        next if !GameData::Species.exists?(switch)
        next if switch != pkmn.species
        newPkmn = i
      end
      canSwitch = true
      break
    end
    if canSwitch
      battle.scene.pbForceEndSpeech
      if newPkmn.nil?
        case switch
        when :Choose
          newPkmn = battle.pbSwitchInBetween(battler.index)
        else
          newPkmn = battle.pbGetReplacementPokemonIndex(battler.index, true)
        end
      end
      if newPkmn && newPkmn >= 0
        trainerName = battle.pbGetOwnerName(battler.index)
        if msg
          lowercase = (msg && msg[0] == "{" && msg[1] == "1") ? false : true
          msg = _INTL("#{msg}", battler.pbThis(lowercase), trainerName)
          battle.pbDisplay(msg.gsub(/\\PN/i, battle.pbPlayer.name))
        end
        case switch
        when :Forced
          battle.pbDisplay(_INTL("{1} went back to {2}!", battler.pbThis, trainerName))
          battle.pbRecallAndReplace(battler.index, newPkmn, true)
          battle.pbDisplay(_INTL("{1} was dragged out!", battler.pbThis))
        else
          battle.pbMessageOnRecall(battler)
          battle.pbRecallAndReplace(battler.index, newPkmn)
        end
        battle.pbClearChoice(battler.index)
        battle.pbOnBattlerEnteringBattle(battler.index)
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Forces a trainer to Mega Evolve.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "megaEvolve",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !params || !battler || battler.fainted? || battle.decision > 0
    ch = battle.choices[battler.index]
    next if ch[0] != :UseMove
    oldMode = battle.wildBattleMode
    battle.wildBattleMode = :mega if battler.wild? && oldMode != :mega
    if battle.pbCanMegaEvolve?(battler.index)
      battle.scene.pbForceEndSpeech
      battle.pbDisplay(params.gsub(/\\PN/i, battle.pbPlayer.name)) if params.is_a?(String)
      battle.pbMegaEvolve(battler.index)
    end
    battle.wildBattleMode = oldMode
  }
)

#-------------------------------------------------------------------------------
# Toggles the availability of Mega Evolution for trainers.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableMegas",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler 
    side = (battler.opposes?) ? 1 : 0
    owner = battle.pbGetOwnerIndexFromBattlerIndex(idxBattler)
    battle.megaEvolution[side][owner] = (params) ? -2 : -1
  }
)

#-------------------------------------------------------------------------------
# Toggles the player's ability to use Poke Balls.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableBalls",
  proc { |battle, idxBattler, idxTarget, params|
    battle.disablePokeBalls = params
  }
)

#-------------------------------------------------------------------------------
# Toggles the player's controls being handled by the AI.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableControl",
  proc { |battle, idxBattler, idxTarget, params|
    battle.controlPlayer = params
  }
)

#-------------------------------------------------------------------------------
# Prematurely forces the battle to end.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "endBattle",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    params = 1 if params == 4
    battle.scene.pbForceEndSpeech
    battle.decision = params
  }
)

#-------------------------------------------------------------------------------
# Forces a wild Pokemon to flee.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "wildFlee",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if battle.decision > 0 || !battler || !battler.wild?
    battle.scene.pbForceEndSpeech
    battler.wild_flee(params) 
  }
)


################################################################################
#
# Battler conditions.
#
################################################################################

#-------------------------------------------------------------------------------
# Changes a battler's name.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerName",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    if !nil_or_empty?(params)
      battler.pokemon.name = params
      battler.name = params
      battle.scene.pbRefresh
    end
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's HP.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerHP",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    battle.scene.pbForceEndSpeech
    if params.is_a?(Array)
      amt, msg = params[0], params[1]
    else
      amt, msg = params, nil
    end
    lowercase = (msg && msg[0] == "{" && msg[1] == "1") ? false : true
    trainerName = (battler.wild?) ? "" : battle.pbGetOwnerName(battler.index)
    msg = _INTL("#{msg}", battler.pbThis(lowercase), trainerName) if msg
    old_hp = battler.hp
    if amt > 0
	  battler.stopBoostedHPScaling = true
      battler.pbRecoverHP(battler.totalhp / amt)
    elsif amt <= 0
      if amt == 0
        battler.hp = 0
      else
        battler.hp -= ((battler.totalhp / amt.abs).round).clamp(1, battler.hp - 1)
      end
      battle.scene.pbHitAndHPLossAnimation([[battler, old_hp, 0]])
    end
    if battler.hp != old_hp
      battle.pbDisplay(msg.gsub(/\\PN/i, battle.pbPlayer.name)) if msg
      battler.pbFaint(true) if battler.fainted?
    end
  }
)

#-------------------------------------------------------------------------------
# Sets a cap for how much HP the battler is capable of losing from attacks.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerHPCap",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    battler.damageThreshold = params
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's status condition.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerStatus",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    battle.scene.pbForceEndSpeech
    if params.is_a?(Array)
      status, msg = params[0], params[1]
    else
      status, msg = params, false
    end
    status = status.sample if status.is_a?(Array)
    case status
    when :Random
      statuses = []
      GameData::Status.each { |s| statuses.push(s.id) if s.id != :NONE }
      statuses.shuffle.each do |s|
        next if !battler.pbCanInflictStatus?(s, battler)
        count = ([:SLEEP, :DROWSY].include?(s)) ? battler.pbSleepDuration : 0
        battler.pbInflictStatus(status, count)
        break
      end
    when :NONE
      battler.pbCureAttract
      battler.pbCureConfusion
      battler.pbCureStatus(msg)
    when :CONFUSE, :CONFUSED, :CONFUSION
      battler.pbConfuse(msg) if battler.pbCanConfuse?(battler, msg)
    when :BAD_POISON, :TOXIC, :TOXIC_POISON
      battler.pbPoison(nil, msg, true) if battler.pbCanPoison?(battler, msg)
    else
      if GameData::Status.exists?(status) && battler.pbCanInflictStatus?(status, battler, msg)
        count = ([:SLEEP, :DROWSY].include?(status)) ? battler.pbSleepDuration : 0
        battler.pbInflictStatus(status, count)
      end
    end
    battler.pbCheckFormOnStatusChange
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's form.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerForm",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    if params.is_a?(Array)
      form, msg = params[0], params[1]
    else
      form, msg = params, nil
    end
    if msg.is_a?(String)
      lowercase = (msg[0] == "{" && msg[1] == "1") ? false : true
      trainerName = (battler.wild?) ? "" : battle.pbGetOwnerName(battler.index)
      msg = _INTL("#{msg}", battler.pbThis(lowercase), trainerName)
    end
    case form
    when :Cycle
      form = battler.form + 1
    when :Random
      total_forms = []
      GameData::Species.each do |s|
        next if s.species != battler.species
        next if s.form == battler.form || s.form == 0
        next if s.has_special_form?
        total_forms.push(s.form)
      end
      form = total_forms.sample
    end
    next if !form
    species = GameData::Species.get_species_form(battler.species, form)
    if species.has_special_form?
      form = 0
    else
      form = species.form
    end
    next if battler.form == form
    battle.scene.pbForceEndSpeech
    battler.pbSimpleFormChange(form, msg)
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's ability.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerAbility",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    if params.is_a?(Array)
      abil, msg = params[0], params[1]
    else
      abil, msg = params, nil
    end
    abil = abil.sample if abil.is_a?(Array)
    abil = battler.pokemon.ability_id if abil == :Reset
    next if !abil || !GameData::Ability.exists?(abil)
    next if battler.ability_id == abil
    next if battler.ungainableAbility?(abil)
    next if battler.unstoppableAbility?
    battle.pbShowAbilitySplash(battler, true, false) if msg
    oldAbil = battler.ability
    battler.ability = abil
    battle.scene.pbForceEndSpeech
    if msg
      battle.pbReplaceAbilitySplash(battler)
      if msg.is_a?(String)
        lowercase = (msg[0] == "{" && msg[1] == "1") ? false : true
        trainerName = (battler.wild?) ? "" : battle.pbGetOwnerName(battler.index)
        msg = _INTL("#{msg}", battler.pbThis(lowercase), trainerName)
        battle.pbDisplay(msg.gsub(/\\PN/i, battle.pbPlayer.name))
      else
        battle.pbDisplay(_INTL("{1} acquired {2}!", battler.pbThis, battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
    battler.pbOnLosingAbility(oldAbil)
    battler.pbTriggerAbilityOnGainingIt
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's held item.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerItem",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    if params.is_a?(Array)
      item, msg = params[0], params[1]
    else
      item, msg = params, nil
    end
    item = item.sample if item.is_a?(Array)
    next if !item || !GameData::Item.exists?(item)
    next if battler.unlosableItem?(item)
    next if battler.item_id == item
    if msg.is_a?(String)
      lowercase = (msg[0] == "{" && msg[1] == "1") ? false : true
      trainerName = (battler.wild?) ? "" : battle.pbGetOwnerName(battler.index)
      msg = _INTL("#{msg}", battler.pbThis(lowercase), trainerName)
    end
    olditem = battler.item
    battle.scene.pbForceEndSpeech
    case item
    when :Remove
      next if !battler.item
      battler.item = nil
      if msg && !msg.is_a?(String)
        itemName = GameData::Item.get(olditem).portion_name
        battle.pbDisplay(_INTL("{1}'s held {2} was removed!", battler.pbThis, itemName))
      end
    else
      battler.item = item
      if msg && !msg.is_a?(String)
        itemName = GameData::Item.get(battler.item).portion_name
        prefix = (itemName.starts_with_vowel?) ? "an" : "a"
        battle.pbDisplay(_INTL("{1} obtained {2} {3}!", battler.pbThis, prefix, itemName))
      end
    end
    if msg.is_a?(String)
      battle.pbDisplay(msg.gsub(/\\PN/i, battle.pbPlayer.name))
    end
    battler.pbCheckFormOnHeldItemChange
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's moves.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerMoves",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    case params
    when Array
      Pokemon::MAX_MOVES.times do |i|
        new_move = params[i]
        battler.moves[i] = new_move if new_move.nil?
        next if !GameData::Move.exists?(new_move)
        move = Pokemon::Move.new(new_move)
        battler.moves[i] = Battle::Move.from_pokemon_move(battle, move)
      end
      battler.moves.compact!
      battler.moves.uniq!
    when :Reset
      battler.pokemon.reset_moves
      battler.pokemon.numMoves.times do |i|
        move = battler.pokemon.moves[i]
        battler.moves[i] = Battle::Move.from_pokemon_move(battle, move)
      end
    else
      move_data = GameData::Move.try_get(params)
      next if !move_data || battler.pbHasMove?(params)
      move = Pokemon::Move.new(params)
      battler.moves.push(Battle::Move.from_pokemon_move(battle, move))
      battler.moves.shift if @battler.moves.length > Pokemon::MAX_MOVES
    end
    battler.pbCheckFormOnMovesetChange
  }
)

#-------------------------------------------------------------------------------
# Changes a battler's stat stages.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerStats",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    battle.scene.pbForceEndSpeech
    case params
    when :Reset
      if battler.hasAlteredStatStages?
        battler.pbResetStatStages
        battle.pbDisplay(_INTL("{1}'s stat changes returned to normal!", battler.pbThis))
      end
    when :ResetRaised
      if battler.hasRaisedStatStages?
        battler.statsDropped = true
        battler.statsLoweredThisRound = true
        GameData::Stat.each_battle { |s| battler.stages[s.id] = 0 if battler.stages[s.id] > 0 }
        battle.pbDisplay(_INTL("{1}'s raised stats returned to normal!", battler.pbThis))
      end
    when :ResetLowered
      if battler.hasLoweredStatStages?
        battler.statsRaisedThisRound = true
        GameData::Stat.each_battle { |s| battler.stages[s.id] = 0 if battler.stages[s.id] < 0 }
        battle.pbDisplay(_INTL("{1}'s lowered stats returned to normal!", battler.pbThis))
      end
    when Array
      showAnim = true
      last_change = 0
      rand_stats = []
      GameData::Stat.each_battle do |s| 
        next if params.include?(s.id)
        rand_stats.push(s.id)
      end
      for i in 0...params.length / 2
        stat, stage = params[i * 2], params[i * 2 + 1]
        next if !stage.is_a?(Integer) || stage == 0
        if stat == :Random
          loop do
            break if rand_stats.empty?
            randstat = rand_stats.sample
            rand_stats.delete(randstat) if randstat
            next if params.include?(randstat)
            stat = randstat
            break
          end
        end
        next if !stat.is_a?(Symbol) || !GameData::Stat.exists?(stat)
        if stage > 0
          next if !battler.pbCanRaiseStatStage?(stat, battler)
          showAnim = true if !showAnim && last_change < 0
          if battler.pbRaiseStatStage(stat, stage, battler, showAnim)
            last_change = stage
            showAnim = false
          end
        else
          next if !battler.pbCanLowerStatStage?(stat, battler)
          showAnim = true if !showAnim && last_change > 0
          if battler.pbLowerStatStage(stat, stage.abs, battler, showAnim)
            last_change = stage
            showAnim = false
          end
          break if battler.pbItemOnStatDropped
        end
      end
      battler.pbItemStatRestoreCheck
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the effects on a battler.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "battlerEffects",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted? || battle.decision > 0
    effects = (params[0].is_a?(Array)) ? params : [params]
    effects.each do |array|
      id, value, msg = *array
      effect = PBEffects.const_get(id)
      next if !effect
      lowercase = (msg && msg[0] == "{" && msg[1] == "1") ? false : true
      battler_name = battler.pbThis(lowercase)
      battle.scene.pbForceEndSpeech if msg
      if $DELUXE_PBEFFECTS[:battler][:boolean].include?(id)
        next if battler.effects[effect] == value
        next if [:TwoTurnAttack, :Transform].include?(id)
        case id
        when :Nightmare
          next if !battler.asleep?
        when :ExtraType
          next if !value.nil? && (!GameData::Type.exists?(value) || battler.pbHasType?(value))
        end
        battler.effects[effect] = value
        battle.pbDisplay(_INTL(msg, battler_name)) if msg
      elsif $DELUXE_PBEFFECTS[:battler][:counter].include?(id)
        next if battler.effects[effect] == 0 && value == 0
        case id
        when :Yawn
          next if battler.status != :NONE
        when :FuryCutter
          maxMult = 1
          power = GameData::Move.get(:FURYCUTTER).power
          while (power << (maxMult - 1)) < 160
            maxMult += 1
          end
          next if battler.effects[effect] >= maxMult
        when :MagnetRise, :Telekinesis
          next if battle.field.effects[PBEffects::Gravity] > 0
          next if id == :Telekinesis && battler.mega? && battler.isSpecies?(:GENGAR)
        when :Substitute, :WeightChange, :FocusEnergy
          battler.effects[effect] += value
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
          next
        when :Stockpile
          next if battler.effects[effect] == 3
          battler.effects[effect] += (value).clamp(1, 3 - battler.effects[effect])
          battler.effects[PBEffects::StockpileDef] = battler.effects[effect]
          battler.effects[PBEffects::StockpileSpDef] = battler.effects[effect]
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
          next
        end
        next if battler.effects[effect] > 0 && value > 0
        case id
        when :LockOn, :Trapping, :Syrupy
          opposing = battler.pbDirectOpposing(true)
          next if !opposing || opposing.fainted?
          case id
          when :LockOn   then subeffect = PBEffects::LockOnPos
          when :Trapping then subeffect = PBEffects::TrappingUser
          when :Syrupy   then subeffect = PBEffects::SyrupyUser
          end
          battler.effects[subeffect] = opposing.index
        when :Disable, :Encore
          next if !battler.lastMoveUsed
          case id
          when :Disable then subeffect = PBEffects::DisableMove
          when :Encore  then subeffect = PBEffects::EncoreMove
          end
          battler.effects[subeffect] = battler.lastMoveUsed
        end
        battler.effects[effect] = value
        battle.pbDisplay(_INTL(msg, battler_name)) if msg
      elsif $DELUXE_PBEFFECTS[:battler][:index].include?(id)
        next if battler.effects[effect] == -1 && value == -1
        next if value >= 0 && !battle.battlers[value]
        next if id == :SkyDrop
        battler.effects[effect] = value
        battle.pbDisplay(_INTL(msg, battler_name)) if msg
      end
    end
  }
)


################################################################################
#
# Battlefield conditions.
#
################################################################################

#-------------------------------------------------------------------------------
# Changes the effects on one side of the battlefield.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "teamEffects",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battle.decision > 0
    index = battler.idxOwnSide
    if battler.index.odd?
      index = (battler.idxOwnSide == 0) ? 1 : 0
    end
    case index
    when 0 then side = battler.pbOwnSide
    when 1 then side = battler.pbOpposingSide
    end
    effects = (params[0].is_a?(Array)) ? params : [params]
    effects.each do |array|
      id, value, msg = *array
      effect = PBEffects.const_get(id)
      next if !effect
      battle.scene.pbForceEndSpeech if msg
      lowercase = (msg && msg[0] == "{" && msg[1] == "1") ? false : true
      case index
      when 0 then team_name = battler.pbTeam(lowercase)
      when 1 then team_name = battler.pbOpposingTeam(lowercase)
      end
      if $DELUXE_PBEFFECTS[:team][:boolean].include?(id)
        next if side.effects[effect] == value
        side.effects[effect] = value
        battle.pbDisplay(_INTL(msg, team_name)) if msg
      elsif $DELUXE_PBEFFECTS[:team][:counter].include?(id)
        case id
        when :Spikes, :ToxicSpikes
          max = (id == :Spikes) ? 3 : 2
          if value > 0
            next if side.effects[effect] >= max
            side.effects[effect] += (value).clamp(1, max - side.effects[effect])
          else
            next if side.effects[effect] == 0
            side.effects[effect] = 0
          end
        else
          next if side.effects[effect] > 0 && value > 0
          next if side.effects[effect] == 0 && value == 0
          side.effects[effect] = value
        end
        battle.pbDisplay(_INTL(msg, team_name)) if msg
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the effects affecting the entire battlefield.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "fieldEffects",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    battler = battle.battlers[idxBattler]
    effects = (params[0].is_a?(Array)) ? params : [params]
    effects.each do |array|
      id, value, msg = *array
      effect = PBEffects.const_get(id)
      next if !effect
      battle.scene.pbForceEndSpeech if msg
      lowercase = (msg && msg[0] == "{" && msg[1] == "1") ? false : true
      battler_name = (battler) ? battler.pbThis(lowercase) : ""
      if $DELUXE_PBEFFECTS[:field][:boolean].include?(id)
        next if battle.field.effects[effect] == value
        battle.field.effects[effect] = value
        battle.pbDisplay(_INTL(msg, battler_name)) if msg
      elsif $DELUXE_PBEFFECTS[:field][:counter].include?(id)
        next if battle.field.effects[effect] > 0 && value > 0
        next if battle.field.effects[effect] == 0 && value == 0
        case id
        when :PayDay
          battle.field.effects[effect] += value
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
        when :TrickRoom
          battle.field.effects[effect] = value
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
          if battle.field.effects[effect] > 0
            battle.allBattlers.each do |b|
              next if !b.hasActiveItem?(:ROOMSERVICE)
              next if !b.pbCanLowerStatStage?(:SPEED)
              battle.pbCommonAnimation("UseItem", b)
              b.pbLowerStatStage(:SPEED, 1, nil)
              b.pbConsumeItem
            end
          end
        when :Gravity
          battle.field.effects[effect] = value
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
          if battle.field.effects[effect] > 0
            battle.allBattlers.each do |b|
              showMessage = false
              if b.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                                    "TwoTurnAttackInvulnerableInSkyParalyzeTarget",
                                    "TwoTurnAttackInvulnerableInSkyTargetCannotAct")
                b.effects[PBEffects::TwoTurnAttack] = nil
                battle.pbClearChoice(b.index) if !b.movedThisRound?
                showMessage = true
              end
              if b.effects[PBEffects::MagnetRise]  >  0 ||
                 b.effects[PBEffects::Telekinesis] >  0 ||
                 b.effects[PBEffects::SkyDrop]     >= 0
                b.effects[PBEffects::MagnetRise]    = 0
                b.effects[PBEffects::Telekinesis]   = 0
                b.effects[PBEffects::SkyDrop]       = -1
                showMessage = true
              end
              battle.pbDisplay(_INTL("{1} couldn't stay airborne because of gravity!", b.pbThis)) if showMessage
            end
          end
        else
          battle.field.effects[effect] = value
          battle.pbDisplay(_INTL(msg, battler_name)) if msg
        end
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the battlefield weather.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeWeather",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    next if [:HarshSun, :HeavyRain, :StrongWinds].include?(battle.field.weather)
    battler = battle.battlers[idxBattler]
    battle.scene.pbForceEndSpeech
    case params
    when :Random
      array = []
      GameData::BattleWeather::DATA.keys.each do |key|
        next if [:None, :HarshSun, :HeavyRain, :StrongWinds, :ShadowSky, battle.field.weather].include?(key)
        array.push(key)
      end
      weather = array.sample
      battle.pbStartWeather(battler, weather, true)
    when :None
      case battle.field.weather
      when :Sun       then battle.pbDisplay(_INTL("The sunlight faded."))
      when :Rain      then battle.pbDisplay(_INTL("The rain stopped."))
      when :Sandstorm then battle.pbDisplay(_INTL("The sandstorm subsided."))
      when :ShadowSky then battle.pbDisplay(_INTL("The shadow sky faded."))
      when :Hail    
        if defined?(Settings::HAIL_WEATHER_TYPE)
          case Settings::HAIL_WEATHER_TYPE
          when 0 then battle.pbDisplay(_INTL("The hail stopped."))
          when 1 then battle.pbDisplay(_INTL("The snow stopped."))
          when 2 then battle.pbDisplay(_INTL("The hailstorm ended."))
          end
        else
          battle.pbDisplay(_INTL("The hail stopped."))
        end
      else
        battle.pbDisplay(_INTL("The weather cleared."))
      end
      battle.pbStartWeather(battler, :None, true)
    else
      params = :Hail if params == :Snow
      if GameData::BattleWeather.exists?(params) && battle.field.weather != params
        battle.pbStartWeather(battler, params, true)
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the battlefield terrain.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeTerrain",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    battler = battle.battlers[idxBattler]
    battle.scene.pbForceEndSpeech
    case params
    when :Random
      array = []
      GameData::BattleTerrain::DATA.keys.each do |key|
        next if [:None, battle.field.terrain].include?(key)
        array.push(key)
      end
      weather = array.sample
      battle.pbStartTerrain(battler, terrain)
    when :None
      case battle.field.terrain
      when :Electric  then battle.pbDisplay(_INTL("The electricity disappeared from the battlefield."))
      when :Grassy    then battle.pbDisplay(_INTL("The grass disappeared from the battlefield."))
      when :Misty     then battle.pbDisplay(_INTL("The mist disappeared from the battlefield."))
      when :Psychic   then battle.pbDisplay(_INTL("The weirdness disappeared from the battlefield."))
      else                 battle.pbDisplay(_INTL("The battlefield returned to normal."))
      end
      battle.pbStartTerrain(battler, :None)
    else
      if GameData::BattleTerrain.exists?(params) && battle.field.terrain != params
        battle.pbStartTerrain(battler, params)
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the battlefield environment.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeEnvironment",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    battler = battle.battlers[idxBattler]
    case params
    when :Random
      array = []
      GameData::Environment::DATA.keys.each do |key|
        next if [:None, battle.environment].include?(key)
        array.push(key)
      end
      battle.environment = array.sample
    else
      if GameData::Environment.exists?(params) && battle.environment != params
        battle.environment = params
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Changes the battle backdrop and bases.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "changeBackdrop",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    if params.is_a?(Array)
      backdrop, base = params[0], params[1]
    else
      backdrop = base = params
    end
    battle.backdrop = backdrop if pbResolveBitmap("Graphics/Battlebacks/#{backdrop}_bg")
    if base && pbResolveBitmap("Graphics/Battlebacks/#{base}_base0")
      battle.backdropBase = base 
      if base.include?("city")          then battle.environment = :None
      elsif base.include?("grass")      then battle.environment = :Grass
      elsif base.include?("water")      then battle.environment = :MovingWater
      elsif base.include?("puddle")     then battle.environment = :Puddle
      elsif base.include?("underwater") then battle.environment = :Underwater
      elsif base.include?("cave")       then battle.environment = :Cave
      elsif base.include?("rocky")      then battle.environment = :Rock
      elsif base.include?("volcano")    then battle.environment = :Volcano
      elsif base.include?("sand")       then battle.environment = :Sand
      elsif base.include?("forest")     then battle.environment = :Forest
      elsif base.include?("snow")       then battle.environment = :Snow
      elsif base.include?("ice")        then battle.environment = :Ice
      elsif base.include?("distortion") then battle.environment = :Graveyard
      elsif base.include?("sky")        then battle.environment = :Sky
      elsif base.include?("space")      then battle.environment = :Space
      end
    end
    battle.scene.pbFlashRefresh
  }
)