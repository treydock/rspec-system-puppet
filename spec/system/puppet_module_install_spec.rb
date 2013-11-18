require 'spec_helper_system'

describe "helper puppet_module_install" do
  it 'should return no errors when including a class' do
    pp = <<-EOS.gsub(/^\s{6}/, '')
      class { 'mymodule':
        param1 => 'bar',
      }
    EOS
    puppet_apply(pp) do |r|
      r.stdout.should =~ /Param1: bar/
      r.stderr.should be_empty
      r.exit_code.should be_zero
    end
  end

  it 'shoud not copy skipped files' do
    module_path = proj_root + 'spec' + 'fixtures' + 'skip_module'
    puppet_module_install(:source => module_path, :module_name => 'skip_module', :skip => ['skip_me.txt'])
    shell 'ls /etc/puppet/modules/skip_module/skip_me.txt' do |r|
      r.exit_code.should equal(2)
      r.stderr.should =~ /.*No such file or directory.*/
    end
  end
end
