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

RSpec::Matchers.define :have_keys do |*keys|
  match do |actual|
    keys.all? { |k| actual.keys.include?(k) }
  end
end

RSpec::Matchers.define :be_around_now do
  match do |actual|
    1 >= (actual - Time.now)
  end
end

RSpec::Matchers.define :be_dataset do |expected|
  match do |actual|
    expected.all? do |m|
      actual.include?(m)
    end &&
    actual.all? do |m|
      expected.include?(m)
    end
  end
end

