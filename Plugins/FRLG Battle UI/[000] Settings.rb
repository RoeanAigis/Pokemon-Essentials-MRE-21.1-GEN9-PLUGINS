#------------------------------------------------------------------------------
# Settings
#------------------------------------------------------------------------------
# This contains settings to modify the FRLG Battle UI Plugin 
#------------------------------------------------------------------------------

module MessageConfig
  # 0 = Pause cursor is displayed at end of text
  # 1 = Pause cursor is displayed at bottom right
  # 2 = Pause cursor is displayed at lower middle side
  CURSOR_POSITION = 0
end

module Settings
    #--------------------------------------------------------------------------
    # If this setting is set to true, move category is displayed beside type
    # icon in battle screen
    #--------------------------------------------------------------------------
    BATTLE_MOVE_CATEGORY = true

    #--------------------------------------------------------------------------
    # If this setting is set to true, move name is shortened with ellipses in 
    # fight menu
    #--------------------------------------------------------------------------
    SHORTEN_MOVES = true
end