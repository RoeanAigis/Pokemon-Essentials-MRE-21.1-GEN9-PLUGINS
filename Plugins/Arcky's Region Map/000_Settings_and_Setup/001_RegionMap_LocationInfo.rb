=begin
  The following settings for text formatting can be used for the description of each location.
  <b> ... </b>       - Formats the text in bold.
  <i> ... </i>       - Formats the text in italics.
  <u> ... </u>       - Underlines the text.
  <s> ... </s>       - Draws a strikeout line over the text.
  <al> ... </al>     - Left-aligns the text.  Causes line breaks before and after
                       the text.
  <r>                - Right-aligns the text until the next line break.
  <ar> ... </ar>     - Right-aligns the text.  Causes line breaks before and after
                       the text.
  <ac> ... </ac>     - Centers the text.  Causes line breaks before and after the
                       text.
  <br>               - Causes a line break.
  <o=X>              - Displays the text in the given opacity (0-255)
  <outln>            - Displays the text in outline format.
  <outln2>           - Displays the text in outline format (outlines more
                       exaggerated.
  <icon=X>           - Displays the icon X (in Graphics/Icons/).
=end

module ARMLocationPreview
  # Region0
  LappetTown = {
    description: "A fairly old and loud town. \nIt's a big and not so pretty place.", # \n or <br> can be used to add a line break.
    south: [13, 20],
    north: [13, 11],
    west: [12, 12],
    icon: "LappetTown"
  }

  Route1 = {
    description: "<ac>The first Route in the Region and a home to Kurt.</ac>", # <ac>text</ac> can be used to center text horizontally.
    south: [13, 12],
    north: [13, 10]
  }

  CedolanCity = {
    # location [13, 10]
    northEast_13_10: [14, 9],
    south_13_10: [13, 11],
    # location [14, 10]
    north_14_10: [14, 9],
    southWest_14_10: [13, 11],
    # used for both locations
    east: [15, 10],
    west: [12, 10],
    description_13_10: "The biggest City in Essen. It has a department store!",
    description_14_10: "The biggest City in Essen. It has a department store and what does it not have?",
    icon: "LappetTown"
  }

  Route2 = {
    description: "A route with a lot of bridges.",
    east_14_8: [15, 8],
    northEast_14_9: [15, 8],
    south: [13, 10]
  }

  LeruceanTown = {
    west: [14, 8],
    east: [16, 8],
    north: [15, 7],
    description: "Another Small Town. And a lot of text to fill the space here up to 3 lines yes yes baguette!",
    icon: "LappetTown"
  }

  NaturalPark = {
    west: [15, 8],
    description: "A big Park and it's natural."
  }

  Route3 = {
    west_14_6: [13, 6],
    east_14_6: "Ice Cave",
    west_15_6: [13, 6],
    south_15_6: [15, 8],
    south_15_7: [15, 8],
    north_15_7: "Ice Cave",
    description: "A Route full with Trainers.",
    description_15_6: "An Icy Cold Cave located here... And still a lot of Trainers!"
  }

  IngidoPlateau = {
    description: "Once a trainer has collected all 8 Badges, they are allowed to enter the League and challenge the E4 and Champion!",
    west: [12, 6],
    east: [14, 6]
  }

  Route4 = {
    description: "The start of the Cycling Bridge.",
    south_11_6: [11, 7],
    east: [13, 6],
    southWest_12_6: [11, 7]
  }

  Route5 = {
    description: "The Cycling Bridge itself!",
    north: [11, 6],
    south: [11, 10]
  }

  Route6 = {
    description: "The end of the Cycling Bridge",
    north_11_10: [11, 7],
    northWest_12_10: [11, 7],
    east: [13, 10]
  }

  Route7 = {
    description: "A rocky route with mountains and caves and stuff."
  }

  BattleFrontier = {
    south: [18, 17],
    west: "Rock Cave",
    description: "Challenge the Brains of the Frontier! Which are just Humans."
  }

  SafariZone = {
    description: "A zone to go on Safari. What else would you do here?",
    east: [13, 12]
  }

  Route8 = {
    description: "Is this even a Route? It's just water and a waterfall.",
    north: [13, 12]
  }

  BerthIsland = {
    description: "The island which is home to the Pokémon named Deoxys."
  }

  FaradayIsland = {
    description: "The island which is home to the Pokémon named Mew and it's shiny!"
  }

  # Region1
  Here = {
    description: "There's something here but I don't know what!"
  }

  #Region2
  ViraidanCity = {
    description: "All there's known about this place is that they sell Baguette!"
  }
end    