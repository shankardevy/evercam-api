require 'nokogiri'

class Rack::MockResponse

  def alerts
    markup = Nokogiri::HTML(body)
    markup.css('div.alert')
  end

end

