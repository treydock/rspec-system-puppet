require 'rspec-system-puppet'

module RSpecSystemPuppet::Helpers
  include RSpecSystem::Helpers
  include RSpecSystem::Log

  # Basic helper to install puppet
  def puppet_install(options = {})
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
      system_run('rpm -ivh http://yum.puppetlabs.com/el/5/products/i386/puppetlabs-release-5-6.noarch.rpm')
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
  end

  # Helper to copy a module onto a node from source
  def puppet_module_install(options)
    # Defaults etc.
    options = {
      :node => rspec_system_node_set.default_node,
      :module_path => "/etc/puppet/modules",
    }.merge(options)

    source = options[:source]
    module_name = options[:module_name]
    module_path = options[:module_path]
    node = options[:node]

    raise "Must provide :source and :module_name parameters" unless source && module_name

    log.info("Now transferring module onto node")
    system_rcp(:sp => source, :d => node, :dp => File.join(module_path, module_name))
  end

  # Runs puppet resource commands
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
      yield(*result)
    else
      result
    end
  end
end
