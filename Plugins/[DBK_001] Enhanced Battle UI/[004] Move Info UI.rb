#===============================================================================
# Move Info UI
#===============================================================================
class Battle::Scene  
  #-----------------------------------------------------------------------------
  # Toggles the visibility of the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbToggleMoveInfo(*args)
    return if pbInSafari?
    @moveUIToggle = !@moveUIToggle
    (@moveUIToggle) ? pbSEPlay("GUI party switch") : pbPlayCloseMenuSE
    @sprites["moveinfo"].visible = @moveUIToggle
    pbUpdateTargetIcons
    pbUpdateMoveInfoWindow(*args)
  end

  #-----------------------------------------------------------------------------
  # Updates icon sprites to be used for the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbUpdateTargetIcons
    idx = 0
    @battle.allBattlers.each do |b|
      if b && !b.fainted? && b.index.odd?
        @sprites["info_icon#{b.index}"].pokemon = b.displayPokemon
        @sprites["info_icon#{b.index}"].visible = @moveUIToggle
        @sprites["info_icon#{b.index}"].x = Graphics.width - 32 - (idx * 64)
        @sprites["info_icon#{b.index}"].y = 68
        if b.dynamax?
          @sprites["info_icon#{b.index}"].set_dynamax_icon_pattern
        elsif b.tera?
          @sprites["info_icon#{b.index}"].set_tera_icon_pattern
        else
          @sprites["info_icon#{b.index}"].zoom_x = 1
          @sprites["info_icon#{b.index}"].zoom_y = 1
          @sprites["info_icon#{b.index}"].pattern = nil
        end
        idx += 1
      else
        @sprites["info_icon#{b.index}"].visible = false
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Draws the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbUpdateMoveInfoWindow(battler, specialAction, cw)
    pbHideBattleInfo
    @moveUIOverlay.clear
    return if !@moveUIToggle
    xpos = 0
    ypos = 94
    move = battler.moves[cw.index]
    terastal = battler.tera? || (specialAction == :tera && cw.teraType > 0)
    #---------------------------------------------------------------------------
    # Gets move type and category (for display purposes).
    case move.function_code
    when "CategoryDependsOnHigherDamageTera",
         "TerapagosCategoryDependsOnHigherDamage"
      if terastal
        type = battler.tera_type
        realAtk, realSpAtk = battler.getOffensiveStats
        category = (realAtk > realSpAtk) ? 0 : 1
      else
        type = move.type
        category = move.calcCategory
      end
    when "CategoryDependsOnHigherDamagePoisonTarget", 
         "CategoryDependsOnHigherDamageIgnoreTargetAbility"
      type = move.pbCalcType(battler)
      move.pbOnStartUse(battler, [battler.pbDirectOpposing])
      category = move.calcCategory
    else
      type = move.pbCalcType(battler)
      category = move.category
    end
    #---------------------------------------------------------------------------
    # Draws images.
    typenumber = GameData::Type.get(type).icon_position
    imagePos = [
      [@path + "move_bg", xpos, ypos],
      ["Graphics/UI/types",    xpos + 272, ypos + 4, 0, typenumber * 28, 64, 28],
      ["Graphics/UI/category", xpos + 336, ypos + 4, 0, category * 28, 64, 28]
    ]
    pbDrawMoveFlagIcons(xpos, ypos, move, imagePos)
    pbDrawTypeEffectiveness(xpos, ypos, move, type, imagePos)
    pbDrawImagePositions(@moveUIOverlay, imagePos)
    #---------------------------------------------------------------------------
    # Move damage calculations (for display purposes).
    powBase   = accBase   = effBase   = BASE_LIGHT
    powShadow = accShadow = effShadow = SHADOW_LIGHT 
    basePower = calcPower = finalPower = move.power
    hidePower = false
    if terastal
      if battler.typeTeraBoosted?(type)
        bonus = (type == :STELLAR) ? 1.2 : 1.5
        stab = (battler.types.include?(type)) ? 2 : bonus
      else
        stab = (battler.types.include?(type)) ? 1.5 : 1
      end
    else
      stab = (battler.pbHasType?(type)) ? 1.5 : 1
    end
    case move.function_code
    when "ThrowUserItemAtTarget"                     # Fling
      hidePower = true if !battler.item
    when "TypeAndPowerDependOnUserBerry"             # Natural Gift
      hidePower = true if !battler.item || !battler.item.is_berry?
    when "PursueSwitchingFoe",                       # Pursuit
         "RemoveTargetItem",                         # Knock Off
         "HitOncePerUserTeamMember",                 # Beat Up
         "DoublePowerIfTargetActed",                 # Payback
         "DoublePowerIfTargetNotActed",              # Bolt Beak, Fishious Rend
         "PowerHigherWithTargetHP",                  # Crush Grip, Wring Out
         "PowerHigherWithTargetHP100PowerRange",     # Hard Press
         "PowerHigherWithTargetWeight",              # Low Kick, Grass Knot
         "PowerHigherWithUserFasterThanTarget",      # Electro Ball
         "PowerHigherWithTargetFasterThanUser",      # Gyro Ball
         "FixedDamageUserLevelRandom",               # Psywave
         "RandomlyDamageOrHealTarget",               # Present
         "RandomlyDealsDoubleDamage",                # Fickle Beam
         "RandomPowerDoublePowerIfTargetUnderground" # Magnitude
      hidePower = true if calcPower == 1
    end
    if move.damagingMove?
      if !hidePower
        calcPower = move.pbBaseDamage(move.power, battler, battler.pbDirectOpposing)
        calcPower = move.pbModifyDamage(calcPower, battler, battler.pbDirectOpposing)
      end
      powerDiff = (move.function_code == "PowerHigherWithUserHP") ? calcPower - basePower : basePower - calcPower
      calcPower *= stab
      finalPower = (calcPower >= powerDiff) ? calcPower : basePower * stab
      calcPower = finalPower if finalPower > basePower
      if finalPower > 1
        if calcPower > basePower
          powBase, powShadow = BASE_RAISED, SHADOW_RAISED
        elsif finalPower < (basePower * stab).floor
          powBase, powShadow = BASE_LOWERED, SHADOW_LOWERED
        end
      end
    end
    #---------------------------------------------------------------------------
    # Draws text.
    textPos = []
    power = (finalPower == 0) ? "---" : (hidePower) ? "???" : finalPower.floor.to_s
    accuracy = (move.accuracy == 0) ? "---" : move.accuracy.to_s
    case move.function_code
    when "ParalyzeFlinchTarget", "BurnFlinchTarget", "FreezeFlinchTarget"
      chance = 10
    when "LowerTargetDefense1FlinchTarget"
      chance = 50
    else
      chance = move.addlEffect
    end
    effect_rate = (chance == 0) ? "---" : chance.to_s + "%"
    textPos.push(
      [move.name,       xpos + 10,            ypos + 8,  :left,   BASE_LIGHT, SHADOW_LIGHT],
      [_INTL("Pow:"),   Graphics.width - 86,  ypos + 10, :center, BASE_LIGHT, SHADOW_LIGHT],
      [_INTL("Acc:"),   Graphics.width - 86,  ypos + 40, :center, BASE_LIGHT, SHADOW_LIGHT],
      [_INTL("Effct:"), xpos + 286,           ypos + 40, :left,   BASE_LIGHT, SHADOW_LIGHT],
      [power,           Graphics.width - 34,  ypos + 10, :center, powBase,    powShadow],
      [accuracy,        Graphics.width - 34,  ypos + 40, :center, accBase,    accShadow],
      [effect_rate,     Graphics.width - 146, ypos + 40, :center, effBase,    effShadow]
    )
    pbAddPluginText(xpos, ypos, move, battler, specialAction, cw, textPos)
    pbDrawTextPositions(@moveUIOverlay, textPos)
    drawTextEx(@moveUIOverlay, xpos + 10, ypos + 70, Graphics.width - 10, 2, 
      GameData::Move.get(move.id).description, BASE_LIGHT, SHADOW_LIGHT)
  end
  
  #-----------------------------------------------------------------------------
  # Draws the move flag icons for each move in the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbDrawMoveFlagIcons(xpos, ypos, move, imagePos)
    flagX = xpos + 6
    flagY = ypos + 32
    icons = 0
    if defined?(move.zMove?) && move.zMove?
      imagePos.push([@path + "move_flags", flagX + (icons * 26), flagY, 0 * 26, 0, 26, 28])
	  icons += 1
    elsif defined?(move.dynamaxMove?) && move.dynamaxMove?
      imagePos.push([@path + "move_flags", flagX + (icons * 26), flagY, 1 * 26, 0, 26, 28])
	  icons += 1
    end
    if GameData::Target.get(move.target).targets_foe
	  if !move.flags.include?("CanProtect")
        imagePos.push([@path + "move_flags", flagX + (icons * 26), flagY, 2 * 26, 0, 26, 28])
		icons += 1
	  end
	  if !move.flags.include?("CanMirrorMove")
		imagePos.push([@path + "move_flags", flagX + (icons * 26), flagY, 3 * 26, 0, 26, 28])
		icons += 1
	  end
    end
    move.flags.each do |flag|
      idx = -1
      case flag
      when "Contact"          then idx = 4
      when "TramplesMinimize" then idx = 5
      when "ElectrocuteUser"  then idx = 7
      when "ThawsUser"        then idx = 8
      when "Sound"            then idx = 9
      when "Punching"         then idx = 10
      when "Biting"           then idx = 11
      when "Bomb"             then idx = 12
      when "Pulse"            then idx = 13
      when "Powder"           then idx = 14
      when "Dance"            then idx = 15
      when "Slicing"          then idx = 16
      when "Wind"             then idx = 17
      end
      idx = 6 if flag.include?("HighCriticalHitRate")
      next if idx < 0
      imagePos.push([@path + "move_flags", flagX + (icons * 26), flagY, idx * 26, 0, 26, 28])
	  icons += 1
    end
  end
  
  #-----------------------------------------------------------------------------
  # Draws the type effectiveness display for each opponent in the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbDrawTypeEffectiveness(xpos, ypos, move, type, imagePos)
    idx = 0
    @battle.allBattlers.each do |b|
      next if b.index.even?
      if b && !b.fainted? && move.category < 2
        poke = b.displayPokemon
        unknown_species = $player.pokedex.battled_count(poke.species) == 0 && !$player.pokedex.owned?(poke.species)
        unknown_species = false if Settings::SHOW_TYPE_EFFECTIVENESS_FOR_NEW_SPECIES
        unknown_species = true if b.celestial?
        value = Effectiveness.calculate(type, *b.pbTypes(true))
        if unknown_species                             then effct = 0
        elsif Effectiveness.ineffective?(value)        then effct = 1
        elsif Effectiveness.not_very_effective?(value) then effct = 2
        elsif Effectiveness.super_effective?(value)    then effct = 3
        else effct = 4
        end
        imagePos.push([@path + "move_effectiveness", Graphics.width - 64 - (idx * 64), ypos - 76, effct * 64, 0, 64, 76])
        @sprites["info_icon#{b.index}"].visible = true
      else
        @sprites["info_icon#{b.index}"].visible = false
      end
      idx += 1
    end
  end
  
  #-----------------------------------------------------------------------------
  # Draws additional plugin-specific text to be displayed in the Move Info UI.
  #-----------------------------------------------------------------------------
  def pbAddPluginText(xpos, ypos, move, battler, specialAction, cw, textPos)
    case specialAction
    #---------------------------------------------------------------------------
    # Sets up additional text for Z-Moves.
    #---------------------------------------------------------------------------
    when :zmove
      if cw.mode == 2
        if move.zMove? && move.has_zpower?
          effect, stage = move.get_zpower_effect
          case effect
          when "HealUser"    then text = _INTL("Fully restores the user's HP.")
          when "HealSwitch"  then text = _INTL("Fully restores an incoming Pokémon's HP.")
          when "CriticalHit" then text = _INTL("Raises the user's critical hit rate.")
          when "ResetStats"  then text = _INTL("Resets the user's lowered stat stages.")
          when "FollowMe"    then text = _INTL("The user becomes the center of attention.")
          else
            if stage
              stat = (effect == "AllStats") ? "stats" : GameData::Stat.get(effect.to_sym).name
              case stage
              when "3" then text = _INTL("Drastically raises the user's {1}.", stat)
              when "2" then text = _INTL("Sharply raises the user's {1}.", stat)
              else          text = _INTL("Raises the user's {1}.", stat)
              end
            end
          end
          textPos.push([_INTL("Z-Power: #{text}"), xpos + 10, ypos + 128, :left, BASE_RAISED, SHADOW_RAISED]) if text
        end
      end
    #---------------------------------------------------------------------------
    # Sets up additional text for moves affected by Terastallization.
    #---------------------------------------------------------------------------
    when :tera
      teramove = ["CategoryDependsOnHigherDamageTera",
                  "TerapagosCategoryDependsOnHigherDamage"].include?(move.function_code)
      if (battler.tera? || cw.teraType > 0) && (teramove || battler.tera_type == move.pbCalcType(battler))
        textPos.push([_INTL("Tera Type: Move altered by Terastallization."), xpos + 10, ypos + 128, :left, BASE_RAISED, SHADOW_RAISED])
      end
    end
  end
end