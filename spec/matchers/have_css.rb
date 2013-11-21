RSpec::Matchers.define :have_css do |css|
  match do |actual|
    false == actual.css(css).empty?
  end
end

