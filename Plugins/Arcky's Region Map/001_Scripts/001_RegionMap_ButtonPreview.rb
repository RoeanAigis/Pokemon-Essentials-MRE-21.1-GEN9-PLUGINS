class PokemonRegionMap_Scene  
  def showButtonPreview
    if !@sprites["buttonPreview"]
      @sprites["buttonPreview"] = IconSprite.new(0, 0, @viewport)
      @sprites["buttonPreview"].setBitmap(findUsableUI("mapButtonBox"))
      @sprites["buttonPreview"].z = 24
      @sprites["buttonPreview"].visible = !@flyMap && !@wallmap
    end 
  end

  def convertButtonToString(button)
    controlPanel = $PokemonSystem.respond_to?(:game_controls)
    case button 
    when 11
      buttonName = controlPanel ? "Menu" : "ACTION"
    when 12
      buttonName = controlPanel ? "Cancel" : "BACK"
    when 13 
      buttonName = controlPanel ? "Action" : "USE"
    when 14 
      buttonName = controlPanel ? "Scroll Up" : "JUMPUP"
    when 15
      buttonName = controlPanel ? "Scroll Down" : "JUMPDOWN"
    when 16
      buttonName = controlPanel ? "Ready Menu" : "SPECIAL"
    when 17
      buttonName = "AUX1" #Unused 
    when 18
      buttonName = "AUX2" #Unused
    end 
    if controlPanel
      buttonName = $PokemonSystem.game_controls.find{|c| c.control_action==buttonName}.key_name 
      buttonName = makeButtonNameShorter(buttonName)
    end 
    return buttonName
  end 

  def makeButtonNameShorter(button)
    case button 
    when "Backspace"
      button = "Return"
    when "Caps Lock"
      button = "Caps"
    when "Page Up"
      button = "pg Up"
    when "Page Down"
      button = "pg Dn"
    when "Print Screen"
      button = "prt Scr"
    when "Numpad 0"
      button = "Num 0"
    when "Numpad 1"
      button = "Num 1"
    when "Numpad 2"
      button = "Num 2"
    when "Numpad 3"
      button = "Num 3"
    when "Numpad 4"
      button = "Num 4"
    when "Numpad 5"
      button = "Num 5"
    when "Numpad 6"
      button = "Num 6"
    when "Numpad 7"
      button = "Num 7"
    when "Numpad 8"
      button = "Num 8"
    when "Numpad 9"
      button = "Num 9"
    when "multiply"
      button = "Multi"
    when "Separator"
      button = "Sep"
    when "Subtract"
      button = "Sub"
    when "Decimal"
      button = "Dec"
    when "Divide"
      button = "Div"
    when "Num Lock"
      button = "Num"
    when "Scroll Lock"
      button = "Scroll"
    end 
    return button 
  end 

  def updateButtonInfo(name = "", replaceName = "")
    return if @wallmap || @flyMap
    @timer = 0 if !@timer
    frames = ARMSettings::BUTTON_PREVIEW_TIME_CHANGE * Graphics.frame_rate
    width = @previewShow && @mode == 2 && BOX_TOP_LEFT ? (Graphics.width - @sprites["previewBox"].width) : @sprites["buttonPreview"].width 
    textPos = getTextPosition
    getAvailableActions(name, replaceName)
    avActions = @mapActions.select { |_, action| action[:condition]}.values
    avActions.sort_by! { |action| action[:priority] ? 0 : 1 }
    if avActions != @prevAvActions
      @prevAvActions = avActions
      @timer = 0
    end
    @indActions = (@timer / frames) % avActions.length
    if avActions.any?
      selActions = avActions[@indActions % avActions.length]
      button = convertButtonToString(selActions[:button])
      text = "#{button}: #{selActions[:text]}"
      @sprites["buttonName"].bitmap.clear
      pbDrawTextPositions(
      @sprites["buttonName"].bitmap,
      [[text, (textPos[0] + (width / 2)) + ARMSettings::BUTTON_BOX_TEXT_OFFSET_X, (textPos[1] + 14) + ARMSettings::BUTTON_BOX_TEXT_OFFSET_Y, 2, ARMSettings::BUTTON_BOX_TEXT_MAIN, ARMSettings::BUTTON_BOX_TEXT_SHADOW]]
      )
      @sprites["buttonName"].visible = !@flyMap && !@wallmap
      @sprites["buttonName"].z = 25
    end 
  end 

  def getAvailableActions(name = "", replaceName = "")
    getAvailableRegions if !@avRegions
    @mapActions = {
      :ChangeMode => {
        condition: @modeCount >= 2,
        text: "Change Mode",
        button: ARMSettings::CHANGE_MODE_BUTTON
      },
      :ChangeRegion => {
        condition: @avRegions.length >= 2 && !@previewShow,
        text: "Change Region",
        button: ARMSettings::CHANGE_REGION_BUTTON
      },
      :ViewInfo => {
        condition: @mode == 0 && !@previewShow && name != "" && (name != replaceName || ARMSettings::CAN_VIEW_INFO_UNVISITED_MAPS) || @lineCount == 0,
        text: "View Info",
        button: ARMSettings::SHOW_LOCATION_BUTTON,
        priority: true
      },
      :HideInfo => {
        condition: @mode == 0 && @previewShow && @lineCount != 0 && @curLocName != "",
        text: "Hide Info",
        button: Input::BACK
      },
      :QuickFly => {
        condition: @mode == 1 && ARMSettings::CAN_QUICK_FLY && (ARMSettings::SWITCH_TO_ENABLE_QUICK_FLY.nil? || $game_switches[ARMSettings::SWITCH_TO_ENABLE_QUICK_FLY]),
        text: "Quick Fly",
        button: ARMSettings::QUICK_FLY_BUTTON,
        priority: true
      },
      :ShowQuest => {
        condition: @mode == 2 && @questNames.is_a?(Array) && @questNames.length < 2 && !@previewShow,
        text: "View Quest",
        button: ARMSettings::SHOW_QUEST_BUTTON,
        priority: true 
      },
      :HideQuest => {
        condition: @mode == 2 && @previewShow,
        text: "Hide Quest",
        button: Input::BACK
      },
      :ShowQuests => {
        condition: @mode == 2 && @questNames.is_a?(Array) && @questNames.length >= 2 && !@previewShow,
        text: "View Quests",
        button: ARMSettings::SHOW_QUEST_BUTTON,
        priority: true
      },
      :ChangeQuest => {
        condition: @mode == 2 && @questNames.is_a?(Array) && @questNames.length >= 2 && @previewShow,
        text: "Change Quest",
        button: ARMSettings::SHOW_QUEST_BUTTON
      },
      :Quit => {
        condition: !@previewShow,
        text: "Close Map",
        button: Input::BACK
      }
    }
  end 
end 