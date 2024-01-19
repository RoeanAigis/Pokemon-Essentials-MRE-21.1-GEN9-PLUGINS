#===============================================================================
# Animation utilities.
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Checks if a common animation exists.
  #-----------------------------------------------------------------------------
  def pbCommonAnimationExists?(animName)
    animations = pbLoadBattleAnimations
    animations.each do |a|
      next if !a || a.name != "Common:" + animName
      return true
    end
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Calls a flee animation for wild Pokemon.
  #-----------------------------------------------------------------------------
  def pbBattlerFlee(battler, msg = nil)
    @briefMessage = false
    fleeAnim = Animation::BattlerFlee.new(@sprites, @viewport, battler.index, @battle)
    dataBoxAnim = Animation::DataBoxDisappear.new(@sprites, @viewport, battler.index)
    loop do
      fleeAnim.update
      dataBoxAnim.update
      pbUpdate
      break if fleeAnim.animDone? && dataBoxAnim.animDone?
    end
    fleeAnim.dispose
    dataBoxAnim.dispose
    if msg.is_a?(String)
      @battle.pbDisplayPaused(_INTL("#{msg}", battler.pbThis))
    else
      @battle.pbDisplayPaused(_INTL("{1} fled!", battler.pbThis))
    end
  end
 
  #-----------------------------------------------------------------------------
  # Calls animations to revert a battler from various battle states.
  #-----------------------------------------------------------------------------
  def pbRevertBattlerStart(idxBattler)
    reversionAnim = Animation::RevertBattlerStart.new(@sprites, @viewport, idxBattler, @battle)
    loop do
      reversionAnim.update
      pbUpdate
      break if reversionAnim.animDone?
    end
    reversionAnim.dispose
  end
  
  def pbRevertBattlerEnd
    reversionAnim = Animation::RevertBattlerEnd.new(@sprites, @viewport, @battle)
    loop do
      reversionAnim.update
      pbUpdate
      break if reversionAnim.animDone?
    end
    reversionAnim.dispose
  end
  
  #-----------------------------------------------------------------------------
  # Used for refreshing the entire battle scene with a white flash effect.
  #-----------------------------------------------------------------------------
  def pbFlashRefresh
    pbForceEndSpeech
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate
      tone = lerp(0, 255, 0.7, timer_start, System.uptime)
      @viewport.tone.set(tone, tone, tone, 0)
      break if tone >= 255
    end
    pbRefreshEverything
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate
      break if System.uptime - timer_start >= 0.25
    end
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate
      tone = lerp(255, 0, 0.4, timer_start, System.uptime)
      @viewport.tone.set(tone, tone, tone, 0)
      break if tone <= 0
    end
  end
end

#-------------------------------------------------------------------------------
# Animation code to animate a fleeing battler.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::BattlerFlee < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler, battle)
    @idxBattler = idxBattler
    @battle     = battle
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    batSprite = @sprites["pokemon_#{@idxBattler}"]
    shaSprite = @sprites["shadow_#{@idxBattler}"]
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    shadow  = addSprite(shaSprite, PictureOrigin::CENTER)
    direction = (@battle.battlers[@idxBattler].opposes?(0)) ? batSprite.x : -batSprite.x    
    shadow.setVisible(delay, false)
    battler.setSE(delay, "Battle flee")
    battler.moveOpacity(delay, 8, 0)
    battler.moveDelta(delay, 28, direction, 0)
    battler.setVisible(delay + 28, false)
  end
end

#-------------------------------------------------------------------------------
# Animation code for reverting battlers from various battle states.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::RevertBattlerStart < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler, battle)
    @battle = battle
    @index = idxBattler
    super(sprites, viewport)
  end

  def createProcesses
    darkenBattlefield(@battle, 0, @index, "Anim/Psych Up")
  end
end

class Battle::Scene::Animation::RevertBattlerEnd < Battle::Scene::Animation
  def initialize(sprites, viewport, battle)
    @battle = battle
    super(sprites, viewport)
  end

  def createProcesses
    revertBattlefield(@battle, 4)
  end
end


#===============================================================================
# Calls fleeing animation for roaming Pokemon.
#===============================================================================
class Battle::Battler
  def pbProcessTurn(choice, tryFlee = true)
    return false if fainted?
    if tryFlee && wild? &&
       @battle.rules["alwaysflee"] && @battle.pbCanRun?(@index)
      pbBeginTurn(choice)
      wild_flee(_INTL("{1} fled from battle!", pbThis))
      pbEndTurn(choice)
      return true
    end
    if choice[0] == :Shift
      idxOther = -1
      case @battle.pbSideSize(@index)
      when 2
        idxOther = (@index + 2) % 4
      when 3
        if @index != 2 && @index != 3
          idxOther = (@index.even?) ? 2 : 3
        end
      end
      if idxOther >= 0
        @battle.pbSwapBattlers(@index, idxOther)
        case @battle.pbSideSize(@index)
        when 2
          @battle.pbDisplay(_INTL("{1} moved across!", pbThis))
        when 3
          @battle.pbDisplay(_INTL("{1} moved to the center!", pbThis))
        end
      end
      pbBeginTurn(choice)
      pbCancelMoves
      @lastRoundMoved = @battle.turnCount
      return true
    end
    if choice[0] != :UseMove
      pbBeginTurn(choice)
      pbEndTurn(choice)
      return false
    end
    PBDebug.log("[Use move] #{pbThis} (#{@index}) used #{choice[2].name}")
    PBDebug.logonerr { pbUseMove(choice, choice[2] == @battle.struggle) }
    @battle.pbJudge
    @battle.pbCalculatePriority if Settings::RECALCULATE_TURN_ORDER_AFTER_SPEED_CHANGES
    return true
  end
end


#===============================================================================
# Calls fleeing animation for Safari Pokemon.
#===============================================================================
class SafariBattle
  def pbStartBattle
    begin
      pkmn = @party2[0]
      pbSetSeen(pkmn)
      @scene.pbStartBattle(self)
      pbDisplayPaused(_INTL("Wild {1} appeared!", pkmn.name))
      @scene.pbSafariStart
      weather_data = GameData::BattleWeather.try_get(@weather)
      @scene.pbCommonAnimation(weather_data.animation) if weather_data
      safariBall = GameData::Item.get(:SAFARIBALL).id
      catch_rate = pkmn.species_data.catch_rate
      catchFactor  = (catch_rate * 100) / 1275
      catchFactor  = [[catchFactor, 3].max, 20].min
      escapeFactor = (pbEscapeRate(catch_rate) * 100) / 1275
      escapeFactor = [[escapeFactor, 2].max, 20].min
      loop do
        cmd = @scene.pbSafariCommandMenu(0)
        case cmd
        when 0
          if pbBoxesFull?
            pbDisplay(_INTL("The boxes are full! You can't catch any more Pokémon!"))
            next
          end
          @ballCount -= 1
          @scene.pbRefresh
          rare = (catchFactor * 1275) / 100
          if safariBall
            pbThrowPokeBall(1, safariBall, rare, true)
            if @caughtPokemon.length > 0
              pbRecordAndStoreCaughtPokemon
              @decision = 4
            end
          end
        when 1
          pbDisplayBrief(_INTL("{1} threw some bait at the {2}!", self.pbPlayer.name, pkmn.name))
          @scene.pbThrowBait
          catchFactor  /= 2 if pbRandom(100) < 90
          escapeFactor /= 2
        when 2
          pbDisplayBrief(_INTL("{1} threw a rock at the {2}!", self.pbPlayer.name, pkmn.name))
          @scene.pbThrowRock
          catchFactor  *= 2
          escapeFactor *= 2 if pbRandom(100) < 90
        when 3
          pbSEPlay("Battle flee")
          pbDisplayPaused(_INTL("You got away safely!"))
          @decision = 3
        else
          next
        end
        catchFactor  = [[catchFactor, 3].max, 20].min
        escapeFactor = [[escapeFactor, 2].max, 20].min
        if @decision == 0
          if @ballCount <= 0
            pbSEPlay("Safari Zone end")
            pbDisplay(_INTL("PA: You have no Safari Balls left! Game over!"))
            @decision = 2
          elsif pbRandom(100) < 5 * escapeFactor
            @scene.pbBattlerFlee(@battlers[1])
            @decision = 3
          elsif cmd == 1
            pbDisplay(_INTL("{1} is eating!", pkmn.name))
          elsif cmd == 2
            pbDisplay(_INTL("{1} is angry!", pkmn.name))
          else
            pbDisplay(_INTL("{1} is watching carefully!", pkmn.name))
          end
          weather_data = GameData::BattleWeather.try_get(@weather)
          @scene.pbCommonAnimation(weather_data.animation) if weather_data
        end
        break if @decision > 0
      end
      @scene.pbEndBattle(@decision)
    rescue BattleAbortedException
      @decision = 0
      @scene.pbEndBattle(@decision)
    end
    return @decision
  end
end


#===============================================================================
# Utilities for special battle animations, such as Mega Evolution.
#===============================================================================
class Battle::Scene::Animation
  #-----------------------------------------------------------------------------
  # Used for animation compatibility with animated Pokemon sprites.
  #-----------------------------------------------------------------------------  
  def addPokeSprite(poke, origin = PictureOrigin::TOP_LEFT)
    case poke
    when Pokemon
      s = PokemonSprite.new(@viewport)
      s.setPokemonBitmap(poke)
    when Array
      s = PokemonSprite.new(@viewport)
      s.setSpeciesBitmap(*poke)
    end
    num = @pictureEx.length
    picture = PictureEx.new(s.z)
    picture.x       = s.x
    picture.y       = s.y
    picture.visible = s.visible
    picture.color   = s.color.clone
    picture.tone    = s.tone.clone
    picture.setOrigin(0, origin)
    @pictureEx[num] = picture
    @pictureSprites[num] = s
    @tempSprites.push(s)
    return picture
  end

  #-----------------------------------------------------------------------------
  # Used to darken all sprites in battle for cinematic animations.
  #-----------------------------------------------------------------------------
  def darkenBattlefield(battle, delay = 0, idxBattler = -1, sound = nil)
    tone = Tone.new(-60, -60, -60, 150)
    battleBG = addSprite(@sprites["battle_bg"])
    battleBG.moveTone(delay, 4, tone)
    battle.allBattlers.each do |b|
      battler = addSprite(@sprites["pokemon_#{b.index}"], PictureOrigin::BOTTOM)
      shadow = addSprite(@sprites["shadow_#{b.index}"], PictureOrigin::CENTER)
      box = addSprite(@sprites["dataBox_#{b.index}"])
      if b.index == idxBattler
        battler.setSE(delay, sound) if sound
        battler.moveTone(delay, 4, Tone.new(255, 255, 255, 255))
      else
        battler.moveTone(delay, 4, tone)
      end
      shadow.moveTone(delay, 4, tone)
      box.moveTone(delay, 4, tone)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Reverts the changes made by darkenBattlefield.
  #-----------------------------------------------------------------------------
  def revertBattlefield(battle, delay)
    tone = Tone.new(0, 0, 0, 0)
    battleBG = addSprite(@sprites["battle_bg"])
    battleBG.moveTone(delay, 6, tone)
    battle.allBattlers.each do |b|
      battler = addSprite(@sprites["pokemon_#{b.index}"], PictureOrigin::BOTTOM)
      shadow = addSprite(@sprites["shadow_#{b.index}"], PictureOrigin::CENTER)
      box = addSprite(@sprites["dataBox_#{b.index}"])
      battler.moveOpacity(delay, 6, 255)
      battler.moveTone(delay, 6, tone)
      shadow.moveOpacity(delay, 6, 255)
      shadow.moveTone(delay, 6, tone)
      box.moveTone(delay, 6, tone)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Sets the backdrop.
  #-----------------------------------------------------------------------------
  def dxSetBackdrop(checkfile, default, delay)
    zoom = 1
    if pbResolveBitmap(checkfile)
      file = checkfile
    elsif pbResolveBitmap(default)
      zoom = 1.5
      file = default
    else
      file = "Graphics/Pictures/evolutionbg"
    end
    pictureBG = addNewSprite(0, 0, file)
    pictureBG.setVisible(delay, false)
    spriteBG = @pictureEx.length - 1
    @pictureSprites[spriteBG].z = 999
    pictureBG.setZ(delay, @pictureSprites[spriteBG].z)
    pictureBG.setZoom(delay, 100 * zoom)
    return [pictureBG, spriteBG]
  end
  
  #-----------------------------------------------------------------------------
  # Sets the battle bases. Only sets one if a trainer doesn't appear.
  #-----------------------------------------------------------------------------
  def dxSetBases(checkfile, default, delay, xpos, ypos, offset = false)
    tr_base_offset = 0
    file = (pbResolveBitmap(checkfile)) ? checkfile : default
    pictureBASES = []
    if offset
      base = addNewSprite(0, 0, file)
      base.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      if @opposes
        @pictureSprites[sprite].x = Graphics.width
      else
        @pictureSprites[sprite].x = -@pictureSprites[sprite].bitmap.width
      end
      @pictureSprites[sprite].y = ypos - 33
      @pictureSprites[sprite].z = 999
      tr_base_offset = @pictureSprites[sprite].bitmap.width / 4
      base.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      base.setZ(delay, @pictureSprites[sprite].z)
      pictureBASES.push(base)
    end
    base = addNewSprite(0, 0, file)
    base.setVisible(delay, false)
    sprite = @pictureEx.length - 1
    @pictureSprites[sprite].x = xpos - @pictureSprites[sprite].bitmap.width / 2
    @pictureSprites[sprite].y = ypos
    @pictureSprites[sprite].y += 20 if offset
    @pictureSprites[sprite].z = 999
    base.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
    base.setZ(delay, @pictureSprites[sprite].z)
    pictureBASES.push(base)
    return [pictureBASES, tr_base_offset]
  end
  
  #-----------------------------------------------------------------------------
  # Sets a Pokemon sprite.
  #-----------------------------------------------------------------------------
  def dxSetPokemon(poke, delay, mirror = false, offset = false, opacity = 100, zoom = 100)
    battle_pos = Battle::Scene.pbBattlerPosition(1, 1)
    picturePOKE = addPokeSprite(poke, PictureOrigin::BOTTOM)
    picturePOKE.setVisible(delay, false)
    spritePOKE = @pictureEx.length - 1
    @pictureSprites[spritePOKE].mirror = mirror
    @pictureSprites[spritePOKE].x = battle_pos[0] - 128
    @pictureSprites[spritePOKE].y = battle_pos[1] + 80
    @pictureSprites[spritePOKE].y += 20 if offset
    @pictureSprites[spritePOKE].ox = @pictureSprites[spritePOKE].bitmap.width / 2
    @pictureSprites[spritePOKE].oy = @pictureSprites[spritePOKE].bitmap.height
    @pictureSprites[spritePOKE].z = 999
    case poke
    when Pokemon
      poke.species_data.apply_metrics_to_sprite(@pictureSprites[spritePOKE], 1)
    when Array
      metrics_data = GameData::SpeciesMetrics.get_species_form(poke[0], poke[2])
      metrics_data.apply_metrics_to_sprite(@pictureSprites[spritePOKE], 1)
    end
    picturePOKE.setXY(delay, @pictureSprites[spritePOKE].x, @pictureSprites[spritePOKE].y)
    picturePOKE.setZ(delay, @pictureSprites[spritePOKE].z)
    picturePOKE.setZoom(delay, zoom) if zoom != 100
    picturePOKE.setOpacity(delay, opacity) if opacity != 100
    return [picturePOKE, spritePOKE]
  end
  
  #-----------------------------------------------------------------------------
  # Sets a Pokemon sprite with an outline.
  #-----------------------------------------------------------------------------
  def dxSetPokemonWithOutline(poke, delay, mirror = false, offset = false, color = Color.white)
    battle_pos = Battle::Scene.pbBattlerPosition(1, 1)
    picturePOKE = []
    for i in [ [2, 0],  [-2, 0], [0, 2],  [0, -2], [2, 2],  [-2, -2], [2, -2], [-2, 2], [0, 0] ]
      outline = addPokeSprite(poke, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].mirror = mirror
      @pictureSprites[sprite].x = battle_pos[0] + i[0] - 128
      @pictureSprites[sprite].y = battle_pos[1] + i[1] + 80
      @pictureSprites[sprite].y += 20 if offset
      @pictureSprites[sprite].ox = @pictureSprites[sprite].bitmap.width / 2
      @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
      @pictureSprites[sprite].z = 999
      case poke
      when Pokemon
        poke.species_data.apply_metrics_to_sprite(@pictureSprites[sprite], 1)
      when Array
        set = (poke[8]) ? 2 : poke[7] ? 1 : 0
        metrics_data = GameData::SpeciesMetrics.get_species_form(poke[0], poke[2])
        metrics_data.apply_metrics_to_sprite(@pictureSprites[sprite], 1) #, false, set)
      end
      outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      outline.setZ(delay, @pictureSprites[sprite].z)
      outline.setColor(delay, color) if i != [0, 0]
      picturePOKE.push([outline, sprite])
    end
    return picturePOKE
  end
  
  #-----------------------------------------------------------------------------
  # Sets up a trainer sprite along with an item sprite to be 'used'.
  #-----------------------------------------------------------------------------
  def dxSetTrainerWithItem(trainer, item, delay, mirror = false, color = Color.white)
    pictureTRAINER = addNewSprite(0, 0, trainer)
    pictureTRAINER.setVisible(delay, false)
    spriteTRAINER = @pictureEx.length - 1
    @pictureSprites[spriteTRAINER].y = 105
    if mirror
      @pictureSprites[spriteTRAINER].mirror = true
      @pictureSprites[spriteTRAINER].x = -@pictureSprites[spriteTRAINER].bitmap.width
      trainer_end_x = 0
    else
      @pictureSprites[spriteTRAINER].x = Graphics.width 
      trainer_end_x = Graphics.width - @pictureSprites[spriteTRAINER].bitmap.width
    end
    @pictureSprites[spriteTRAINER].z = 999
    trainer_x, trainer_y = @pictureSprites[spriteTRAINER].x, @pictureSprites[spriteTRAINER].y
    pictureTRAINER.setXY(delay, trainer_x, trainer_y)
    pictureTRAINER.setZ(delay, @pictureSprites[spriteTRAINER].z)
    trData = [pictureTRAINER, trainer_end_x, trainer_y]
    pictureITEM = []
    for i in [ [2, 0],  [-2, 0], [0, 2],  [0, -2], [2, 2],  [-2, -2], [2, -2], [-2, 2], [0, 0] ]
      outline = addNewSprite(0, 0, item, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].x = trainer_end_x + (@pictureSprites[spriteTRAINER].bitmap.width / 2) + i[0]
      @pictureSprites[sprite].y = 97 + i[1]
      @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
      @pictureSprites[sprite].z = 999
      outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      outline.setZ(delay, @pictureSprites[sprite].z)
      outline.setOpacity(delay, 0)
      outline.setColor(delay, color) if i != [0, 0]
      pictureITEM.push([outline, sprite])
    end
    trData.push(pictureITEM)
    return trData
  end
  
  #-----------------------------------------------------------------------------
  # Sets a sprite.
  #-----------------------------------------------------------------------------
  def dxSetSprite(file, delay, xpos, ypos, offset = false, opacity = 100, zoom = 100)
    pictureSPRITE = addNewSprite(0, 0, file, PictureOrigin::CENTER)
    pictureSPRITE.setVisible(delay, false)
    spriteSPRITE = @pictureEx.length - 1
    @pictureSprites[spriteSPRITE].x = xpos
    @pictureSprites[spriteSPRITE].y = ypos
    @pictureSprites[spriteSPRITE].y += 20 if offset
    @pictureSprites[spriteSPRITE].z = 999
    @pictureSprites[spriteSPRITE].oy = @pictureSprites[spriteSPRITE].bitmap.height
    pictureSPRITE.setXY(delay, @pictureSprites[spriteSPRITE].x, @pictureSprites[spriteSPRITE].y)
    pictureSPRITE.setZ(delay, @pictureSprites[spriteSPRITE].z)
    pictureSPRITE.setZoom(delay, zoom) if zoom != 100
    pictureSPRITE.setOpacity(delay, opacity) if opacity != 100
    return [pictureSPRITE, spriteSPRITE]
  end
  
  #-----------------------------------------------------------------------------
  # Sets a sprite with an outline.
  #-----------------------------------------------------------------------------
  def dxSetSpriteWithOutline(file, delay, xpos, ypos, color = Color.white)
    pictureSPRITE = []
    if file && pbResolveBitmap(file)
      for i in [ [2, 0],  [-2, 0], [0, 2],  [0, -2], [2, 2],  [-2, -2], [2, -2], [-2, 2], [0, 0] ]
        outline = addNewSprite(0, 0, file, PictureOrigin::BOTTOM)
        outline.setVisible(delay, false)
        sprite = @pictureEx.length - 1
        @pictureSprites[sprite].x = xpos + i[0]
        @pictureSprites[sprite].y = ypos + i[1]
        @pictureSprites[sprite].z = 999
        @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
        outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
        outline.setZ(delay, @pictureSprites[sprite].z)
        outline.setOpacity(delay, 0)
        outline.setColor(delay, color) if i != [0, 0]
        pictureSPRITE.push([outline, sprite])
      end
    end
    return pictureSPRITE
  end
  
  #-----------------------------------------------------------------------------
  # Sets a sprite to act as a title.
  #-----------------------------------------------------------------------------
  def dxSetTitleWithOutline(file, delay, upper = false, color = Color.white)
    pictureTITLE = []
    if file && pbResolveBitmap(file)
      for i in [ [2, 0],  [-2, 0], [0, 2],  [0, -2], [2, 2],  [-2, -2], [2, -2], [-2, 2], [0, 0] ]
        outline = addNewSprite(0, 0, file, PictureOrigin::CENTER)
        outline.setVisible(delay, false)
        sprite = @pictureEx.length - 1
        @pictureSprites[sprite].x = (Graphics.width - @pictureSprites[sprite].bitmap.width / 2) + i[0]
        if upper
          @pictureSprites[sprite].y = @pictureSprites[sprite].bitmap.height / 2 + i[1]
        else
          @pictureSprites[sprite].y = (Graphics.height - @pictureSprites[sprite].bitmap.height / 2) + i[1]
        end
        @pictureSprites[sprite].z = 999
        outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
        outline.setZ(delay, @pictureSprites[sprite].z)
        outline.setZoom(delay, 300)
        outline.setOpacity(delay, 0)
        outline.setColor(delay, color) if i != [0, 0]
        outline.setTone(delay, Tone.new(255, 255, 255, 255))
        pictureTITLE.push([outline, sprite])
      end
    end
    return pictureTITLE
  end
  
  #-----------------------------------------------------------------------------
  # Sets an overlay.
  #-----------------------------------------------------------------------------
  def dxSetOverlay(file, delay)
    pictureOVERLAY = addNewSprite(0, 0, file)
    pictureOVERLAY.setVisible(delay, false)
    spriteOVERLAY = @pictureEx.length - 1
    @pictureSprites[spriteOVERLAY].z = 999
    pictureOVERLAY.setZ(delay, @pictureSprites[spriteOVERLAY].z)
    pictureOVERLAY.setOpacity(delay, 0)
    return [pictureOVERLAY, spriteOVERLAY]
  end
  
  #-----------------------------------------------------------------------------
  # Sets a set of four particle sprites by repeating an image.
  #-----------------------------------------------------------------------------
  def dxSetParticles(file, delay, xpos, ypos, range, offset = false)
    picturePARTICLES = []
    4.times do |i|
      particle = addNewSprite(0, 0, file, PictureOrigin::CENTER)
      particle.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      case i
      when 0
        @pictureSprites[sprite].x = xpos - range
        @pictureSprites[sprite].y = ypos - range
      when 1
        @pictureSprites[sprite].x = xpos + range
        @pictureSprites[sprite].y = ypos - range
      when 2
        @pictureSprites[sprite].x = xpos - range
        @pictureSprites[sprite].y = ypos + range
      when 3
        @pictureSprites[sprite].x = xpos + range
        @pictureSprites[sprite].y = ypos + range
      end
      @pictureSprites[sprite].y += 20 if offset
      @pictureSprites[sprite].z = 999
      origin_x, origin_y = @pictureSprites[sprite].x, @pictureSprites[sprite].y
      particle.setXY(delay, origin_x, origin_y)
      particle.setZ(delay, @pictureSprites[sprite].z)
      picturePARTICLES.push([particle, origin_x, origin_y])
    end
    return picturePARTICLES
  end
  
  #-----------------------------------------------------------------------------
  # Sets a set of four particle sprites cut up from a single image.
  #-----------------------------------------------------------------------------
  def dxSetParticlesRect(file, delay, width, length, range, offset = false, inwards = false, idxBattler = nil)
    picturePARTICLES = []
    if idxBattler
      batSprite = @sprites["pokemon_#{idxBattler}"]
      pos = Battle::Scene.pbBattlerPosition(idxBattler, batSprite.sideSize)
      xpos = pos[0]
      ypos = pos[1] - batSprite.bitmap.width / 2
      zpos = batSprite.z
    else
      xpos = Graphics.width / 2
      ypos = Graphics.height / 2
      zpos = 999
    end
    4.times do |i|
      particle = addNewSprite(0, 0, file, PictureOrigin::CENTER)
      particle.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      hWidth = (width / 2).round
      hLength = (length / 2).round
      case i
      when 0
        particle.setSrc(delay, 0, 0)
        particle.setSrcSize(delay, hWidth, hLength)
        start_x, start_y = xpos - range, ypos - range
        end_x, end_y = -range, -range
      when 1
        particle.setSrc(delay, hWidth, 0)
        particle.setSrcSize(delay, width, hLength)
        start_x, start_y = xpos + hWidth + range, ypos - range
        end_x, end_y = Graphics.width + range, -range
      when 2
        particle.setSrc(delay, 0, hLength)
        particle.setSrcSize(delay, hWidth, length)
        start_x, start_y = xpos - range, ypos + hLength + range
        end_x, end_y = -range, Graphics.height + range
      when 3
        particle.setSrc(delay, hWidth, hLength)
        particle.setSrcSize(delay, width, length)
        start_x, start_y = xpos + hWidth + range, ypos + hLength + range
        end_x, end_y = Graphics.width + range, Graphics.height + range
      end
      @pictureSprites[sprite].z = zpos
      particle.setZ(delay, @pictureSprites[sprite].z)
      if inwards
        start_y += 20 if offset
        @pictureSprites[sprite].x = start_x
        @pictureSprites[sprite].y = start_y
        particle.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
        picturePARTICLES.push([particle, start_x, start_y])
      else
        @pictureSprites[sprite].x = xpos + (width / 4).round
        @pictureSprites[sprite].y = ypos + (length / 4).round
        @pictureSprites[sprite].y += 20 if offset
        particle.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
        picturePARTICLES.push([particle, end_x, end_y])
      end
    end
    return picturePARTICLES
  end

  #-----------------------------------------------------------------------------
  # Sets the skip button.
  #-----------------------------------------------------------------------------
  def dxSetSkipButton(delay)
    path = Settings::DELUXE_GRAPHICS_PATH + "skip_button"
    pictureBUTTON = addNewSprite(0, Graphics.height, path)
    sprite = @pictureEx.length - 1
    @pictureSprites[sprite].z = 999
    pictureBUTTON.setZ(delay, @pictureSprites[sprite].z)
    return pictureBUTTON
  end
  
  #-----------------------------------------------------------------------------
  # Sets a fade-in/fade-out overlay.
  #-----------------------------------------------------------------------------
  def dxSetFade(delay)
    path = Settings::DELUXE_GRAPHICS_PATH + "fade"
    pictureFADE = addNewSprite(0, 0, path)
    sprite = @pictureEx.length - 1
    @pictureSprites[sprite].z = 999
    pictureFADE.setZ(delay, @pictureSprites[sprite].z)
    pictureFADE.setOpacity(delay, 0)
    return pictureFADE
  end
end

#-------------------------------------------------------------------------------
# Adds alias for changing Pokemon sprite file names. Used by certain animations.
#-------------------------------------------------------------------------------
class PokemonSprite < Sprite
  attr_reader :name

  def name=(*args)
    case args[0]
    when :Symbol
      setSpeciesBitmap(*args)
    when :Pokemon
      setPokemonBitmap(*args)
    end
  end
end

#-------------------------------------------------------------------------------
# Gets the file names for battle background elements. Used by certain animations.
#-------------------------------------------------------------------------------
class Battle
  def pbGetBattlefieldFiles
    case @time
    when 1 then time = "eve"
    when 2 then time = "night"
    end
    backdropFilename = @backdrop
    baseFilename = @backdrop
    baseFilename = sprintf("%s_%s", baseFilename, @backdropBase) if @backdropBase
    if time
      trialName = sprintf("%s_%s", backdropFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_bg"))
        backdropFilename = trialName
      end
      trialName = sprintf("%s_%s", baseFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_base1"))
        baseFilename = trialName
      end
    end
    if !pbResolveBitmap(sprintf("Graphics/Battlebacks/" + baseFilename + "_base1")) && @backdropBase
      baseFilename = @backdropBase
      if time
        trialName = sprintf("%s_%s", baseFilename, time)
        if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_base1"))
          baseFilename = trialName
        end
      end
    end
    return backdropFilename, baseFilename
  end
end

#-------------------------------------------------------------------------------
# Gets colors related to each type. Used by certain animations.
#-------------------------------------------------------------------------------
def pbGetTypeColors(type)
  case type
  when :NORMAL   then outline = [216, 216, 192]; bg = [168, 168, 120]
  when :FIGHTING then outline = [240, 128, 48];  bg = [192, 48, 40]
  when :FLYING   then outline = [200, 192, 248]; bg = [168, 144, 240]
  when :POISON   then outline = [216, 128, 184]; bg = [160, 64, 160]
  when :GROUND   then outline = [248, 248, 120]; bg = [224, 192, 104]
  when :ROCK     then outline = [224, 192, 104]; bg = [184, 160, 56]
  when :BUG      then outline = [216, 224, 48];  bg = [168, 184, 32]
  when :GHOST    then outline = [168, 144, 240]; bg = [112, 88, 152]
  when :STEEL    then outline = [216, 216, 192]; bg = [184, 184, 208]
  when :FIRE     then outline = [248, 208, 48];  bg = [240, 128, 48]
  when :WATER    then outline = [152, 216, 216]; bg = [104, 144, 240]
  when :GRASS    then outline = [192, 248, 96];  bg = [120, 200, 80]
  when :ELECTRIC then outline = [248, 248, 120]; bg = [248, 208, 48]
  when :PSYCHIC  then outline = [248, 192, 176]; bg = [248, 88, 136]
  when :ICE      then outline = [208, 248, 232]; bg = [152, 216, 216]
  when :DRAGON   then outline = [184, 160, 248]; bg = [112, 56, 248]
  when :DARK     then outline = [168, 168, 120]; bg = [112, 88, 72]
  when :FAIRY    then outline = [248, 216, 224]; bg = [240, 168, 176]
  else                outline = [255, 255, 255]; bg = [200, 200, 200]
  end
  return outline, bg
end