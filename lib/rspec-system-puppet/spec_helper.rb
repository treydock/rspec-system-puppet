require 'rspec-system-puppet/helpers'

include RSpecSystemPuppet::Helpers

RSpec.configure do |c|
  c.include RSpecSystemPuppet::Helpers

  c.add_setting :rs_puppet_repo_base,
    :default => ENV["RS_PUPPET_REPO_BASE"] || osfamily_repo_base(node.facts['osfamily'])
end
