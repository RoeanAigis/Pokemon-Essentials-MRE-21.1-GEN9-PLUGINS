#===============================================================================
# Adds a new effect to store the data of the Pokemon the user transformed into.
#===============================================================================
module PBEffects
  TransformPokemon = 200 
end

#===============================================================================
# GameData::Species utilities.
#===============================================================================
module GameData
  class Species
    def has_special_form?
      return true if @mega_stone || @mega_move
      return true if defined?(@gmax_move) && @gmax_move
      ["getPrimalForm", "getUltraForm", "getEternamaxForm", "getTerastalForm"].each do |function|
        return true if MultipleForms.hasFunction?(@species, function)
      end
      return false
    end
  end
end

#===============================================================================
# Battle::Move utilities.
#===============================================================================
class Battle::Move
  attr_accessor :short_name
  
  #-----------------------------------------------------------------------------
  # Initializes shortened move names for moves with very long names.
  #-----------------------------------------------------------------------------
  alias dx_initialize initialize
  def initialize(battle, move)
    dx_initialize(battle, move)
    @short_name = (Settings::SHORTEN_MOVES && @name.length > 16) ? @name[0..12] + "..." : @name
  end
  
  #-----------------------------------------------------------------------------
  # Utility used for checking for Z-Moves/Dynamax moves, if any exist.
  #-----------------------------------------------------------------------------
  def powerMove?
    return true if defined?(zMove?) && self.zMove?
    return true if defined?(dynamaxMove?) && self.dynamaxMove?
    return false
  end
end

#===============================================================================
# Battle::Battler utilities.
#===============================================================================
class Battle::Battler
  attr_accessor :baseMoves
  attr_accessor :powerMoveIndex
  attr_accessor :hpThreshold, :damageThreshold
  attr_accessor :stopBoostedHPScaling
  
  #-----------------------------------------------------------------------------
  # Initializes properties used by various plugin features.
  #-----------------------------------------------------------------------------
  alias dx_pbInitEffects pbInitEffects  
  def pbInitEffects(batonPass)
    @baseMoves            = []
    @powerMoveIndex       = -1
    @hpThreshold          = 0
    @damageThreshold      = 0
    @stopBoostedHPScaling = false
    dx_pbInitEffects(batonPass)
    @effects[PBEffects::TransformPokemon] = nil
  end
  
  #-----------------------------------------------------------------------------
  # Sets the index of the selected move if selected move is a Z-Move/Dynamax move.
  #-----------------------------------------------------------------------------
  alias dx_pbUseMove pbUseMove
  def pbUseMove(choice, specialUsage = false)
    @powerMoveIndex = (choice[2].powerMove?) ? choice[1] : -1
    dx_pbUseMove(choice, specialUsage)
  end
  
  #-----------------------------------------------------------------------------
  # Utility for resetting a battler's moves back to its original moveset.
  #-----------------------------------------------------------------------------
  def display_base_moves
    return if @baseMoves.empty?
    for i in 0...@moves.length
      next if !@baseMoves[i]
      if @baseMoves[i].is_a?(Battle::Move)
        @moves[i] = @baseMoves[i]
      else
        @moves[i] = Battle::Move.from_pokemon_move(@battle, @baseMoves[i])
      end
    end
    @baseMoves.clear
  end
  
  #-----------------------------------------------------------------------------
  # Utilities for checking compatibility with special actions.
  #-----------------------------------------------------------------------------
  def getActiveState
    return :mega      if mega?
    return :primal    if primal?
    return :ultra     if ultra?
    return :dynamax   if dynamax?
    return :style     if style?
    return :tera      if tera?
    return :celestial if celestial?
    return nil
  end
  
  def hasEligibleAction?(*args)
    args.each do |arg|
      case arg
      when :mega    then return true if hasMega?
      when :primal  then return true if hasPrimal?
      when :zmove   then return true if hasZMove?
      when :ultra   then return true if hasUltra?
      when :dynamax then return true if hasDynamax?
      when :style   then return true if hasStyle?
      when :tera    then return true if hasTera?
      when :zodiac  then return true if hasZodiacPower?
      end
    end
    return false	
  end

  #-----------------------------------------------------------------------------
  # Utility for refreshing a battler's form.
  #-----------------------------------------------------------------------------
  def form_update(fullupdate = false)
    if self.form != @pokemon.form
      self.form = @pokemon.form
      fullupdate = true
    end
    pbUpdate(fullupdate)
    pkmn = @effects[PBEffects::TransformPokemon] || displayPokemon
    @battle.scene.pbChangePokemon(self, pkmn)
    @battle.scene.pbRefreshOne(@index)
  end
  
  #-----------------------------------------------------------------------------
  # Identical to pbChangeForm except it ignores learning new moves for certain species.
  #-----------------------------------------------------------------------------
  def pbSimpleFormChange(newForm, msg)
    return if fainted? || @effects[PBEffects::Transform] || @form == newForm
    oldForm = @form
    oldDmg = @totalhp - @hp
    @form = newForm
    @pokemon.form_simple = newForm if @pokemon
    pbUpdate(true)
    @hp = @totalhp - oldDmg
    @effects[PBEffects::WeightChange] = 0 if Settings::MECHANICS_GENERATION >= 6
    @battle.scene.pbChangePokemon(self, @pokemon)
    @battle.scene.pbRefreshOne(@index)
    @battle.pbDisplay(msg) if msg && msg != ""
    PBDebug.log("[Form changed] #{pbThis} changed from form #{oldForm} to form #{newForm}")
    @battle.pbSetSeen(self)
  end
  
  #-----------------------------------------------------------------------------
  # Checks for form changes upon changing the battler's held item.
  #-----------------------------------------------------------------------------
  def pbCheckFormOnHeldItemChange
    return if fainted? || @effects[PBEffects::Transform]
    #---------------------------------------------------------------------------
    # Dialga - holding Adamant Crystal
    if isSpecies?(:DIALGA)
      newForm = 0
      newForm = 1 if self.item_id == :ADAMANTCRYSTAL
      pbSimpleFormChange(newForm, _INTL("{1} transformed!", pbThis))
    end
    #---------------------------------------------------------------------------
    # Palkia - holding Lustrous Globe
    if isSpecies?(:PALKIA)
      newForm = 0
      newForm = 1 if self.item_id == :LUSTROUSGLOBE
      pbSimpleFormChange(newForm, _INTL("{1} transformed!", pbThis))
    end
    #---------------------------------------------------------------------------
    # Giratina - holding Griseous Orb/Core
    if isSpecies?(:GIRATINA)
      return if $game_map && GameData::MapMetadata.get($game_map.map_id)&.has_flag?("DistortionWorld")
      newForm = 0
      newForm = 1 if Settings::MECHANICS_GENERATION <= 8 && self.item_id == :GRISEOUSORB
      newForm = 1 if Settings::MECHANICS_GENERATION >= 9 && self.item_id == :GRISEOUSCORE
      pbSimpleFormChange(newForm, _INTL("{1} transformed!", pbThis))
    end
    #---------------------------------------------------------------------------
    # Arceus - holding a Plate with Multi-Type
    if isSpecies?(:ARCEUS) && self.ability == :MULTITYPE
      newForm = 0
      type = GameData::Type.get(:NORMAL)
      if self.item_id
        typeArray = {
          1  => [:FIGHTING, [:FISTPLATE,   :FIGHTINIUMZ]],
          2  => [:FLYING,   [:SKYPLATE,    :FLYINIUMZ]],
          3  => [:POISON,   [:TOXICPLATE,  :POISONIUMZ]],
          4  => [:GROUND,   [:EARTHPLATE,  :GROUNDIUMZ]],
          5  => [:ROCK,     [:STONEPLATE,  :ROCKIUMZ]],
          6  => [:BUG,      [:INSECTPLATE, :BUGINIUMZ]],
          7  => [:GHOST,    [:SPOOKYPLATE, :GHOSTIUMZ]],
          8  => [:STEEL,    [:IRONPLATE,   :STEELIUMZ]],
          10 => [:FIRE,     [:FLAMEPLATE,  :FIRIUMZ]],
          11 => [:WATER,    [:SPLASHPLATE, :WATERIUMZ]],
          12 => [:GRASS,    [:MEADOWPLATE, :GRASSIUMZ]],
          13 => [:ELECTRIC, [:ZAPPLATE,    :ELECTRIUMZ]],
          14 => [:PSYCHIC,  [:MINDPLATE,   :PSYCHIUMZ]],
          15 => [:ICE,      [:ICICLEPLATE, :ICIUMZ]],
          16 => [:DRAGON,   [:DRACOPLATE,  :DRAGONIUMZ]],
          17 => [:DARK,     [:DREADPLATE,  :DARKINIUMZ]],
          18 => [:FAIRY,    [:PIXIEPLATE,  :FAIRIUMZ]]
        }
        typeArray.each do |form, data|
          next if !data.last.include?(self.item_id)
          type = GameData::Type.get(data.first)
          newForm = form
        end
      end
      pbSimpleFormChange(newForm, _INTL("{1} transformed into the {2}-type!", pbThis, type.name))
    end
    #---------------------------------------------------------------------------
    # Genesect - holding a Drive
    if isSpecies?(:GENESECT)
      newForm = 0
      drives = [:SHOCKDRIVE, :BURNDRIVE, :CHILLDRIVE, :DOUSEDRIVE]
      drives.each_with_index do |drive, i|
        newForm = i + 1 if self.item_id == drive
      end
      pbSimpleFormChange(newForm, nil)
    end
    #---------------------------------------------------------------------------
    # Silvally - holding a Memory with RKS System
    if isSpecies?(:SILVALLY) && self.ability == :RKSSYSTEM
      newForm = 0
      type = GameData::Type.get(:NORMAL)
      if self.item
        typeArray = {
          1  => [:FIGHTING, [:FIGHTINGMEMORY]],
          2  => [:FLYING,   [:FLYINGMEMORY]],
          3  => [:POISON,   [:POISONMEMORY]],
          4  => [:GROUND,   [:GROUNDMEMORY]],
          5  => [:ROCK,     [:ROCKMEMORY]],
          6  => [:BUG,      [:BUGMEMORY]],
          7  => [:GHOST,    [:GHOSTMEMORY]],
          8  => [:STEEL,    [:STEELMEMORY]],
          10 => [:FIRE,     [:FIREMEMORY]],
          11 => [:WATER,    [:WATERMEMORY]],
          12 => [:GRASS,    [:GRASSMEMORY]],
          13 => [:ELECTRIC, [:ELECTRICMEMORY]],
          14 => [:PSYCHIC,  [:PSYCHICMEMORY]],
          15 => [:ICE,      [:ICEMEMORY]],
          16 => [:DRAGON,   [:DRAGONMEMORY]],
          17 => [:DARK,     [:DARKMEMORY]],
          18 => [:FAIRY,    [:FAIRYMEMORY]]
        }
        typeArray.each do |form, data|
          next if !data.last.include?(self.item_id)
          type = GameData::Type.get(data.first)
          newForm = form
        end
      end
      pbSimpleFormChange(newForm, _INTL("{1} transformed into the {2}-type!", pbThis, type.name))
    end
    #---------------------------------------------------------------------------
    # Zacian - holding Rusted Sword
    if isSpecies?(:ZACIAN)
      newForm = 0
      newForm = 1 if self.item_id == :RUSTEDSWORD
      moves = [:IRONHEAD, :BEHEMOTHBLADE]
      @moves.each_with_index do |m, i|
        next if m.id != moves[self.form]
        move = Pokemon::Move.new(moves.reverse[self.form])
        move.pp = m.pp
        @moves[i] = Battle::Move.from_pokemon_move(@battle, move)
      end
      pbSimpleFormChange(newForm, _INTL("{1} transformed!", pbThis))
    end
    #---------------------------------------------------------------------------
    # Zamazenta - holding Rusted Shield
    if isSpecies?(:ZAMAZENTA)
      newForm = 0
      newForm = 1 if self.item_id == :RUSTEDSHIELD
      moves = [:IRONHEAD, :BEHEMOTHBASH]
      @moves.each_with_index do |m, i|
        next if m.id != moves[self.form]
        move = Pokemon::Move.new(moves.reverse[self.form])
        move.pp = m.pp
        @moves[i] = Battle::Move.from_pokemon_move(@battle, move)
      end
      pbSimpleFormChange(newForm, _INTL("{1} transformed!", pbThis))
    end
    #---------------------------------------------------------------------------
    # Ogerpon - holding masks
    if isSpecies?(:OGERPON)
      newForm = (self.tera?) ? 8 : 4
      maskName = GameData::Item.get(:TEALMASK).name
      masks = [:TEALMASK, :WELLSPRINGMASK, :HEARTHFLAMEMASK, :CORNERSTONEMASK]
      masks.each_with_index do |mask, i|
        next if self.item_id != mask
        newForm += i
        maskName = GameData::Item.get(mask).name
        break
      end
      pbSimpleFormChange(newForm, _INTL("{1} put on its {2}!", pbThis, maskName))
    end
  end
end

#===============================================================================
# Battle::AI utilities.
#===============================================================================
class Battle::AI
  def pbAbleToTarget?(user, target, target_data)
    return false if user.index == target.index
    return false if target_data.num_targets == 0
    return false if !@battle.pbMoveCanTarget?(user.index, target.index, target_data)
    if target_data.targets_foe
      return true if user.wild? && !user.opposes?(target) && user.isRivalSpecies?(target)
      return false if !user.opposes?(target)
    end
    return true
  end
  
  def pbShouldInvertScore?(target_data)
    if target_data.targets_foe && !@target.opposes?(@user) && @target.index != @user.index
      return false if @user.battler.wild? && @user.battler.isRivalSpecies?(@target.battler)
      return true
    end
    return false
  end
  
  def pbGetMoveScoreAgainstTarget
    if @trainer.has_skill_flag?("PredictMoveFailure") && pbPredictMoveFailureAgainstTarget
      PBDebug.log("     move will not affect #{@target.name}")
      return -1
    end
    score = MOVE_BASE_SCORE
    if @trainer.has_skill_flag?("ScoreMoves")
      old_score = score
      score = Battle::AI::Handlers.apply_move_effect_against_target_score(@move.function_code,
         MOVE_BASE_SCORE, @move, @user, @target, self, @battle)
      PBDebug.log_score_change(score - old_score, "function code modifier (against target)")
      score = Battle::AI::Handlers.apply_general_move_against_target_score_modifiers(
        score, @move, @user, @target, self, @battle)
    end
    target_data = @move.pbTarget(@user.battler)
    if pbShouldInvertScore?(target_data)
      if score == MOVE_USELESS_SCORE
        PBDebug.log("     move is useless against #{@target.name}")
        return -1
      end
      old_score = score
      score = ((1.85 * MOVE_BASE_SCORE) - score).to_i
      PBDebug.log_score_change(score - old_score, "score inverted (move targets ally but can target foe)")
    end
    return score
  end
end

#===============================================================================
# Battle::AI::AIBattler utilities.
#===============================================================================
class Battle::AI::AIBattler
  #-----------------------------------------------------------------------------
  # Utilities for running checks on opposing battlers.
  #-----------------------------------------------------------------------------
  def opponent_side_has_move_flags?(*flags)
    @ai.each_foe_battler(@side) do |b, i|
      flags.each do |flag|
        return true if b.check_for_move { |m| m.flags.include?(flag) }
      end
    end
    return false
  end
  
  def opponent_side_has_function?(*functions)
    @ai.each_foe_battler(@side) do |b, i|
      return true if b.has_move_with_function?(*functions)
    end
    return false
  end
  
  def opponent_side_has_ability?(ability, near = false)
    if ability.is_a?(Array)
      ability.each do |abil|
        bearer = @ai.battle.pbCheckOpposingAbility(abil, @index, near)
        return true if !bearer.nil?
      end
    else
      bearer = @ai.battle.pbCheckOpposingAbility(ability, @index, near)
      return true if !bearer.nil?
    end
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Utility for checking if a battler is at risk of obtaining a status effect.
  #-----------------------------------------------------------------------------
  def risks_getting_status?(status, *functions)
    return false if self.status != :NONE
    types = self.pbTypes(true)
    return false if status == :BURN && types.include?(:FIRE)
    return false if status == :POISON && (types.include?(:POISON) || types.include?(:STEEL))
    return false if status == :PARALYSIS && Settings::MORE_TYPE_EFFECTS && types.include?(:ELECTRIC)
    return false if [:FROZEN, :FROSTBITE].include?(status) && types.include?(:ICE)
    return false if !opponent_side_has_function?(*functions)
    return false if self.effects[PBEffects::Substitute] > 0
    return false if @ai.battle.sides[@side].effects[PBEffects::Safeguard] > 0
    return false if @ai.battle.field.terrain == :Misty && @battler.affectedByTerrain?
    return false if [:FROZEN, :FROSTBITE].include?(status) && 
                    [:Sun, :HarshSun].include?(@battler.effectiveWeather)
    return false if wants_status_problem?(status)
    return false if Battle::AbilityEffects.triggerStatusImmunityNonIgnorable(self.ability_id, @battler, status)
    if ability_active? && !@ai.battle.moldBreaker
      return false if Battle::AbilityEffects.triggerStatusImmunity(self.ability_id, @battler, status)
      @ai.each_ally(@index) do |b, i|
        next if !b.ability_active?
        return false if Battle::AbilityEffects.triggerStatusImmunityFromAlly(b.ability_id, b.battler, status)
      end
    end
    return true
  end
end