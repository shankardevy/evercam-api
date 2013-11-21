require 'nokogiri'

class Rack::MockResponse

  def mime
    content_type.split(';')[0]
  end

  def charset
    content_type.split(';')[1].
      split('=')[1]
  end

  def alerts
    html.css('div.alert')
  end

  def json
    mime == 'application/json' ? JSON.parse(body) :
      (raise Exception, 'response is not json')
  end

  def html
    mime == 'text/html' ? Nokogiri.HTML(body) :
      (raise Exception, 'response is not html')
  end

end

