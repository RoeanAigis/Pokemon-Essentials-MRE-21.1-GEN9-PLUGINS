#===============================================================================
# "FRLG Battle UI" plugin
# This file contains changes made to Battle_Scene, Scene_Initialize and
# Scene_ChooseCommands
#===============================================================================
class Battle::Scene
  # Text colors
  MESSAGE_BASE_COLOR   = Color.new(248, 248, 248)
  MESSAGE_SHADOW_COLOR = Color.new(104, 88, 112)
  
  def pbShowWindow(windowType)
    @sprites["messageBox"].visible    = (windowType == MESSAGE_BOX)
    @sprites["messageWindow"].visible = (windowType == MESSAGE_BOX)
    @sprites["commandWindow"].visible = (windowType == COMMAND_BOX)
    @sprites["fightWindow"].visible   = (windowType == FIGHT_BOX)
  end

  def pbInitSprites
    @sprites = {}
    # The background image and each side's base graphic
    pbCreateBackdropSprites
    # Create message box graphic
    messageBox = pbAddSprite("messageBox", 0, Graphics.height - 96,
                             "Graphics/UI/Battle/overlay_message", @viewport)
    messageBox.z = 195
    # Create message window (displays the message)
    msgWindow = Window_AdvancedTextPokemon.newWithSize(
      "", 16, Graphics.height - 96 + 2, Graphics.width - 32, 96, @viewport
    )
    msgWindow.z              = 200
    msgWindow.opacity        = 0
    msgWindow.baseColor      = MESSAGE_BASE_COLOR
    msgWindow.shadowColor    = MESSAGE_SHADOW_COLOR
    msgWindow.letterbyletter = true
    @sprites["messageWindow"] = msgWindow
    # Create command window
    @sprites["commandWindow"] = CommandMenu.new(@viewport, 200)
    # Create fight window
    @sprites["fightWindow"] = FightMenu.new(@viewport, 200)
    pbShowWindow(MESSAGE_BOX)
    # The party lineup graphics (bar and balls) for both sides
    2.times do |side|
      partyBar = pbAddSprite("partyBar_#{side}", 0, 0,
                             "Graphics/UI/Battle/overlay_lineup", @viewport)
      partyBar.z       = 120
      partyBar.mirror  = true if side == 0   # Player's lineup bar only
      partyBar.visible = false
      NUM_BALLS.times do |i|
        ball = pbAddSprite("partyBall_#{side}_#{i}", 0, 0, nil, @viewport)
        ball.z       = 121
        ball.visible = false
      end
      # Ability splash bars
      if USE_ABILITY_SPLASH
        @sprites["abilityBar_#{side}"] = AbilitySplashBar.new(side, @viewport)
      end
    end
    # Player's and partner trainer's back sprite
    @battle.player.each_with_index do |p, i|
      pbCreateTrainerBackSprite(i, p.trainer_type, @battle.player.length)
    end
    # Opposing trainer(s) sprites
    if @battle.trainerBattle?
      @battle.opponent.each_with_index do |p, i|
        pbCreateTrainerFrontSprite(i, p.trainer_type, @battle.opponent.length)
      end
    end
    # Data boxes and Pokémon sprites
    @battle.battlers.each_with_index do |b, i|
      next if !b
      @sprites["dataBox_#{i}"] = PokemonDataBox.new(b, @battle.pbSideSize(i), @viewport)
      pbCreatePokemonSprite(i)
    end
    # Wild battle, so set up the Pokémon sprite(s) accordingly
    if @battle.wildBattle?
      @battle.pbParty(1).each_with_index do |pkmn, i|
        index = (i * 2) + 1
        pbChangePokemon(index, pkmn)
        pkmnSprite = @sprites["pokemon_#{index}"]
        pkmnSprite.tone    = Tone.new(-80, -80, -80)
        pkmnSprite.visible = true
      end
    end
  end

  def pbItemMenu(idxBattler, _firstAction)
    # Fade out and hide all sprites
    visibleSprites = pbFadeOutAndHide(@sprites)
    # Set Bag starting positions
    oldLastPocket = $bag.last_viewed_pocket
    oldChoices    = $bag.last_pocket_selections.clone
    if @bagLastPocket
      $bag.last_viewed_pocket     = @bagLastPocket
      $bag.last_pocket_selections = @bagChoices
    else
      $bag.reset_last_selections
    end
    # Start Bag screen
    itemScene = PokemonBag_Scene.new
    itemScene.pbStartScene($bag, true,
                           proc { |item|
                             useType = GameData::Item.get(item).battle_use
                             next useType && useType > 0
                           }, false)
    # Loop while in Bag screen
    wasTargeting = false
    loop do
      # Select an item
      item = itemScene.pbChooseItem
      break if !item
      # Choose a command for the selected item
      item = GameData::Item.get(item)
      itemName = item.name
      useType = item.battle_use
      cmdUse = -1
      commands = []
      commands[cmdUse = commands.length] = _INTL("Use") if useType && useType != 0
      commands[commands.length]          = _INTL("Cancel")
      command = itemScene.pbShowCommands(_INTL("{1} is selected.", itemName), commands)
      next unless cmdUse >= 0 && command == cmdUse   # Use
      # Use types:
      # 0 = not usable in battle
      # 1 = use on Pokémon (lots of items, Blue Flute)
      # 2 = use on Pokémon's move (Ethers)
      # 3 = use on battler (X items, Persim Berry, Red/Yellow Flutes)
      # 4 = use on opposing battler (Poké Balls)
      # 5 = use no target (Poké Doll, Guard Spec., Poké Flute, Launcher items)
      case useType
      when 1, 2, 3   # Use on Pokémon/Pokémon's move/battler
        # Auto-choose the Pokémon/battler whose action is being decided if they
        # are the only available Pokémon/battler to use the item on
        case useType
        when 1   # Use on Pokémon
          if @battle.pbTeamLengthFromBattlerIndex(idxBattler) == 1
            break if yield item.id, useType, @battle.battlers[idxBattler].pokemonIndex, -1, itemScene
          end
        when 3   # Use on battler
          if @battle.pbPlayerBattlerCount == 1
            break if yield item.id, useType, @battle.battlers[idxBattler].pokemonIndex, -1, itemScene
          end
        end
        # Fade out and hide Bag screen
        itemScene.pbFadeOutScene
        # Get player's party
        party    = @battle.pbParty(idxBattler)
        partyPos = @battle.pbPartyOrder(idxBattler)
        partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
        modParty = @battle.pbPlayerDisplayParty(idxBattler)
        # Start party screen
        pkmnScene = PokemonParty_Scene.new
        pkmnScreen = PokemonPartyScreen.new(pkmnScene, modParty)
        pkmnScreen.pbStartScene(_INTL("Use on which Pokémon?"), @battle.pbNumPositions(0, 0))
        idxParty = -1
        # Loop while in party screen
        loop do
          # Select a Pokémon
          pkmnScene.pbSetHelpText(_INTL("Use on which Pokémon?"))
          idxParty = pkmnScreen.pbChoosePokemon
          break if idxParty < 0
          idxPartyRet = -1
          partyPos.each_with_index do |pos, i|
            next if pos != idxParty + partyStart
            idxPartyRet = i
            break
          end
          next if idxPartyRet < 0
          pkmn = party[idxPartyRet]
          next if !pkmn || pkmn.egg?
          idxMove = -1
          if useType == 2   # Use on Pokémon's move
            idxMove = pkmnScreen.pbChooseMove(pkmn, _INTL("Restore which move?"))
            next if idxMove < 0
          end
          break if yield item.id, useType, idxPartyRet, idxMove, pkmnScene
        end
        pkmnScene.pbEndScene
        break if idxParty >= 0
        # Cancelled choosing a Pokémon; show the Bag screen again
        itemScene.pbFadeInScene
      when 4   # Use on opposing battler (Poké Balls)
        idxTarget = -1
        if @battle.pbOpposingBattlerCount(idxBattler) == 1
          @battle.allOtherSideBattlers(idxBattler).each { |b| idxTarget = b.index }
          break if yield item.id, useType, idxTarget, -1, itemScene
        else
          wasTargeting = true
          # Fade out and hide Bag screen
          itemScene.pbFadeOutScene
          # Fade in and show the battle screen, choosing a target
          tempVisibleSprites = visibleSprites.clone
          tempVisibleSprites["commandWindow"] = false
          tempVisibleSprites["fightWindow"]  = true
          idxTarget = pbChooseTarget(idxBattler, GameData::Target.get(:Foe), tempVisibleSprites)
          if idxTarget >= 0
            break if yield item.id, useType, idxTarget, -1, self
          end
          # Target invalid/cancelled choosing a target; show the Bag screen again
          wasTargeting = false
          pbFadeOutAndHide(@sprites)
          itemScene.pbFadeInScene
        end
      when 5   # Use with no target
        break if yield item.id, useType, idxBattler, -1, itemScene
      end
    end
    @bagLastPocket = $bag.last_viewed_pocket
    @bagChoices    = $bag.last_pocket_selections.clone
    $bag.last_viewed_pocket     = oldLastPocket
    $bag.last_pocket_selections = oldChoices
    # Close Bag screen
    itemScene.pbEndScene
    # Fade back into battle screen (if not already showing it)
    pbFadeInAndShow(@sprites, visibleSprites) if !wasTargeting
  end
  
  def pbChooseTarget(idxBattler, target_data, visibleSprites = nil, menuType = 1)
    if menuType == 1
      pbShowWindow(FIGHT_BOX)
      cw = @sprites["fightWindow"]
    else
      pbShowWindow(COMMAND_BOX)
      cw = @sprites["commandWindow"]
    end
    # Create an array of battler names (only valid targets are named)
    texts = pbCreateTargetTexts(idxBattler, target_data)
    # Determine mode based on target_data
    mode = (target_data.num_targets == 1) ? 0 : 1
    index = pbFirstTarget(idxBattler, target_data)
    pbSelectBattler((mode == 0) ? index : texts, 2)   # Select initial battler/data box
    pbFadeInAndShow(@sprites, visibleSprites) if visibleSprites
    ret = -1
    loop do
      oldIndex = index
      pbUpdate(cw)
      # Update selected command
      if mode == 0   # Choosing just one target, can change index
        if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
          inc = (index.even?) ? -2 : 2
          inc *= -1 if Input.trigger?(Input::RIGHT)
          indexLength = @battle.sideSizes[index % 2] * 2
          newIndex = index
          loop do
            newIndex += inc
            break if newIndex < 0 || newIndex >= indexLength
            next if texts[newIndex].nil?
            index = newIndex
            break
          end
        elsif (Input.trigger?(Input::UP) && index.even?) ||
              (Input.trigger?(Input::DOWN) && index.odd?)
          tryIndex = @battle.pbGetOpposingIndicesInOrder(index)
          tryIndex.each do |idxBattlerTry|
            next if texts[idxBattlerTry].nil?
            index = idxBattlerTry
            break
          end
        end
        if index != oldIndex
          pbPlayCursorSE
          pbSelectBattler(index, 2)   # Select the new battler/data box
        end
      end
      if Input.trigger?(Input::USE)   # Confirm
        ret = index
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::BACK)   # Cancel
        ret = -1
        pbPlayCancelSE
        break
      end
    end
    pbSelectBattler(-1)   # Deselect all battlers/data boxes
    return ret
  end
end