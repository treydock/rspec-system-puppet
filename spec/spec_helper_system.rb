require 'rspec-system/spec_helper'
require 'rspec-system-puppet/helpers'

RSpec.configure do |c|
  c.include RSpecSystemPuppet::Helpers
end
