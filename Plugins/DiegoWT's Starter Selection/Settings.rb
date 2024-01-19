#===============================================================================
# DiegoWT's Starter Selection script settings
#===============================================================================
module StarterSelSettings

# To start the scene, call the script "DiegoWTsStarterSelection.new(x,y,z)", where x, y and z are the species ID of your starters.
# Example of the script call using Bulbasaur, Charmander and Squirtle: 
# DiegoWTsStarterSelection.new(:BULBASAUR,:CHARMANDER,:SQUIRTLE)

# Level of your starters:
  STARTERL = 5
 
# Interface style (1 for HGSS, 2 for BW):
  INSTYLE = 1

# Background choice (1 for lab's table, 2 for grass)
  STARTERBG = 1

# Form of each Starter species:
  STARTER1FORM = 0 # First Starter
  STARTER2FORM = 0 # Second Starter
  STARTER3FORM = 0 # Third Starter

# Shininess of each Starter species, 0 is random, 1 locks to not shiny, 2 locks to shiny:
  STARTER1SHINY = 0 # First Starter
  STARTER2SHINY = 0 # Second Starter
  STARTER3SHINY = 0 # Third Starter

# Whether if each Starter species will have random IVs or not, 0 is random, 1 is 31 IVs for each status:
  STARTER1IV = 0 # First Starter
  STARTER2IV = 0 # Second Starter
  STARTER3IV = 0 # Third Starter
# You can also edit the Script to change the values to something other than 31, lines: 79, 93 and 107

# Item of each Starter species (nil is nothing):
  STARTER1ITEM = nil # First Starter
  STARTER2ITEM = nil # Second Starter
  STARTER3ITEM = nil # Third Starter
# Use the ID of the items when defining them here, and put an : before the name. Such as :ORANBERRY
  
# Horizontal and vertical values for editing the starter position:
  STARTER1X = 0; STARTER1Y = 0 # First Starter
  STARTER2X = 0; STARTER2Y = 0 # Second Starter
  STARTER3X = 0; STARTER3Y = 0 # Third Starter
# Here, for the horizontal lines, negative numbers are left and the positive 
# ones are right. For the vertical lines, negative numbers are up and the
# positive ones are down. Always try to use even numbers!
  
# Starter's circle size configuration. Configure how big you want the Starter
# white circle to be:
  STARTERCZ = 0 # 0 is normal size; 1 is double the size
  
# Set true if you want the script to play the selected starter's cry when selected, 
# or false if not:
  STARTERCRY = true

# Configuration for using two gradients to match both types' colors of the starter.
# This will also work if one or more of your starters only have one type.
# Set true if you want it, or false if not:
  TYPE2COLOR = true

end
