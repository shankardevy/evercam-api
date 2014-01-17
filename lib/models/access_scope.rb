class AccessScope

  def initialize(str)
    @tp, @rt, @id = str.split(':')
  end

  def resource
    case @tp
    when /camera/i
      Camera.by_name(@id)
    when /user/i
      User.by_login(@id)
    else nil
    end
  end

  def right
    @rt
  end

  def valid?
    nil != resource
  end

end

