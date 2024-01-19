#===============================================================================
# "FRLG Battle UI" plugin
# This file contains changes made to Battle_Scene_Animations
# (changes made to party lineup animations).
#===============================================================================
class Battle::Scene::Animation::LineupAppear < Battle::Scene::Animation
  BAR_DISPLAY_WIDTH = 208
  
  def resetGraphics(sprites)
    bar = sprites["partyBar_#{@side}"]
    case @side
    when 0   # Player's lineup
      barX  = Graphics.width - BAR_DISPLAY_WIDTH
      barY  = Graphics.height - 128
      ballX = barX + 40
      ballY = barY - 16
    when 1   # Opposing lineup
      barX  = BAR_DISPLAY_WIDTH
      barY  = 114 - 34
      ballX = barX - 44 - 14   # 14 is width of ball icon
      ballY = barY - 16
      barX -= bar.bitmap.width
    end
    ballXdiff = 20 * (1 - (2 * @side))
    bar.x       = barX
    bar.y       = barY
    bar.opacity = 255
    bar.visible = false
    Battle::Scene::NUM_BALLS.times do |i|
      ball = sprites["partyBall_#{@side}_#{i}"]
      ball.x       = ballX
      ball.y       = ballY
      ball.opacity = 255
      ball.visible = false
      ballX += ballXdiff
    end
  end
end