#===============================================================================
# "FRLG Battle UI" plugin
# This file contains changes made to Battle_Scene_Objects and SafariBattle
# (changes made to databoxes and ability splash).
#===============================================================================
#===============================================================================
# Data box for regular battles
#===============================================================================
class Battle::Scene::PokemonDataBox < Sprite
  attr_reader   :battler
  attr_accessor :selected

  # Time in seconds to fully fill the Exp bar (from empty).
  EXP_BAR_FILL_TIME  = 1.75
  # Time in seconds for this data box to flash when the Exp fully fills.
  EXP_FULL_FLASH_DURATION = 0.2
  # Maximum time in seconds to make a change to the HP bar.
  HP_BAR_CHANGE_TIME = 1.0
  # Time (in seconds) for one complete sprite bob cycle (up and down) while
  # choosing a command for this battler or when this battler is being chosen as
  # a target. Set to nil to prevent bobbing.
  BOBBING_DURATION = 0.6
  # Height in pixels of a status icon
  STATUS_ICON_HEIGHT = 16
  # Text colors
  NAME_BASE_COLOR         = Color.new(64, 64, 64)
  NAME_SHADOW_COLOR       = Color.new(216, 208, 176)
  MALE_BASE_COLOR         = Color.new(64, 200, 208)
  MALE_SHADOW_COLOR       = NAME_SHADOW_COLOR
  FEMALE_BASE_COLOR       = Color.new(248, 152, 144)
  FEMALE_SHADOW_COLOR     = NAME_SHADOW_COLOR

  def initialize(battler, sideSize, viewport = nil)
    super(viewport)
    @battler      = battler
    @sprites      = {}
    @spriteX      = 0
    @spriteY      = 0
    @spriteBaseX  = 0
    @selected     = 0
    @sideSize     = sideSize
    @show_hp_numbers = false
    @show_exp_bar    = false
    initializeDataBoxGraphic()
    initializeOtherGraphics(viewport)
    refresh
  end

  def initializeDataBoxGraphic
    onPlayerSide = @battler.index.even?
    # Get the data box graphic and set whether the HP numbers/Exp bar are shown
    if @sideSize == 1   # One Pokémon on side, use the regular dara box BG
      bgFilename = ["Graphics/UI/Battle/databox_normal",
                    "Graphics/UI/Battle/databox_normal_foe"][@battler.index % 2]
      if onPlayerSide
        @show_hp_numbers = true
        @show_exp_bar    = true
      end
    else   # Multiple Pokémon on side, use the thin dara box BG
      bgFilename = ["Graphics/UI/Battle/databox_thin",
                    "Graphics/UI/Battle/databox_thin_foe"][@battler.index % 2]
    end
    @databoxBitmap&.dispose
    @databoxBitmap = AnimatedBitmap.new(bgFilename)
    # Determine the co-ordinates of the data box and the left edge padding width
    if onPlayerSide
      @spriteX = (Graphics.width - 270)
      @spriteY = Graphics.height - 192
      @spriteBaseX = 34
    else
      @spriteX = (-16 + 24)
      @spriteY = 36
      @spriteBaseX = 16
    end
    case @sideSize
    when 2
      @spriteX += [2,  4,  14,  -8][@battler.index]
      @spriteY += [-20, -34, 34, 20][@battler.index]
    when 3
      @spriteX += [2,  4, 8,  -2,  14,  -8][@battler.index]
      @spriteY += [-42, -46,  4,  0, 50, 46][@battler.index]
    end
  end

  def initializeOtherGraphics(viewport)
    # Create other bitmaps
    @numbersBitmap = AnimatedBitmap.new("Graphics/UI/Battle/icon_numbers")
    @hpBarBitmap   = AnimatedBitmap.new("Graphics/UI/Battle/overlay_hp")
    @expBarBitmap  = AnimatedBitmap.new("Graphics/UI/Battle/overlay_exp")
    # Create sprite to draw HP numbers on
    @hpNumbers = BitmapSprite.new(134, 16, viewport)
    # pbSetSmallFont(@hpNumbers.bitmap)
    @sprites["hpNumbers"] = @hpNumbers
    # Create sprite wrapper that displays HP bar
    @hpBar = Sprite.new(viewport)
    @hpBar.bitmap = @hpBarBitmap.bitmap
    @hpBar.src_rect.height = @hpBarBitmap.height / 3
    @sprites["hpBar"] = @hpBar
    # Create sprite wrapper that displays Exp bar
    @expBar = Sprite.new(viewport)
    @expBar.bitmap = @expBarBitmap.bitmap
    @sprites["expBar"] = @expBar
    # Create sprite wrapper that displays everything except the above
    @contents = Bitmap.new(@databoxBitmap.width, @databoxBitmap.height)
    self.bitmap  = @contents
    self.visible = false
    self.z       = 150 + ((@battler.index / 2) * 5)
    pbSetSystemFont(self.bitmap)
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @databoxBitmap.dispose
    @numbersBitmap.dispose
    @hpBarBitmap.dispose
    @expBarBitmap.dispose
    @contents.dispose
    super
  end

  def x=(value)
    onPlayerSide = @battler.index.even?
    super
    @hpBar.x     = value + @spriteBaseX + 116
    @hpBar.x    += 6 if !onPlayerSide
    @expBar.x    = value + @spriteBaseX + 18
    @hpNumbers.x = value + @spriteBaseX + 80
  end

  def y=(value)
    onPlayerSide = @battler.index.even?
    super
    @hpBar.y     = value + 40
    @hpBar.y    += !onPlayerSide ? @sideSize != 1 ? 4 : -2 : @sideSize != 1 ? 4 : 0
    @expBar.y    = value + 74
    @hpNumbers.y = value + 52
  end

  def z=(value)
    super
    @hpBar.z     = value + 1
    @expBar.z    = value + 1
    @hpNumbers.z = value + 2
  end

  def pbDrawNumber(number, btmp, startX, startY, align = 0)
    # -1 means draw the / character
    n = (number == -1) ? [10] : number.to_i.digits.reverse
    charWidth  = @numbersBitmap.width / 11
    charHeight = @numbersBitmap.height
    startX -= charWidth * n.length if align == 1
    n.each do |i|
      btmp.blt(startX, startY, @numbersBitmap.bitmap, Rect.new(i * charWidth, 0, charWidth, charHeight))
      startX += charWidth
    end
  end

  def draw_background
    self.bitmap.blt(0, 0, @databoxBitmap.bitmap, Rect.new(0, 0, @databoxBitmap.width, @databoxBitmap.height))
  end

  def draw_name
    pbDrawTextPositions(self.bitmap, 
      [[@battler.name, @spriteBaseX - 2, 12 - 2, :left, NAME_BASE_COLOR, NAME_SHADOW_COLOR]]
    )
  end

  def draw_level
    charWidth  = @numbersBitmap.width / 11
    levelWidth = @battler.level.to_s.length * charWidth
    xDif = @battler.index.even? ? 0 : 6
    showLvGraphic = !(@battler.mega? || @battler.primal?)
    # Level number
    pbDrawNumber(@battler.level, self.bitmap, @spriteBaseX + xDif + 210, 16, 1)
    # "Lv" graphic
    pbDrawImagePositions(self.bitmap,
      [["Graphics/UI/Battle/overlay_lv", @spriteBaseX + xDif + (charWidth * 3 - levelWidth) + 140, 16]]
    ) if showLvGraphic
  end

  def draw_gender
    nameWidth = self.bitmap.text_size(@battler.name).width
    gender = @battler.displayGender
    return if ![0, 1].include?(gender)
    gender_text  = (gender == 0) ? _INTL("♂") : _INTL("♀")
    base_color   = (gender == 0) ? MALE_BASE_COLOR : FEMALE_BASE_COLOR
    shadow_color = (gender == 0) ? MALE_SHADOW_COLOR : FEMALE_SHADOW_COLOR
    pbDrawTextPositions(self.bitmap, [[gender_text, @spriteBaseX - 2 + nameWidth, 12 - 2, :left, base_color, shadow_color]])
  end

  def draw_status
    return if @battler.status == :NONE
    yDif = !@battler.index.even? ? @sideSize != 1 ? 12 : 16 : @sideSize != 1 ? 10 : 0 
    if @battler.status == :POISON && @battler.statusCount > 0   # Badly poisoned
      s = GameData::Status.count - 1
    else
      s = GameData::Status.get(@battler.status).icon_position
    end
    return if s < 0
    pbDrawImagePositions(self.bitmap, [["Graphics/UI/Battle/icon_statuses", @spriteBaseX - 4, 50 - yDif,
                                        0, s * STATUS_ICON_HEIGHT, -1, STATUS_ICON_HEIGHT]])
  end

  def draw_shiny_icon
    return if !@battler.shiny?
    xDif = @battler.status == :NONE ? - 4 : 42
    yDif = !@battler.index.even? ? @sideSize != 1 ? 12 : 16 : @sideSize != 1 ? 10 : 0 
    pbDrawImagePositions(self.bitmap, [["Graphics/UI/shiny", @spriteBaseX + xDif, 50 - yDif]])
  end

  def draw_special_form_icon
      filename = nil
      charWidth  = @numbersBitmap.width / 11
      levelWidth = @battler.level.to_s.length * charWidth
      xDif = @battler.index.even? ? 0 : 6
      if @battler.mega?
          filename = "Graphics/UI/Battle/icon_mega"
      elsif @battler.primal?
          if @battler.isSpecies?(:GROUDON)
              filename = "Graphics/UI/Battle/icon_primal_Groudon"
          elsif @battler.isSpecies?(:KYOGRE)
              filename = "Graphics/UI/Battle/icon_primal_Kyogre"
          end
      end
      pbDrawImagePositions(self.bitmap, [[filename, @spriteBaseX + xDif + (charWidth * 3 - levelWidth) + 143, 14]]) if filename
  end

  def draw_owned_icon
    return if !@battler.owned? || !@battler.opposes?(0) # Draw for foe Pokémon (with no status condition) only
    yDif = !@battler.index.even? ? @sideSize != 1 ? 12 : 16 : @sideSize != 1 ? 10 : 0 
    pbDrawImagePositions(self.bitmap, [["Graphics/UI/Battle/icon_own", @spriteBaseX - 2, 50 - yDif]]
      ) if (@battler.status == :NONE && !@battler.shiny?)
  end

  def refresh_hp
    @hpNumbers.bitmap.clear
    return if !@battler.pokemon
    # Show HP numbers
    if @show_hp_numbers
      pbDrawNumber(self.hp, @hpNumbers.bitmap, 66, 0, 1)
      pbDrawNumber(-1, @hpNumbers.bitmap, 66, 0)   # / char
      pbDrawNumber(@battler.totalhp, @hpNumbers.bitmap, 130, 0, 1)
    end
    # Resize HP bar
    w = 0
    if self.hp > 0
      w = @hpBarBitmap.width.to_f * self.hp / @battler.totalhp
      w = 1 if w < 1
      # NOTE: The line below snaps the bar's width to the nearest 2 pixels, to
      #       fit in with the rest of the graphics which are doubled in size.
      w = ((w / 2.0).round) * 2
    end
    @hpBar.src_rect.width = w
    hpColor = 0                                      # Green bar
    hpColor = 1 if self.hp <= @battler.totalhp / 2   # Yellow bar
    hpColor = 2 if self.hp <= @battler.totalhp / 4   # Red bar
    @hpBar.src_rect.y = hpColor * @hpBarBitmap.height / 3
  end

  def refresh_exp
    return if !@show_exp_bar
    w = exp_fraction * @expBarBitmap.width
    # NOTE: The line below snaps the bar's width to the nearest 2 pixels, to
    #       fit in with the rest of the graphics which are doubled in size.
    w = ((w / 2).round) * 2
    @expBar.src_rect.width = w
  end

end

#===============================================================================
# Data box for safari battles
#===============================================================================
class Battle::Scene::SafariDataBox < Sprite
  attr_accessor :selected

  def initialize(battle, viewport = nil)
    super(viewport)
    @selected    = 0
    @battle      = battle
    @databox     = AnimatedBitmap.new("Graphics/UI/Battle/databox_safari")
    self.x       = Graphics.width - 270
    self.y       = Graphics.height - 192
    @contents    = Bitmap.new(@databox.width, @databox.height)
    self.bitmap  = @contents
    self.visible = false
    self.z       = 50
    pbSetSystemFont(self.bitmap)
    refresh
  end

  def refresh
    self.bitmap.clear
    self.bitmap.blt(0, 0, @databox.bitmap, Rect.new(0, 0, @databox.width, @databox.height))
    base   = Color.new(64, 64, 64)
    shadow = Color.new(216, 208, 176)
    textpos = []
    textpos.push([_INTL("Safari Balls"), 30, 14, :left, base, shadow])
    textpos.push([sprintf("Left: %02d", @battle.ballCount), 160, 44, :left, base, shadow])
    pbDrawTextPositions(self.bitmap, textpos)
  end
end

#===============================================================================
# Splash bar to announce a triggered ability
#===============================================================================
class Battle::Scene::AbilitySplashBar < Sprite
  attr_reader :battler

  ABILITY_BASE_COLOR   = Color.new(255, 255, 255)
  ABILITY_SHADOW_COLOR = Color.new(123, 115, 132)
  TEXT_BASE_COLOR = Color.new(0, 0, 0)
  TEXT_SHADOW_COLOR = Color.new(123, 115, 132)

  def initialize(side, viewport = nil)
    super(viewport)
    @side    = side
    @battler = nil
    # Create sprite wrapper that displays background graphic
    @bgBitmap = AnimatedBitmap.new("Graphics/UI/Battle/ability_bar")
    @bgSprite = Sprite.new(viewport)
    @bgSprite.bitmap = @bgBitmap.bitmap
    @bgSprite.src_rect.y      = (side == 0) ? 0 : @bgBitmap.height / 2
    @bgSprite.src_rect.height = @bgBitmap.height / 2
    # Create bitmap that displays the text
    @contents = Bitmap.new(@bgBitmap.width, @bgBitmap.height / 2)
    self.bitmap = @contents
    pbSetSystemFont(self.bitmap)
    # Position the bar
    self.x       = (side == 0) ? -Graphics.width / 2 : Graphics.width
    self.y       = (side == 0) ? 180 : 80
    self.z       = 120
    self.visible = false
  end

  def refresh
    self.bitmap.clear
    return if !@battler
    textPos = []
    textX = (@side == 0) ? 10 : self.bitmap.width - 8
    align = (@side == 0) ? :left : :right
    # Draw Pokémon's name
    textPos.push([_INTL("{1}'s", @battler.name), textX, 8, align,
                  ABILITY_BASE_COLOR, ABILITY_SHADOW_COLOR])
    # Draw Pokémon's ability
    textPos.push([@battler.abilityName, textX, 36, align,
                  TEXT_BASE_COLOR, TEXT_SHADOW_COLOR])
    pbDrawTextPositions(self.bitmap, textPos)
  end

  def update
    super
    @bgSprite.update
  end
end
