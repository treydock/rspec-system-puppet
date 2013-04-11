require 'spec_helper_system'

describe "basic tests:" do
  it "check puppet_install works" do
    puppet_install()
  end

  it 'check puppet_resource returns an exit code of 0' do
    puppet_resource('user') do |r|
      r[:exit_code].should == 0
      r[:stderr].should == ''
    end
  end
end
