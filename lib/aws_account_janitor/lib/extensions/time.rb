class Time
  def ago(days)
    self - days * 86400
  end
end
