#===============================================================================
# Turn certain settings on/off according to your preferences.
#===============================================================================
module ARMSettings
  #===============================================================================
  # Region Map Grid
  #===============================================================================
  # change the square size for each tile on the Region Map here. (I don't recommend changing this but it's here in case you want to anyway.)
  SQUARE_WIDTH  = 16
  SQUARE_HEIGHT = 16

  #===============================================================================
  # Hidden Region Locations
  #===============================================================================
  # This is similar to the REGION_MAP_EXTRAS you set-up in the Settings script section.
  # Why it is here? Well this is simply because it's easier to access if it's all on 1 place.
  # A set of arrays, each containing details of a graphic to be shown on the
  # region map if appropriate. The values for each array are as follows:
  # - Region number.
  # - Game Switch; The graphic is shown if this is ON (non-wall maps only unless you set the last setting to nil).
  # - X coordinate of the graphic on the map, in squares.
  # - Y coordinate of the graphic on the map, in squares.
  # - Name of the graphic, found in the Graphics/Pictures folder.
  # - The graphic will always (true), never (false) or only when the switch is ON (nil) be shown on a wall map.
  REGION_MAP_EXTRAS = [
    [0, 51, 16, 15, "mapHiddenBerth"], #last option is set to nil
    [0, 52, 20, 14, "mapHiddenFaraday", true] #last option is set to true
  ]
  
  #===============================================================================
  # Fly From Town Map
  #===============================================================================
  # Whether the player can use Fly while looking at the Town Map. This is only
  # allowed if the player can use Fly normally.
  CAN_FLY_FROM_TOWN_MAP = true

  #===============================================================================
  # Quick Fly Feature Settings
  #===============================================================================
  # Set this to true if you want to enable the Quick Fly feature.
  # Set this to false if you don't want to use this feature, all other settings below will be ignored.
  CAN_QUICK_FLY = true

  # Choose which Button will activate the Quick Fly Feature
  # Possible buttons are: JUMPUP, JUMPDOWN, SPECIAL, AUX1 and AUX2. any other buttons are not recommended.
  # Press F1 in game to know which key a button is linked to.
  # IMPORTANT: only change the "JUMPUP" to SPECIAL for example so QUICK_FLY_BUTTON = Input::SPECIAL
  QUICK_FLY_BUTTON = Input::JUMPUP

  # Set this to true if you want to enable that the cursor moves automatically to the selected map from the Quick Fly Menu (on selecting, not confirming).
  # Set this to false if you don't want to enable this.
  AUTO_CURSOR_MOVEMENT = true 

  # Set a Switch that needs to be ON in order to enable the Quick Fly Feature.
  # Set this to nil if you don't want to require any switch to be ON.
  # Example: SWITCH_TO_ENABLE_QUICK_FLY = 11 # Quick Fly will be enabled when Switch with ID 11 (Defeated Gym 8) is set to ON. (This is a default essentials Switch) 
  SWITCH_TO_ENABLE_QUICK_FLY = nil

  #===============================================================================
  # Cursor Map Movement Offset
  #===============================================================================
  # This is a optional Setting to make the map move before the Cursor is at the edge of the map screen.
  # - false = No offset, the map will only move (if possible) when the cursor is on the direction's edge of the screen.
  #   example: When you  want to move to the Right, the map will only start moving once the cursor is all the way on the Right edge of the screen. 
  # - true = the map will move (if possible) when the cursor is 1 position away from the direction's edge of the screen.
  #   example: When you want to move to the Right, the map will start moving once the cursor is 1 tile away from the Right edge of the screen. 
  CURSOR_MAP_OFFSET = true  

  #===============================================================================
  # Region District Names
  #===============================================================================
  # Set this to true if you want to change the default name (defined in the PBS) for certain parts of your Region Map.
  USE_REGION_DISTRICTS_NAMES = true   

  # - Region Number
  # - [min X, max X]; the minimum X value and the maximum X value, in squares.
  #    example: [0, 32]; when the cursor is between 0 and 32 (including 0 and 32) the name of the region changes (depending on the Y value as well).
  # - [min Y, max Y]; the minimum Y value and the maximum Y value, in squares.
  #    example: [0, 10]; when the cursor is between 0 and 10 (including 0 and 10) the name of the region changes (depending on the X value as well).
  # - Region District Name; this is the name the script will use only when the cursor is inside X and Y range.
  REGION_DISTRICTS = [
    [0, [9, 12], [8, 11], "West Essen"],
    [0, [9, 19], [12, 15], "South Essen"],
    [0, [9, 19], [4, 7], "North Essen"],
    [0, [15, 19], [7, 11], "East Essen"],
    [0, [13, 14], [8, 11], "Central Essen"],
    [1, [10, 20], [5, 15], "Central Tiall"]
  ]

  #===============================================================================
  # Replace Unvisited Map Names and Point of Interests with any Text you want.
  #===============================================================================
  # Set this to true if you want the name of a location when hovered over in the Region Map being replaced with "???" if it has not been visited yet.
  # Set this to false if you don't want this setting. 
  NO_UNVISITED_MAP_INFO = false     

  # Change this to whatever text you want the map to show instead of the Location's name if it hasn't been visited yet (only applies if above's setting is set to true).
  UNVISITED_MAP_TEXT = "???"

  # Change this to whatever text you want the map to show for the current Location's Point of Interest if it has one. ("" means it'll not show anything)
  UNVISITED_POI_TEXT = "???"

  # Only used if NO_UNVISITED_MAP_INFO is turned on (true)
  # You can link each Point of Interest you have on your Town Map to a certain Game Map ID
  # If this map is then visited, the Point of Interest will be revealed, otherwise it'll revealed together with the location.
  # For example: if Cedolan City has a Point of Interest named "Cedolan Dept. Store", if Cedolan City has been visited, both "Cedolan City" and "Cedolan Dept. Store" are shown for that location.
  # You can prevent the Point of Interest "Cedolan Dept. Store" being revealed by linking it to a Game map (14 in this case). Only once Game map with ID 14 is visited, the Point of Interest is revealed.
  LINK_POI_TO_MAP = {
    "Ice Cave" => 34,
    "Cedolan Dept. Store" => 14
  }

  #===============================================================================
  # Highlight Opacity
  #===============================================================================
  # Change the opacity of the Highlight images to any value between 0 and 100 in steps of 5.
  # Possible values: 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100.
  # Any other values than the one mentioned above will be converted to the closest one accepted.
  # For example 97 will be converted to 95 which will result in the Highlight Images having an opacity of 95%.
  # Any values higher than 100 will be converted to 100%.
  HIGHLIGHT_OPACITY = 85

  #===============================================================================
  # Region Map Modes
  #===============================================================================
  # Choose which button needs to be pressed to change the map mode. ACTION is the default one in essentials.
  # ATTENTION: if you set this to the same button that has been asigned for quick fly and/or quest preview then you won't be able to change modes anymore.
  CHANGE_MODE_BUTTON = Input::ACTION

  # Set the name for each mode you want to display on the Region Map. 
  # Only change what's between the " ". quest and berry are modes that requires a plugin to be installed in order to be activated on the Region Map.
  MODE_NAMES = {
    normal: "Normal Map",
    fly: "Fly Map",
    quest: "Quest Map", #requires the "Modern Quest System + UI" plugin to use.
    berry: "Berry Map", #requires the "TDW Berry Planting Improvements" plugin by Authorwrigty12 to use.
    roaming: "Roaming Map" #requires the "Roaming Icons" plugin by -FL- to use.
  }

  # Set this to true if you want to have a choice menu when you have 3 or more available modes (by default you won't have choice menu when 2 or 1).
  # Set this to false if you want to change the mode by pressing the set button above (CHANGE_MODE_BUTTON) each time (no choice menu will be shown).
  CHANGE_MODE_MENU = true 

  #===============================================================================
  # Region Map Button Preview Options
  #===============================================================================
  # Choose where you want to display the Button Preview Box on the Region Map.
  # - Set this to 1 to display it in the Top Right.
  # - Set this to 2 to display it in the Bottom Right.
  # - Set this to 3 to display it in the Top Left default position).
  # - Set this to 4 to display it in the Bottom Left.
  BUTTON_BOX_POSITION = 1

  # Change the opacity of the Button Preview Box when you move the Cursor behind it.
  # Any value is accepted between 0 and 100 in steps of 5. (Just like the Highlight Opacity Setting).
  BUTTON_BOX_OPACITY = 50

  # Add a small offset to Button Box Text Position (optional). 
  BUTTON_BOX_TEXT_OFFSET_X = 0
  BUTTON_BOX_TEXT_OFFSET_Y = 0

  # Change the Color for the Text in the Button Box.
  BUTTON_BOX_TEXT_MAIN = Color.new(248, 248, 248)
  BUTTON_BOX_TEXT_SHADOW = Color.new(0, 0, 0)

  # Set the amount of time (in seconds) for the Button Preview Text to change to the next one (when 2 or more Actions).
  BUTTON_PREVIEW_TIME_CHANGE = 3 

  #===============================================================================
  # Region Map Music
  #===============================================================================
  # Set this to true if you want to have the BGM change when opening the Region Map.
  # The BGM that was playing before will be restored when closing the Region Map.
  CHANGE_MUSIC_IN_REGION_MAP = false 

  # You can set different BGM for each region, change the volume and pitch. Volume and Pitch are 100 by default.
  # - The Region number.
  # - The name of the BGM
  # - Volume level.
  # - Pitch level.
  MUSIC_PER_REGION = [
    [0, "Radio - Oak", 90, 100], #Volume will be set to 90% and Pitch to 100%
    [0, "Radio - March"] #Volume and Pitch are both set to 100 by default if not given here.
  ]

  #===============================================================================
  # Region Map Text Positions
  #===============================================================================
  # Add an offset to each Text individually (optional). This could be handy if you're using a custom UI.
  # Used for the Region and District Name Text Position.
  REGION_NAME_OFFSET_X = 0
  REGION_NAME_OFFSET_Y = 0

  # Used for the Location Name Text Position.
  LOCATION_NAME_OFFSET_X = 0
  LOCATION_NAME_OFFSET_Y = 0

  # Used for the Point of Interest Text Position.
  POI_NAME_OFFSET_X = 0
  POI_NAME_OFFSET_Y = 0

  # Used for the Mode Name Text Position
  MODE_NAME_OFFSET_X = 0
  MODE_NAME_OFFSET_Y = 0 

  #===============================================================================
  # Region Map Text Colors
  #===============================================================================
  # Change the color for each Text individually (optional).
  # Color used for the Region and Distric Name Text.
  REGION_TEXT_MAIN = Color.new(248, 248, 248)
  REGION_TEXT_SHADOW = Color.new(0, 0, 0)

  # Color used for the Location Name Text.
  LOCATION_TEXT_MAIN = Color.new(248, 248, 248)
  LOCATION_TEXT_SHADOW = Color.new(0, 0, 0)

  # Color used for the Point of Interest Text Position.
  POI_TEXT_MAIN = Color.new(248, 248, 248)
  POI_TEXT_SHADOW = Color.new(0, 0, 0)

  # Color used for the Mode Name Text Position.
  MODE_TEXT_MAIN = Color.new(248, 248, 248)
  MODE_TEXT_SHADOW = Color.new(0, 0, 0)

  #===============================================================================
  # Region Map UI options
  #===============================================================================
  # Set this to true if you're using a UI that is transparant and you want to see the Region map behind this UI.
  REGION_MAP_BEHIND_UI = false     
  
  # Set for each Region if you want the Player Icon to be visible (true) or invisible (false).
  SHOW_PLAYER_ON_REGION = {
    region0: true,
    region1: false
  }

  # Set this to true if you want the cursor being centered by default when no Map Position is defined for the Game Map the Region Map was opened from.
  CENTER_CURSOR_BY_DEFAULT = true  

  # Set this to true if you want the UI and Graphics to change depending on the Region number.
  # For each Region you want the UI to change, make a new Folder and name it "Region1" or any Region number (as long as it matches with the one set in the PBS).
  # The Default UI will be used if no Region Folder is found for the current Region.
  CHANGE_UI_ON_REGION = false 
  #===============================================================================
  # Region Map changing
  #===============================================================================
  CHANGE_REGION_BUTTON = Input::JUMPDOWN
  #===============================================================================
  # Region Map Menu Options
  #===============================================================================
  # Change the max options that'll show at the same time when seeing any choice menu.
  # Mainly used for the Quick Fly, Region Changing and Quest Preview.
  # This will prevent the screen being filled with all the location names incase they are long.
  MAX_OPTIONS_CHOICE_MENU = 4

  #===============================================================================
  # Region Map Common Preview Box options
  #===============================================================================
  # This is the line height each line will take for the Location and Quest Preview text.
  PREVIEW_LINE_HEIGHT = 32
      
  #===============================================================================
  # Region Map Location Preview Options
  #===============================================================================
  # Set this to false if you wish to not use the Location Preview feature
  USE_LOCATION_PREVIEW = true

  # Choose the button you need to press to view information about the Current Location.
  SHOW_LOCATION_BUTTON = Input::USE

  # This setting has no effect if NO_UNVISITED_MAP_INFO is set to false
  # Set this to true if you want to view info of locations that are "unvisited".
  CAN_VIEW_INFO_UNVISITED_MAPS = true  

  # Only used when the setting above is set to true. 
  # Default text when the location has not been visited yet.
  UNVISITED_MAP_INFO_TEXT = "No information Available"
  
  # Note: The Location Previews are numbered by the amount of lines they are meant for, 
  # If you change this to a higher number then make sure you have a bigger graphic.
  # Set the max lines the location descripions can take.
  MAX_DESCRIPTION_LINES = 3

  # Add a small offset to the Description Text Position. 
  # (Keep in mind that the Icon, Dash Line and Direction Text Y positions are all calculated based on the Y position of the Description text.)
  DESCRIPTION_TEXT_OFFSET_X = 0
  DESCRIPTION_TEXT_OFFSET_Y = 0

  # Change the Color of the Description text.
  DESCRIPTION_TEXT_MAIN = Color.new(248, 248, 248)
  DESCRIPTION_TEXT_SHADOW = Color.new(0, 0, 0)

  # Set this to true when you want to center the description text if it would be smaller than the icon in lines 
  # (2 lines with a lineheight of 32px each would be smaller than an icon of 96px so the description text will be adjusted by 16px)
  CENTER_DESCRIPTION_TEXT = true 

  # Set the max height a location Icon can take. (Be careful, this settings should be equal to PREVIEW_LINE_HEIGHT * MAX_DESCRIPTION_LINES.)
  MAX_ICON_HEIGHT = 96

  # Add a small offset to the Icon Position.
  ICON_OFFSET_X = 0
  ICON_OFFSET_Y = 0

  # Set this to true if you want the icon to center within the description lines. This is similar to the CENTER_DESCRIPTION_TEXT setting.
  # (3 lines with a lineheight of 32px each would be bigger than an icon of 64px so the icon will be adjusted by 16px.)
  CENTER_ICON = true

  # How to edit the Location preview Box Graphics:
  # In the UI\Default\LocationPreview folder you'll see different LocPreview Images. 
  # Each with a number at the end which tells the script how many lines of text they are meant for.
  # A 2 means 2 lines, 3 means 3 lines and so on.
  # There are 2 variants provided:
  # Normal Version - DIRECTION_HEIGHT_SPACING is not set to 0 and there's Direction information given :
  # Simple formula to calculate the Total Height of the Graphic : 
  # PREVIEW_LINE_HEIGHT * Total Lines.

  # Alt Version - DIRECTION_HEIGHT_SPACING is set to 0 or no Direction information is given :
  # Simple formula to calculate the Total Height of the Graphic : 
  # (PREVIEW_LINE_HEIGHT * Total Lines) + DIRECTION_HEIGHT_SPACING)

  # change the spacing between the Location Description text and the Directions Text. 
  # (Keep in mind that changing this number might require you to edit your Location Preview Images as well to provide enough space.) 
  DIRECTION_HEIGHT_SPACING = 16

  # Set this to true if you want to use the mapLocationPreviewDash.png image and make the script draw a dash line below the description.
  # You can change the width and height and color of this image to your preferences.
  # If the DIRECTION_HEIGHT_SPACING is lower than the Dash Image height, the dash will not be drawn to prevent the dash covering text.
  DRAW_DASH_IMAGES = true 

  # Add a small offset to the Dash Line. (This is the same no matter how many lines the preview box is.)
  DASH_OFFSET_X = 0
  DASH_OFFSET_Y = 0

  # There's no setting to turn location directions on or off as if you don't provide any direction information, 
  # it'll not adjust the preview box height and the dash lines will also not be used.

  # Set the max lines the location directions can take.
  MAX_DIRECTION_LINES = 2
-
  # Add a small offset to the Direction Text Position.
  DIRECTION_TEXT_OFFSET_X = 0
  DIRECTION_TEXT_OFFSET_Y = 0

  # Change the color of the Direction Text.
  DIRECTION_TEXT_MAIN = Color.new(248, 248, 248)
  DIRECTION_TEXT_SHADOW = Color.new(0, 0, 0)

  # Change the amount of spaces between each direction for a location (this will give as result some spacing between each direction.).
  LOCATION_DIRECTION_SPACES = 3

  #===============================================================================
  # Region Map Weather Preview Options
  #===============================================================================
  # Set this to true to display the weather Preview on the Region Map.
  USE_WEATHER_PREVIEW = true 

  # This Setting only applies to the Normal Map (Mode 0). 
  # Set this to true if you want the weather preview only be displayed together with the Location Preview (if active).
  # For all the other modes (provided in the WEATHER_ON_MODES setting below) the preview will always be displayed.
  WEATHER_ON_LOCATION_PREVIEW_ACTIVE = true

  # Set here in an Array, which modes can display the Weather Preview. (only the number)
  # 0 = Normal Map
  # 1 = Fly Map (this applies to both Flying methods (through the Town Map or Using Fly directly)) 
  # 2 = Quest Map
  # 3 = Berry Map (not used yet)
  # 4 = Roaming Map (also not used yet).
  WEATHER_ON_MODES = [0, 1]

  #===============================================================================
  # Region Map Quest Preview and Quest Icons Options (IMPORTANT: Required the MQS Plugin to funcion correctly!)
  #===============================================================================
  # Set this to true if you want to display Quest Icons on the Region map (this only shows on the Town Map the player owns and the PokeGear map).
  # Set this to false if you don't want to display Quest Icons or if you are simply not using the MQS Plugin.
  # If the MQS is not installed and this is set to true, it won't harm anything.
  SHOW_QUEST_ICONS = true    

  # Choose which button will activate the Quest Review. 
  # Possible buttons are: USE, JUMPUP, JUMPDOWN, SPECIAL, AUX1 and AUX2. any other buttons are not recommended.
  # USE can be used this time because unlike with the fly map, it won't do anything.
  # Press F1 in game to know which key a button is linked to.
  # IMPORTANT: only change the "JUMPUP" to JUMPDOWN for example so SHOW_QUEST_BUTTON = Input::JUMPDOWN
  SHOW_QUEST_BUTTON = Input::USE 

  # How to edit the Quest preview Box Graphics:
  # This is a bit less complex than the Location Preview Graphics as there are no Alt versions this time.
  # Simple formula to calculate the Total Height of the Graphic : 
  # PREVIEW_LINE_HEIGHT * Total Lines.
  # This includes the Task and Location information.
  MAX_QUEST_LINES = 4

  # Add a small offset to Quest Name Text position.
  QUEST_NAME_OFFSET_X = 0
  QUEST_NAME_OFFSET_Y = 0

  # Change the Color of the Quest Name Text.
  QUEST_TEXT_MAIN = Color.new(248, 248, 248)
  QUEST_TEXT_SHADOW = Color.new(0, 0, 0)

  # Add a small offset to the Quest Task and Location Text position.
  QUEST_INFO_OFFSET_X = 0
  QUEST_INFO_OFFSET_Y = 0

  # Change the Color of the Quest Task and Location Text.
  QUEST_INFO_MAIN = Color.new(248, 248, 248)
  QUEST_INFO_SHADOW = Color.new(0, 0, 0)

  #The end of the Settings for now :)
end