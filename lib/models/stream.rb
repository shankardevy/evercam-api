class Stream < Sequel::Model
  many_to_one :device
  many_to_one :owner, class: 'User'
end

