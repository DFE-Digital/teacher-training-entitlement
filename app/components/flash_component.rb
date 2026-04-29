class FlashComponent < BaseComponent
  def initialize(flash:)
    @flash = flash
  end

  def flash_title
    if hashed_flash?
      @flash[flash_key][:title]
    elsif success?
      "Success"
    elsif notice?
      "Important"
    elsif error? || alert?
      "Error"
    end
  end

  def flash_message
    if hashed_flash?
      @flash[flash_key][:message]
    else
      @flash[flash_key]
    end
  end

private

  def flash_key
    %i[success notice alert error].each do |key|
      return key if @flash[key].present?
    end
  end

  def success?
    @flash[:success].present?
  end

  def notice?
    @flash[:notice].present?
  end

  def error?
    @flash[:error].present?
  end

  def alert?
    @flash[:alert].present?
  end

  def hashed_flash?
    @flash[flash_key].is_a?(Hash)
  end
end
