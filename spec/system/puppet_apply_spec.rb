require 'spec_helper_system'

describe "helper puppet_apply" do
  it 'should print notice message to stdout' do
    puppet_apply('notice("foo")') do |r|
      r.stdout.should =~ /foo/
      r.stderr.should be_empty
      r.exit_code.should be_zero
    end
  end

  it 'should run as root' do
    puppet_apply(:code => 'notice("user ${::id}")') do |r|
      r.stdout.should =~ /user root/
      r.stderr.should be_empty
      r.exit_code.should be_zero
    end
  end

  it 'in debug mode should return notice message to stdout and Debug: labels' do
    puppet_apply(:code => 'notice("foo")', :debug => true) do |r|
      r.stdout.should =~ /foo/
      r.stdout.should =~ /Debug:/
      r.stderr.should be_empty
      r.exit_code.should be_zero
    end
  end

  it 'with trace off it should work normally' do
    puppet_apply(:code => 'notice("foo")', :trace => false) do |r|
      r.stdout.should =~ /foo/
      r.stderr.should be_empty
      r.exit_code.should be_zero
    end
  end

  context 'test as a subject' do
    context puppet_apply 'notice("foo")' do
      its(:stdout) { should =~ /foo/ }
      its(:stderr) { should be_empty }
      its(:exit_code) { should be_zero }
    end
  end

  context 'when running as a different user' do
    let(:user) { "vagrant" }
    it 'should work normally' do
      puppet_apply(:code => 'notice("user ${::id}")', :user => user) do |r|
        r.stdout.should =~ /user #{user}/
        r.stderr.should eq("")
        r.exit_code.should be_zero
      end
    end
    context 'should use the user home' do
      subject { puppet_apply(:code => "exec { '/bin/pwd': logoutput => true, }", :user => user) }
      its(:stdout) { should =~ %r{returns: /home/#{user}} }
      its(:stderr) { should eq("") }
      its(:exit_code) { should eq(2) }
    end
  end

end
