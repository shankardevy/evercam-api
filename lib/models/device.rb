class Device < Sequel::Model
  one_to_many :streams
end

