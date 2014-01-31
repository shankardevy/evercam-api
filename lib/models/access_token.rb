class AccessToken < Sequel::Model

  plugin :after_initialize

  many_to_one :grantor, class: 'User'
  many_to_one :grantee, class: 'Client'

  one_to_many :rights, class: 'AccessRight',
    key: :token_id

  # Finds the token with a matching request
  # key string or nil if none exist
  def self.by_request(val)
    first(request: val)
  end

  # Sets up a new token with a randomly generated
  # request key which expires one hour from now
  def after_initialize
    self.request ||= SecureRandom.hex(16)
    self.expires_at ||= Time.now + 3600
    self.is_revoked ||= false
    super
  end

  # Determines the number of seconds until this
  # token expires (zero if already expired)
  def expires_in
    seconds = expires_at - Time.now
    seconds > 0 ? seconds.to_i : 0
  end

  # Whether or not this token is still valid
  # (i.e. neither expired nor revoked)
  def is_valid?
    false == is_revoked? &&
      Time.now <= self.expires_at
  end

  # Determines who the beneficiary of the
  # rights associated with this token is
  def grantee
    super || grantor
  end

  # Adds a new access right to this token
  # if it does not already exist
  def grant(name)
    add_right(
      where_right(name)
    ) unless includes?(name)
  end

  # Removes an access right from this token
  # if it exists otherwise does nothing
  def revoke(name)
    rights_dataset.where(
      where_right(name)).delete
  end

  # Whether or not this token includes a
  # particular access right
  def includes?(name)
    1 == rights_dataset.where(
      where_right(name)).count
  end

  private

  def where_right(name)
    AccessRight.split(name).values
  end

end

