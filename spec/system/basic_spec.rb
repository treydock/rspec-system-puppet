require 'spec_helper_system'

describe "basic tests:" do
  it "check puppet_install works" do
    puppet_install()
  end

  it 'facter domain should return something valid' do
    system_run("facter domain") do |r|
      r[:stdout].should =~ /[a-z]+/
      r[:stderr].should == ''
      r[:exit_code].should == 0
    end
  end

  it 'facter fqdn should return something valid' do
    system_run("facter fqdn") do |r|
      r[:stdout].should =~ /vm/
      r[:stderr].should == ''
      r[:exit_code].should == 0
    end
  end

  it 'check puppet_resource returns an exit code of 0' do
    puppet_resource('user') do |r|
      r[:stderr].should == ''
      r[:exit_code].should == 0
    end
  end

  it 'check puppet apply with just a notice' do
    puppet_apply('notice("foo")') do |r|
      r[:stdout].should =~ /foo/
      r[:stderr].should == ''
      r[:exit_code].should == 0
    end
  end
end
