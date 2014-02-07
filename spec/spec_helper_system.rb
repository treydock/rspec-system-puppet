require 'rspec-system/spec_helper'
require 'rspec-system-puppet/spec_helper'

def proj_root
  Pathname.new(File.join(File.dirname(__FILE__), '..'))
end

RSpec.configure do |c|
end
