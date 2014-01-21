class AccessScope

  attr_reader :type, :right, :id

  def initialize(str)
    parts = str.split(':')
    @type, @right, @id = parts[0].to_sym,
      parts[1].to_sym, parts[2] if 3 == parts.size
  end

  def resource
    @resource =
      case type
      when :camera
        Camera.by_exid(id)
      when :cameras
        User.by_login(id)
      end
  end

  def valid?
    nil != resource
  end

  def to_s
    [@type, @right, @id].join(':')
  end

end

