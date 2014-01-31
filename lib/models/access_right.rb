class AccessRight < Sequel::Model

  PARTS = [:group, :right, :scope]

  many_to_one :token, class: 'AccessToken'

  # Splits a string representation of an
  # access right into a new instance
  def self.split(val)
    self.new(Hash[PARTS.zip(val.split(':'))])
  end

  # Returns the resource which is represented
  # by the scope parameter of this right
  def resource
    @resource =
      case group
      when /^camera$/i
        Camera.by_exid(scope)
      end
  end

  # Whether or not the group this access right
  # represents is specific to a single resource
  # or covers all resources owned by a user
  def generic?
    ['cameras'].include?(group)
  end

  # Whether or not this right is valid, true
  # only when generic or the resource exists
  def valid?
    super && (generic? || resource)
  end

  # Returns a basic string representation of this
  # right in the format group:right:scope
  def to_s
    [group, right, scope].join(':')
  end

end

