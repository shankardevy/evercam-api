def renders_with_ok(result=subject)
  assert_equal 200, result.status
end

def temp_redirects_to(path, result=subject)
  assert_equal 302, result.status

  expect_uri = URI.join('http://example.org', path)
  actual_uri = URI.parse(result.location)

  assert_equal actual_uri, expect_uri
end

def sets_session_key(key, val, result=subject)
  assert_equal last_request.session[key], val
end

def clears_session_key(key, result=subject)
  assert_nil last_request.session[key]
end

def shows_an_error(result=subject)
  shows_a_flash(:error, result)
end

def shows_a_flash(key, result=subject)
  code = result.status

  case code
  when 301, 302
    flash = last_request.session[:flash] || {}
    message = flash[key] || ''
  when 200
    markup = Nokogiri::HTML(last_response.body)
    message = markup.css("div.alert-#{key}").text
  end

  assert_not_empty message
end

