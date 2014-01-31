class AccessRight < Sequel::Model

  PARTS = [:group, :right, :scope]

  many_to_one :token, class: 'AccessToken'

  # Splits a string representation of an
  # access right into a new instance
  def self.split(val)
    self.new(Hash[PARTS.zip(val.split(':'))])
  end

end

