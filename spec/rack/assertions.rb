def renders_with_ok(result)
  assert_equal 200, result.status
end

def temp_redirects_to(uri, result)
  assert_equal 302, result.status
  assert_equal "http://example.org/#{uri}", result.location
end

