################################################################################
# "Caruban's Dynamic Darkness" v 1.0.0
# By Caruban
#-------------------------------------------------------------------------------
# I made this plugin after seeing NuriYuri's DynamicLight (PSDK). 
# With this plugin, you can make dark maps more lively with a light source that you can control freely.
# One example of this kind of darkness is Ecruteak's Gym in HGSS.
#
# SETTINGS
# In the plugin Settings section, you may edit several variables.
# Below is a list of the settings.
# - INITIAL_DARKNESS_CIRCLE
# The initial radius of the darkness circle on dark maps
# - FLASH_CIRCLE_RADIUS
# Radius of darkness circle while using Flash
# - VARIABLE_RADIUS_DARK_MAP
# Variable ID of initial radius based on Map ID
# Any radius changes on these map IDs will be reset after the player gets 
# out of the dark map and saved to this variable.
# - INITIAL_DARKNESS_OPACITY
# Initial opacity of darkness on dark maps
# - OPACITY_DARK_MAP_BY_ID
# Value of initial opacity based on Map ID
# This will give a different opacity for every map IDs listed here.
#
# SCRIPT COMMANDS
# There are several script commands that you can use to control the darkness.
# Below is a list of script commands.
# - pbGetDarknessOpacity
# This script command is used to get the darkness opacity on the current map.
# - pbGetDarknessRadius
# This script command is used to get the darkness radius on the current map.
# - pbSetDarknessRadius(value)
# This script command is used to set the darkness radius on the current map.
# - pbMoveDarknessRadius(value)
# This script command is used to change the darkness radius gradually on the current map.
# - pbMoveDarknessRadiusMax
# This script command is used to change the darkness radius gradually to the max on the current map. 
# It will fully brighten the map.
# - pbMoveDarknessRadiusMin
# This script command is used to change the darkness radius gradually to the min on the current map.
# The player will be lost its light source.
#
# EVENT BEHAVIOURS
# These are several pieces of text that can be put into the event's name,
# which will cause those events to have particular behaviours.
# Below is a list of those texts and behaviours.
# - "glowalways"
# An event with this text in its name will always become a light source.
# - "glowswitch(X)"
# An event with this text in its name will become a light source if the switch is ON.
# The "X" is the game variable ID (1 - xxx) or the event's self switch (A, B, C, or D).
# - "glowsize(X)"
# An event with this text in its name will become a light source with a radius of "X" pixels.
# This is also treated as "glowalways" if there is no "glowswitch(X)" in its name.
# - "glowstatic"
# An event with this text in its name will become a static light source.
# This is also treated as "glowalways" if there is no "glowswitch(X)" in its name.
################################################################################
# Configuration
################################################################################
module Settings
  # The initial radius of the darkness circle on dark maps
  INITIAL_DARKNESS_CIRCLE = 64

  # Radius of darkness circle while using Flash
  FLASH_CIRCLE_RADIUS = 176

  # Variable ID of initial radius based on Map ID
  # Any radius changes on these map IDs will be reset after the player gets 
  # out of the dark map and saved to this variable.
  VARIABLE_RADIUS_DARK_MAP = {
    # Map ID => Variable ID
    # 50 => 26,
  }

  # Initial opacity of darkness on dark maps
  INITIAL_DARKNESS_OPACITY = 255

  # Value of initial opacity based on Map ID
  # This will give a different opacity for every map IDs listed here.
  OPACITY_DARK_MAP_BY_ID = {
    # Map ID => Opacity value
    # 52 => 200,
  }
end

################################################################################
# Global Variable
################################################################################
class PokemonGlobalMetadata
  # @return [Integer] global darkness radius
  attr_accessor   :darknessRadius
end

################################################################################
# Global Function
################################################################################
# @return [Integer] Opacity of darkness on dark map in this map
def pbGetDarknessOpacity
  value = Settings::OPACITY_DARK_MAP_BY_ID[$game_map.map_id]
  if value
    opacity = value
  else
    opacity = Settings::INITIAL_DARKNESS_OPACITY
  end
  return opacity
end

# @return [Integer] Radius of darkness on dark map in this map
def pbGetDarknessRadius
  var = Settings::VARIABLE_RADIUS_DARK_MAP[$game_map.map_id]
  if var && $game_variables[var]
    radius = $game_variables[var]
  elsif $PokemonGlobal.darknessRadius
    radius = $PokemonGlobal.darknessRadius
  else
    radius = Settings::INITIAL_DARKNESS_CIRCLE
  end
  return radius
end

# Set Radius of darkness on dark map in this map
def pbSetDarknessRadius(value)
  return if value < 0
  var = Settings::VARIABLE_RADIUS_DARK_MAP[$game_map.map_id]
  if var
    $game_variables[var] = value
  elsif $PokemonGlobal.darknessRadius
    $PokemonGlobal.darknessRadius = value
  end
end

# Change darkness circle radius with animation
def pbMoveDarknessRadius(value)
  return if !$game_temp.darkness_sprite
  darkness = $game_temp.darkness_sprite
  value = [darkness.radiusMin, [darkness.radiusMin, value].max].min
  darkness.moveRadius(value)
end

def pbMoveDarknessRadiusMax
  return if !$game_temp.darkness_sprite
  darkness = $game_temp.darkness_sprite
  darkness.moveRadius(darkness.radiusMax)
end

def pbMoveDarknessRadiusMin
  return if !$game_temp.darkness_sprite
  darkness = $game_temp.darkness_sprite
  darkness.moveRadius(darkness.radiusMin)
end

################################################################################
# Event Handlers
################################################################################
# Display darkness circle on dark maps.
EventHandlers.add(:on_map_or_spriteset_change, :show_darkness,
  proc { |scene, _map_changed|
    next if !scene || !scene.spriteset
    map_metadata = $game_map.metadata
    if map_metadata&.dark_map
      $game_temp.darkness_sprite = DarknessSprite.new
      scene.spriteset.addUserSprite($game_temp.darkness_sprite)
      if $PokemonGlobal.flashUsed
        $game_temp.darkness_sprite.radius = Settings::FLASH_CIRCLE_RADIUS
      end
      $PokemonGlobal.darknessRadius = $game_temp.darkness_sprite.radius
    else
      $PokemonGlobal.flashUsed = false
      $game_temp.darkness_sprite&.dispose
      $game_temp.darkness_sprite = nil
      $PokemonGlobal.darknessRadius = nil
    end
  }
)

#===============================================================================
# Flash Handlers
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:FLASH, proc { |move, pkmn, showmsg|
  next false if !pbCheckHiddenMoveBadge(Settings::BADGE_FOR_FLASH, showmsg)
  if !$game_map.metadata&.dark_map
    pbMessage(_INTL("You can't use that here.")) if showmsg
    next false
  end
  if $PokemonGlobal.flashUsed
    pbMessage(_INTL("Flash is already being used.")) if showmsg
    next false
  end
  if $game_temp.darkness_sprite && pbGetDarknessRadius >= Settings::FLASH_CIRCLE_RADIUS
    pbMessage(_INTL("It is already bright here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:FLASH, proc { |move, pokemon|
  darkness = $game_temp.darkness_sprite
  next false if !darkness || darkness.disposed?
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!", pokemon.name, GameData::Move.get(move).name))
  end
  $PokemonGlobal.flashUsed = true
  $stats.flash_count += 1
  duration = 0.7
  old_rad = darkness.radius
  pbWait(duration) do |delta_t|
    darkness.radius = lerp(old_rad, Settings::FLASH_CIRCLE_RADIUS, duration, delta_t)
  end
  darkness.radius = Settings::FLASH_CIRCLE_RADIUS
  next true
})

################################################################################
# Darkness Sprites
################################################################################
class DarknessSprite < Sprite
  attr_reader :radius

  def initialize(viewport = nil)
    super(viewport)
    @darkness = Bitmap.new(Graphics.width, Graphics.height)
    @radius = pbGetDarknessRadius
    pbSetDarknessRadius(@radius)
    @light_modifier = 0
    @light_starttime = System.uptime
    self.bitmap = @darkness
    self.z      = 99998
    refresh
  end
  
  def radiusMin; return 0;  end
  def radiusMax; return 320; end

  def radius=(value)
    @radius = value.round
    pbSetDarknessRadius(@radius)
    refresh
  end

  def moveRadius(value)
    return if value < 0 || value == @radius
    duration = 0.7
    old_rad = @radius
    pbWait(duration) do |delta_t|
      self.radius = lerp(old_rad, value, duration, delta_t)
    end
    self.radius = value
  end

  def refresh
    @darkness.clear
    return if @radius >= radiusMax
    # Initial dark screen
    @darkness.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0,0,0, pbGetDarknessOpacity))
    numfades = 3
    fade_trans = 0.9
    cradius = @radius + @light_modifier
    # Get player position on screen
    cx = $game_player.screen_x                                  # Graphics.width / 2
    cy = $game_player.screen_y - $game_player.sprite_size[1]/2  # Graphics.height / 2
    # Get events position on screen and its behaviours
    events_pos = []
    $game_map.events.each_value { |event|
      cradius_e = (event.name[/glowsize\((\d+)\)/i] rescue false) ? $~[1].to_i : pbGetDarknessRadius
      cradius_e += @light_modifier if !(event.name[/glowstatic/i] rescue false)
      if (event.name[/glowalways/i] || 
         (!event.name[/glowswitch\((\w+)\)/i] && (event.name[/glowsize\((\d+)\)/i] || event.name[/glowstatic/i])) rescue false)
        events_pos.push([event.screen_x, event.screen_y-event.sprite_size[1]/2, cradius_e, true])
      elsif (event.name[/glowswitch\((\w+)\)/i] rescue false)
        switchid = $1
        switch = false
        if (switchid.to_i.to_s == switchid &&  # Variable Switch
           $game_switches[switchid.to_i]) ||
           !event.isOff?(switchid) # Self Switch
            switch = true
        end
        events_pos.push([event.screen_x,event.screen_y-event.sprite_size[1]/2, cradius_e, switch])
      end
    }
    # Draw circle
    (1..numfades).each do |i|
      # Player
      createCircle(cx,cy,numfades,i,cradius) if @radius > 0
      cradius = (cradius * fade_trans).floor
      # Events
      events_pos.each do |ev|
        next if !ev[3] # switch
        createCircle(ev[0],ev[1],numfades,i,ev[2])
        ev[2] = (ev[2] * fade_trans).floor
      end
    end
  end

  def createCircle(cx, cy, numfades, i, cradius)
    alpha = pbGetDarknessOpacity.to_f * (numfades - i) / numfades
    (cx - cradius..cx + cradius).each do |j|
      next if j.odd?
      diff2 = (cradius * cradius) - ((j - cx) * (j - cx))
      diff = Math.sqrt(diff2).to_i
      diff += 1 if diff.odd?
      @darkness.fill_rect(j, cy - diff, 2, diff * 2, Color.new(0, 0, 0, alpha))
    end
  end

  alias caruban_update update
  def update
    duration = 2  # Seconds
    size = 6      # Max light modifier in pixel
    @light_starttime = System.uptime if System.uptime - @light_starttime > duration
    if System.uptime - @light_starttime < duration / 2
      @light_modifier = lerp(0, -size, duration / 2, @light_starttime, System.uptime).to_i
    else
      @light_modifier = lerp(-size, 0, duration / 2, @light_starttime + duration / 2, System.uptime).to_i
    end
    caruban_update
    refresh
  end
end
