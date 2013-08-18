2.2.0
=====

This feature release provides the ability to pass a :puppet setting to the facter helper, allowing you to return puppet facts when querying. At the moment the setting is false by default.

#### Detailed Changes

* Add puppet option to facter helper (Trey Dockendorf)

2.1.0
=====

This feature release provides some minor bug fixes, improved docuemntation and features as outlined below.

#### Detailed Changes

* Remove coupling with Bundler (Hunter Haugen)
* Add module_path option to puppet_apply helper (Dominic Cleal)
* Pass node option when creating the host alias for puppet (Trey Dockendorf)

2.0.0
=====

This major release adds rspec-system 2 support for using helpers in a subject. So now, all rspec-system-puppet helpers can be used as a normal helper or in a subject like so:

    describe 'puppet tests' do
      pp = 'notice("foo")'

      context puppet_apply(pp) do
        its(:stdout) { should =~ /foo/ }
        its(:stderr) { should be_empty }
        its(:exit_code) { should be_zero }
      end
    end

You can also refresh a helper in the middle of a test, here is a neat way to test idempotency:

    describe 'puppet tests' do
      it 'test that code is idempotent' do
        pp = "include myclass"

        puppet_apply(pp) do |r|
          r.stderr.should be_empty
          r.exit_code.should_not == 1
          r.refresh                    # this re-runs the puppet code
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end
      end
    end

#### Detailed Changes

* rspec-system 2 helpers (Ken Barber)
