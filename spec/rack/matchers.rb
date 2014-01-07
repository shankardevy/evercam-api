RSpec::Matchers.define :have_css do |css|
  match do |actual|
    false == actual.css(css).empty?
  end
end

RSpec::Matchers.define :have_fragment do |fragments|
  match do |actual|
    uri = URI.parse(actual)
    ary = URI.decode_www_form(uri.fragment)

    act = Hash[*ary.flatten]
    fragments.all? { |k,v| act[k.to_s] == v.to_s }
  end
end

RSpec::Matchers.define :include_keys do |*keys|
  match do |actual|
    keys.all? { |k| actual.keys.include?(k) }
  end
end

