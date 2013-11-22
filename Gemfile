source 'https://rubygems.org'

def location_for(place, fake_version = nil)
  mdata = /^(git:[^#]*)(#(.*))?/.match(place)
  if mdata
    [fake_version, { :git => mdata[1], :branch => mdata[3] || 'master' }].compact
  elsif mdata = /^file:\/\/(.*)/.match(place)
    ['>= 0', { :path => File.expand_path(mdata[1]) }]
  else
    [place, { :require => false }]
  end
end

# This allows us to test against master revisions of rspec-system
rsversion = ENV['GEM_RS_VERSION']
if rsversion
  gem 'rspec-system', *location_for(rsversion)
end

gemspec

group :development, :test do
  gem 'rake'
  gem 'mocha', :require => 'mocha/api'
end

group :development do
  gem 'yard'
  gem 'redcarpet'
end
