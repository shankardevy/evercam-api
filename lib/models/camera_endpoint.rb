class CameraEndpoint < Sequel::Model

  many_to_one :camera

  def to_s
    "#{scheme}://#{host}:#{port}"
  end

end

