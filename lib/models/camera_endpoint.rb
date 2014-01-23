require 'ipaddr'

class CameraEndpoint < Sequel::Model

  LOCAL_RANGES = [
    IPAddr.new('127.0.0.0/8')
  ]

  PRIVATE_RANGES = [
    IPAddr.new('192.168.0.0/16'),
    IPAddr.new('172.16.0.0/12'),
    IPAddr.new('10.0.0.0/8')
  ]

  many_to_one :camera

  def local?
    in_range?(LOCAL_RANGES)
  end

  def private?
    in_range?(PRIVATE_RANGES)
  end

  def public?
    !local? && !private?
  end

  def to_s
    "#{scheme}://#{host}:#{port}"
  end

  private

  def in_range?(range)
    return false unless Resolv::IPv4::Regex =~ host
    range.any? { |r| r.include?(host) }
  end

end

