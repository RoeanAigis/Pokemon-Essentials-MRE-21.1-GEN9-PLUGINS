#===============================================================================
# "FRLG Battle UI" plugin
# This file contains changes made to Battle_Scene_Menus
# (changes made to command and fight menus).
#===============================================================================
class Battle::Scene::MenuBase
  TEXT_BASE_COLOR   = Battle::Scene::MESSAGE_BASE_COLOR
  TEXT_SHADOW_COLOR = Battle::Scene::MESSAGE_SHADOW_COLOR
end

#===============================================================================
# Command menu (Fight/Pokémon/Bag/Run)
#===============================================================================
class Battle::Scene::CommandMenu < Battle::Scene::MenuBase
  # Just displays text, the command window and the graphic
  # Graphics/UI/Battle/overlay_message.png.

  # Lists of which button graphics to use in different situations/types of battle.
  MODES = [
    [0, 2, 1, 3],   # 0 = Regular battle
    [0, 2, 1, 9],   # 1 = Regular battle with "Cancel" instead of "Run"
    [0, 2, 1, 4],   # 2 = Regular battle with "Call" instead of "Run"
    [5, 7, 6, 3],   # 3 = Safari Zone
    [0, 8, 1, 3]    # 4 = Bug-Catching Contest
  ]

  def initialize(viewport, z)
    super(viewport)
    self.x = 0
    self.y = Graphics.height - 96
    # Create message box (shows "What will X do?")
    @msgBox = Window_UnformattedTextPokemon.newWithSize(
      "", self.x + 16, self.y + 2, 220, Graphics.height - self.y, viewport
    )
    @msgBox.baseColor   = TEXT_BASE_COLOR
    @msgBox.shadowColor = TEXT_SHADOW_COLOR
    @msgBox.windowskin  = nil
    addSprite("msgBox", @msgBox)
    # Create background graphic
    background = IconSprite.new(self.x, self.y, viewport)
    background.setBitmap("Graphics/UI/Battle/overlay_command")
    addSprite("background", background)
    # Create command window (shows Fight/Bag/Pokémon/Run)
    @cmdWindow = Window_CommandPokemon.newWithSize(
      [], self.x + Graphics.width - 256, self.y, 256, Graphics.height - self.y, viewport
    )
    @cmdWindow.columns       = 2
    @cmdWindow.columnSpacing = 4
    @cmdWindow.ignore_input  = true
    addSprite("cmdWindow", @cmdWindow)
    self.z = z
    refresh
  end

  def z=(value)
    super
    @msgBox.z    += 1
    @cmdWindow.z += 1 if @cmdWindow
  end

  def setTexts(value)
    @msgBox.text = value[0]
    commands = []
    (1..4).each { |i| commands.push(value[i]) if value[i] }
    @cmdWindow.commands = commands
  end

  def refresh
    @msgBox.refresh
    @cmdWindow&.refresh
  end
end



#===============================================================================
# Fight menu (choose a move)
#===============================================================================
class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  attr_reader :battler
  attr_reader :shiftMode

  TYPE_ICON_HEIGHT = 28

  # Just displays text, command window and the graphic
  #     Graphics/UI/Battle/overlay_message.png. 

  # Text colours of PP of selected move
  PP_COLORS = [
    Color.new(239, 0, 0), Color.new(247, 222, 156),    # Red, zero PP
    Color.new(255, 148, 0), Color.new(255, 239, 115),  # Orange, 1/4 of total PP or less
    Color.new(239, 222, 0), Color.new(255, 247, 140),  # Yellow, 1/2 of total PP or less
    Color.new(80, 80, 80), Color.new(160, 160, 160)    # Black, more than 1/2 of total PP
  ]

  def initialize(viewport, z)
    super(viewport)
    self.x = 0
    self.y = Graphics.height - 96
    @battler   = nil
    @shiftMode = 0
    # NOTE: @mode is for the display of the Mega Evolution button.
    #       0=don't show, 1=show unpressed, 2=show pressed
    @shiftBitmap   = AnimatedBitmap.new(_INTL("Graphics/UI/Battle/cursor_shift"))
    @megaEvoBitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Battle/cursor_mega"))
    @typeBitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    @categoryBitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/category"))
    # Create Shift button
    @shiftButton = Sprite.new(viewport)
    @shiftButton.bitmap = @shiftBitmap.bitmap
    @shiftButton.x      = self.x + 4
    @shiftButton.y      = self.y - @shiftBitmap.height
    addSprite("shiftButton", @shiftButton)
    # Create Mega Evolution button
    @megaButton = Sprite.new(viewport)
    @megaButton.bitmap = @megaEvoBitmap.bitmap
    @megaButton.x      = self.x + 116
    @megaButton.y      = self.y - (@megaEvoBitmap.height / 2) 
    @megaButton.src_rect.height = @megaEvoBitmap.height / 2
    addSprite("megaButton", @megaButton)
    # Create background graphic
    background = IconSprite.new(0, Graphics.height - 96, viewport)
    background.setBitmap("Graphics/UI/Battle/overlay_fight")
    addSprite("background", background)
    # Create type icon graphic
    @typeIcon = Sprite.new(viewport)
    @typeIcon.bitmap = @typeBitmap.bitmap
    @typeIcon.x      = self.x + 374
    @typeIcon.x     += 58 if !Settings::BATTLE_MOVE_CATEGORY
    @typeIcon.y      = self.y + 50
    @typeIcon.src_rect.height = TYPE_ICON_HEIGHT
    addSprite("typeIcon", @typeIcon)
    # Create category icon graphic
    @categoryIcon = Sprite.new(viewport)
    @categoryIcon.bitmap = @categoryBitmap.bitmap
    @categoryIcon.x      = self.x + 438
    @categoryIcon.y      = self.y + 50
    @categoryIcon.src_rect.height = TYPE_ICON_HEIGHT
    addSprite("categoryIcon", @categoryIcon)
    # Create overlay for selected move's info (shows move's PP)
    @infoOverlay = BitmapSprite.new(Graphics.width, Graphics.height - self.y, viewport)
    @infoOverlay.x = self.x
    @infoOverlay.y = self.y
    pbSetNarrowFont(@infoOverlay.bitmap)
    addSprite("infoOverlay", @infoOverlay)
    # Create message box (shows type and PP of selected move)
    @msgBox = Window_AdvancedTextPokemon.newWithSize(
      "", self.x + 358, self.y, Graphics.width - 358, Graphics.height - self.y, viewport
    )
    @msgBox.baseColor   = TEXT_BASE_COLOR
    @msgBox.shadowColor = TEXT_SHADOW_COLOR
    pbSetNarrowFont(@msgBox.contents)
    addSprite("msgBox", @msgBox)
    # Create command window (shows moves)
    @cmdWindow = Window_CommandPokemon.newWithSize(
      [], self.x, self.y, 358, Graphics.height - self.y, viewport
    )
    @cmdWindow.columns       = 2
    @cmdWindow.columnSpacing = 4
    @cmdWindow.ignore_input  = true
    pbSetNarrowFont(@cmdWindow.contents)
    addSprite("cmdWindow", @cmdWindow)
    self.z = z
  end

  def dispose
    super
    @typeBitmap&.dispose
    @categoryBitmap&.dispose
    @megaEvoBitmap&.dispose
    @shiftBitmap&.dispose
  end

  def z=(value)
    super
    @msgBox.z      += 1 if @msgBox
    @cmdWindow.z   += 2 if @cmdWindow
    @infoOverlay.z  = @msgBox.z + 6 if @infoOverlay
    @typeIcon.z     = @msgBox.z + 1 if @typeIcon
    @categoryIcon.z = @msgBox.z + 1 if @categoryIcon
  end

  def battler=(value)
    @battler = value
    refresh
    refreshButtonNames
  end

  def shiftMode=(value)
    oldValue = @shiftMode
    @shiftMode = value
    refreshShiftButton if @shiftMode != oldValue
  end

  def refreshButtonNames
    moves = (@battler) ? @battler.moves : []
    # Fill in command window
    commands = []
    [4, moves.length].max.times do |i|
      moveName = "-"
      if (moves[i])
        moveName = (Settings::SHORTEN_MOVES && moves[i].name.length > 15)? moves[i].name[0..11] + "..." : moves[i].name
      end
      commands.push(moveName)
    end
    @cmdWindow.commands = commands
  end

  def refreshSelection
    moves = (@battler) ? @battler.moves : []
    refreshMoveData(moves[@index])
  end

  def refreshMoveData(move)
    @infoOverlay.bitmap.clear
    if !move
      @visibility["typeIcon"] = false
      @visibility["categoryIcon"] = false
      return
    end
    @visibility["typeIcon"] = true
    @visibility["categoryIcon"] = Settings::BATTLE_MOVE_CATEGORY
    # Type icon
    type_number = GameData::Type.get(move.display_type(@battler)).icon_position
    @typeIcon.src_rect.y = type_number * TYPE_ICON_HEIGHT 
    # Category icon
    @categoryIcon.src_rect.y = move.display_category(@battler) * TYPE_ICON_HEIGHT
    # PP text
    if move.total_pp > 0
      ppFraction = [(4.0 * move.pp / move.total_pp).ceil, 3].min
      textPos = []
      textPos.push([_INTL("PP"), 374, 22, :left, PP_COLORS[ppFraction * 2], PP_COLORS[(ppFraction * 2) + 1]])
      textPos.push([_INTL("{1}/{2}", move.pp, move.total_pp),
                    496, 22, :right, PP_COLORS[ppFraction * 2], PP_COLORS[(ppFraction * 2) + 1]])
      textPos.push([_INTL("Type"), 374, 52, :left, Color.new(80, 80, 80), Color.new(160, 160, 160)])  if !Settings::BATTLE_MOVE_CATEGORY
      pbDrawTextPositions(@infoOverlay.bitmap, textPos)
    end
  end

  def refreshMegaEvolutionButton
    @megaButton.src_rect.y    = (@mode - 1) * @megaEvoBitmap.height / 2
    @megaButton.x             = self.x + ((@shiftMode > 0) ? 170 : 116)
    @megaButton.z             = self.z - 1
    @visibility["megaButton"] = (@mode > 0)
  end

  def refreshShiftButton
    @shiftButton.src_rect.y    = (@shiftMode - 1) * @shiftBitmap.height
    @shiftButton.z             = self.z - 1
    @visibility["shiftButton"] = (@shiftMode > 0)
  end

  def refresh
    return if !@battler
    refreshSelection
    refreshMegaEvolutionButton
    refreshShiftButton
  end
end