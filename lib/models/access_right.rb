class AccessRight < Sequel::Model

  # Right constants.
  SNAPSHOT                   = 'snapshot'.freeze
  VIEW                       = 'view'.freeze
  EDIT                       = 'edit'.freeze
  DELETE                     = 'delete'.freeze
  LIST                       = "list".freeze
  GRANT                      = 'grant'.freeze
  BASE_RIGHTS                = [SNAPSHOT, VIEW, EDIT, DELETE, LIST]
  ALL_RIGHTS                 = BASE_RIGHTS + [GRANT]
  PUBLIC_RIGHTS              = [SNAPSHOT, LIST]

  # Status constants.
  ACTIVE                     = 1
  DELETED                    = -1
  ALL_STATUSES               = [ACTIVE, DELETED]

  many_to_one :token, class: 'AccessToken'
  many_to_one :camera
  many_to_one :grantor, class: 'User', key: :grantor_id

  # Returns a basic string representation of an AccessRight.
  def to_s
    [camera_id, token_id, right].join(':')
  end

  # Validates the objects values. Implicitly called before save.
  def validate
    super
    errors.add(:token_id, "is not set") if !token_id
    errors.add(:camera_id, "is not set") if !camera_id
    errors.add(:status, "is invalid") if !ALL_STATUSES.include?(status)
    if !BASE_RIGHTS.include?(right)
      match = /^grant~(.+)$/.match(right)
      if match
        errors.add(:right, "is invalid") if !BASE_RIGHTS.include?(match[1])
      else
        errors.add(:right, "is invalid")
      end
    end
  end

  # Returns an AccessRightSet for a given resource and token combination.
  def self.rights_for(resource, token)
    AccessRightSet.new(resource, token.target)
  end

  def self.valid_right_name?(name)
    result = BASE_RIGHTS.include?(name)
    if !result
      match = /^grant~(.+)$/.match(name)
      result = BASE_RIGHTS.include?(match[1]) if match
    end
    result
  end
end

