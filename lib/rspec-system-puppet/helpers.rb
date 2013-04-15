require 'rspec-system-puppet'

module RSpecSystemPuppet::Helpers
  include RSpecSystem::Helpers
  include RSpecSystem::Log

  # Basic helper to install puppet
  #
  # @param opts [Hash] a hash of opts
  def puppet_install(opts = {})
    # Grab facts from node
    facts = system_node.facts

    # Remove annoying mesg n from profile, otherwise on Debian we get:
    # stdin: is not a tty which messes with our tests later on.
    if facts['osfamily'] == 'Debian'
      log.info("Remove 'mesg n' from profile to stop noise")
      system_run("sed -i 's/^mesg n/# mesg n/' /root/.profile")
    end

    # Grab PL repository and install PL copy of puppet
    log.info "Starting installation of puppet from PL repos"
    if facts['osfamily'] == 'RedHat'
      if facts['operatingsystem'] == 'Fedora'
        # Fedora testing is probably the best for now
        system_run('sed -i "0,/RE/s/enabled=0/enabled=1/" /etc/yum.repos.d/fedora-updates-testing.repo')
      else
        if facts['operatingsystemrelease'] =~ /^6\./
          system_run('rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-6.noarch.rpm')
        else
          system_run('rpm -ivh http://yum.puppetlabs.com/el/5/products/x86_64/puppetlabs-release-5-6.noarch.rpm')
        end
      end
      system_run('yum install -y puppet')
    elsif facts['osfamily'] == 'Debian'
      system_run("wget http://apt.puppetlabs.com/puppetlabs-release-#{facts['lsbdistcodename']}.deb")
      system_run("dpkg -i puppetlabs-release-#{facts['lsbdistcodename']}.deb")
      system_run('apt-get update')
      system_run('apt-get install -y puppet')
    end

    # Prep modules dir
    log.info("Preparing modules dir")
    system_run('mkdir -p /etc/puppet/modules')

    pp = <<-EOS
host { 'puppet':
  ip => '127.0.0.1',
}
    EOS
    puppet_apply(pp)
  end

  # Basic helper to install a puppet master
  #
  # @param opts [Hash] a hash of opts
  def puppet_master_install
    # Defaults etc.
    opts = {
      :node => rspec_system_node_set.default_node,
    }

    node = opts[:node]

    # Grab facts from node
    facts = system_node(:node => node).facts

    if facts['osfamily'] == 'RedHat'
      system_run(:n => node, :c => 'yum install -y puppet-server')
      system_run(:n => node, :c => 'service puppetmaster start')
    elsif facts['osfamily'] == 'Debian'
      system_run(:n => node, :c => 'apt-get install -y puppetmaster')
      system_run(:n => node, :c => 'service puppetmaster start')
    end
  end

  # Run puppet agent
  #
  # @param opts [Hash] a hash of opts
  # @return [Hash] a hash of results
  # @yield [result] yields result when called as a block
  # @yieldparam result [Hash] a hash containing :exit_code, :stdout and :stderr
  def puppet_agent
    # Defaults etc.
    opts = {
      :node => rspec_system_node_set.default_node,
    }

    node = opts[:node]

    result = system_run(:n => node, :c => 'puppet agent -t --detailed-exitcodes')

    if block_given?
      yield(result)
    else
      result
    end
  end

  # Helper to copy a module onto a node from source
  #
  # @param opts [Hash] a hash of opts
  def puppet_module_install(opts)
    # Defaults etc.
    opts = {
      :node => rspec_system_node_set.default_node,
      :module_path => "/etc/puppet/modules",
    }.merge(opts)

    source = opts[:source]
    module_name = opts[:module_name]
    module_path = opts[:module_path]
    node = opts[:node]

    raise "Must provide :source and :module_name parameters" unless source && module_name

    log.info("Now transferring module onto node")
    system_rcp(:sp => source, :d => node, :dp => File.join(module_path, module_name))
  end

  # Runs puppet resource commands
  #
  # @param opts [Hash] a hash of opts
  def puppet_resource(opts)
    if opts.is_a?(String)
      opts = {:resource => opts}
    end

    # Defaults
    opts = {
      :node => rspec_system_node_set.default_node
    }.merge(opts)

    resource = opts[:resource]
    node = opts[:node]

    raise 'Must provide resource' unless resource

    log.info("Now running puppet resource")
    result = system_run(:n => node, :c => "puppet resource #{resource}")

    if block_given?
      yield(result)
    else
      result
    end
  end

  # Run puppet DSL code directly with `puppet apply`.
  #
  # This takes a string of PuppetDSL code, uploads it to the test server and
  # executes it directly with `puppet apply`.
  #
  # @param opts [Hash, String] a hash of opts, or a string containing the
  #   code to execute with option defaults
  # @option opts [String] :code the Puppet DSL code to execute
  # @option opts [RSpecSystem::Node] :node node to execute DSL on
  # @return [Hash] a hash of results
  # @yield [result] yields result when called as a block
  # @yieldparam result [Hash] a hash containing :exit_code, :stdout and :stderr
  # @example
  #   it "run notice" do
  #     puppet_apply("notice('foo')") do |r|
  #       r[:stdout].should =~ /foo/
  #     end
  #   end
  # @todo Support for custom switches perhaps?
  # @todo The destination path is static, need a good remote random path
  #   generator
  def puppet_apply(opts)
    if opts.is_a?(String)
      opts = {:code => opts}
    end

    # Defaults
    opts = {
      :node => rspec_system_node_set.default_node
    }.merge(opts)

    code = opts[:code]
    node = opts[:node]

    raise 'Must provide code' unless code

    log.info("Copying DSL to remote host")
    file = Tempfile.new('rsp_puppet_apply')
    file.write(code)
    file.close

    remote_path = '/tmp/puppetapply.' + rand(1000000000).to_s
    r = system_rcp(:sp => file.path, :dp => remote_path, :d => node)
    file.unlink

    log.info("Cat file to see contents")
    system_run(:n => node, :c => "cat #{remote_path}")

    log.info("Now running puppet apply")
    result = system_run(:n => node, :c => "puppet apply --detailed-exitcodes #{remote_path}")

    if block_given?
      yield(result)
    else
      result
    end
  end
end
