class PokemonRegionMap_Scene  
  def getPreviewBox
    if !@sprites["previewBox"]
      @sprites["previewBox"] = IconSprite.new(0, 0, @viewport)
      @sprites["previewBox"].z = 26
      @sprites["previewBox"].visible = false
    end 
    return if @mode != 0 && @mode != 2
    case @mode
    when 0
      preview = "LocationPreview/mapLocBox#{@useAlt}"
      @sprites["previewBox"].x = 16
    when 2
      @lineCount = 2 if @lineCount == 1
      preview = "QuestPreview/mapQuestBox"
      @sprites["previewBox"].x = Graphics.width - (16 + @sprites["previewBox"].width)
    end 
    @sprites["previewBox"].setBitmap(findUsableUI("#{preview}#{@lineCount}"))
    @questPreviewWidth = @sprites["previewBox"].width if @mode == 2
  end 

  def showPreviewBox
    return if @lineCount == 0
    if @mode == 0
      @sprites["previewBox"].y = Graphics.height - 32
    elsif @mode == 2
      @sprites["previewBox"].y = 32 - @sprites["previewBox"].height
    end
    @sprites["previewBox"].visible = true
    height = @sprites["previewBox"].height
    if @mode == 0
      @sprites["previewBox"].y = (Graphics.height - 32) - height
      # Check if the Button Box is on the bottom and the previewBox is bigger than the Button Box when on the Bottom Right.
    elsif @mode == 2
      # do similar like mode 0 but yet different XD
      @sprites["previewBox"].y = (32 - @sprites["previewBox"].height) + height 
    end
    changePreviewBoxAndArrow(height)
    if @mode == 0
      @sprites["locationDash"].visible = true if @locationDash
      @sprites["locationIcon"].visible = true if @locationIcon
    end
    @sprites["locationText"].visible = true
    @previewShow = true
    getPreviewWeather 
    updateButtonInfo
    @previewMode = @mode 
  end 

  def changePreviewBoxAndArrow(height)
    previewWidthBiggerButtonX = @sprites["previewBox"].width > @sprites["buttonPreview"].x
    halfScreenWidth = Graphics.width / 2
    previewWidthHalfScreenSize = @sprites["previewBox"].width > halfScreenWidth
    previewWidthDownArrowX = @sprites["previewBox"].width > @sprites["downArrow"].x
    previewXUpArrowX = @sprites["previewBox"].x < @sprites["upArrow"].x
    buttonXDownArrowX = @sprites["buttonPreview"].x > @sprites["downArrow"].x
    buttonWidthDownArrowX = @sprites["buttonPreview"].width > (@sprites["downArrow"].x + 14)
    buttonXHalfScreenSize = @sprites["buttonPreview"].x < halfScreenWidth
    if @mode == 0
      @sprites["downArrow"].y = (Graphics.height - 60) - height if previewWidthDownArrowX 
      if BOX_BOTTOM_LEFT 
        @sprites["buttonPreview"].y = (Graphics.height - (22 + @sprites["buttonPreview"].height)) - height
        @sprites["buttonName"].y = -height
        if previewWidthHalfScreenSize && previewWidthDownArrowX && buttonWidthDownArrowX
          @sprites["downArrow"].y = (Graphics.height - (44 + @sprites["buttonPreview"].height)) - height
        end 
      elsif BOX_BOTTOM_RIGHT
        if previewWidthBiggerButtonX
          @sprites["buttonPreview"].y = (Graphics.height - (22 + @sprites["buttonPreview"].height)) - height
          @sprites["buttonName"].y = -height
        end
        if previewWidthHalfScreenSize && !(previewWidthDownArrowX && buttonXDownArrowX)
          @sprites["downArrow"].y = (Graphics.height - (44 + @sprites["buttonPreview"].height)) - height
        end
      end 
    elsif @mode == 2
      @sprites["upArrow"].y = 16 + height if previewXUpArrowX
      @sprites["upArrow"].y = @sprites["buttonPreview"].height + height if buttonXHalfScreenSize
      if BOX_TOP_RIGHT
        @sprites["buttonPreview"].y = 22 + height 
        @sprites["buttonName"].y = height 
      end 
    end 
  end 

  def updatePreviewBox
    return if !@previewShow
    if @curLocName == pbGetMapLocation(@mapX, @mapY)
      getLocationInfo if @mode == 0 
      height = @sprites["previewBox"].height
      if @mode == 0
        @sprites["previewBox"].y = (Graphics.height - 32) - height
        changePreviewBoxAndArrow(height)
      elsif @mode == 2
        @sprites["previewBox"].y = (32 - @sprites["previewBox"].height) + height 
        changePreviewBoxAndArrow(height)
      end
      if @mode == 0
        @sprites["locationDash"].visible = true if @locationDash
        @sprites["locationText"].visible = true 
        @sprites["locationIcon"].visible = true if @locationIcon
      end 
      getPreviewWeather 
    else 
      hidePreviewBox
    end 
  end 

  def hidePreviewBox
    return false if !@previewShow && !@previewHide
    @sprites["previewBox"].visible = false
    @sprites["locationText"].bitmap.clear if @sprites["locationText"]
    if @locationIcon
      @sprites["locationIcon"].bitmap.clear 
      @sprites["locationIcon"].visible = false 
    end
    if @locationDash
      @sprites["locationDash"].bitmap.clear 
      @sprites["locationDash"].visible = false
    end
    clearPreviewBox
    if @previewMode == 0
      @sprites["previewBox"].y = (Graphics.height - 32)
      @sprites["downArrow"].y = (BOX_BOTTOM_LEFT && (@sprites["buttonPreview"].x + @sprites["buttonPreview"].width) > (Graphics.width / 2)) || (BOX_BOTTOM_RIGHT && @sprites["buttonPreview"].x < (Graphics.width / 2)) ? (Graphics.height - (44 + @sprites["buttonPreview"].height)) : (Graphics.height - 60)
      if BOX_BOTTOM_LEFT || (BOX_BOTTOM_RIGHT && @sprites["previewBox"].width > @sprites["buttonPreview"].y)
        @sprites["buttonPreview"].y = (Graphics.height - (22 + @sprites["buttonPreview"].height))
        @sprites["buttonName"].y = 0
      end 
    elsif @previewMode == 2
      @sprites["previewBox"].y = 32 - @sprites["previewBox"].height
      @sprites["upArrow"].y = (BOX_TOP_LEFT && (@sprites["buttonPreview"].x + @sprites["buttonPreview"].width) > (Graphics.width / 2)) || (BOX_TOP_RIGHT && @sprites["buttonPreview"].x < (Graphics.width / 2)) ? @sprites["buttonPreview"].height : 16
      if BOX_TOP_RIGHT || BOX_TOP_RIGHT
        @sprites["buttonPreview"].y = 22
        @sprites["buttonName"].y = 0
      end 
    end
    @previewShow = false
    @previewHide = false
    @locationIcon = false
    @locationDash = false
    getPreviewWeather
    return true
  end

  def clearPreviewBox
    return if @sprites["previewBox"].visible == false
    @sprites["locationText"].bitmap.clear if @sprites["locationText"]
    @sprites["modeName"].visible = true
  end 
end 