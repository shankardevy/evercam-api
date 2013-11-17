def renders_with_ok(result=subject)
  assert_equal 200, result.status
end

def temp_redirects_to(path, result=subject)
  expect_uri = URI.join('http://example.org', path)
  actual_uri = URI.parse(result.location)

  assert_equal 302, result.status
  assert_equal actual_uri, expect_uri
end

def clears_session_key(key, result=subject)
  assert_nil last_request.session[key]
end

