require 'spec_helper_acceptance'

describe 'gitlab_ci_runner class' do
  context 'default parameters' do
    it 'idempotently with no errors' do
      pp = <<-EOS
      include gitlab_ci_runner
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe package('gitlab-runner') do
      it { is_expected.to be_installed }
    end

    describe service('gitlab-runner') do
      it { is_expected.to be_running }
      it { is_expected.to be_enabled }
    end

    describe file('/etc/gitlab-runner/config.toml') do
      it { is_expected.to contain '# MANAGED BY PUPPET' }
    end
  end

  context 'concurrent => 20' do
    it 'idempotently with no errors' do
      pp = <<-EOS
      class { 'gitlab_ci_runner':
        concurrent => 20,
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/gitlab-runner/config.toml') do
      it { is_expected.to contain 'concurrent = 20' }
    end
  end

  context 'log_level => error' do
    it 'idempotently with no errors' do
      pp = <<-EOS
      class { 'gitlab_ci_runner':
        log_level => 'error',
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/gitlab-runner/config.toml') do
      it { is_expected.to contain 'log_level = "error"' }
    end
  end

  context 'log_format => text' do
    it 'idempotently with no errors' do
      pp = <<-EOS
      class { 'gitlab_ci_runner':
        log_format => 'text',
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/gitlab-runner/config.toml') do
      it { is_expected.to contain 'log_format = "text"' }
    end
  end

  context 'check_interval => 42' do
    it 'idempotently with no errors' do
      pp = <<-EOS
      class { 'gitlab_ci_runner':
        check_interval => 42,
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/gitlab-runner/config.toml') do
      it { is_expected.to contain 'check_interval = 42' }
    end
  end

  context 'sentry_dsn => https://123abc@localhost/1' do
    it 'idempotently with no errors' do
      pp = <<-EOS
      class { 'gitlab_ci_runner':
        sentry_dsn => 'https://123abc@localhost/1',
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/gitlab-runner/config.toml') do
      it { is_expected.to contain 'sentry_dsn = "https://123abc@localhost/1"' }
    end
  end

  context 'listen_address => localhost:9252' do
    it 'idempotently with no errors' do
      pp = <<-EOS
      class { 'gitlab_ci_runner':
        listen_address => 'localhost:9252',
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/gitlab-runner/config.toml') do
      it { is_expected.to contain 'listen_address = "localhost:9252"' }
    end
  end

  context 'with runners' do
    # We run a sidecar Gitlab container next to acceptance tests.
    # See puppet-gitlab_ci_runner/scripts/start-gitlab.sh
    let(:registrationtoken) do
      File.read(File.expand_path('~/INSTANCE_TOKEN')).chomp
    end

    it 'idempotently with no errors' do
      pp = <<-EOS
      class { 'gitlab_ci_runner':
        manage_docker   => false,
        runners         => {
          test_runner => {}
        },
        runner_defaults => {
          url                => 'http://gitlab',
          registration-token => '#{registrationtoken}',
          executor           => 'shell',
        }
      }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe package('gitlab-runner') do
      it { is_expected.to be_installed }
    end

    describe service('gitlab-runner') do
      it { is_expected.to be_running }
      it { is_expected.to be_enabled }
    end

    it 'registered the runner' do
      authtoken = shell("grep 'token = ' /etc/gitlab-runner/config.toml | cut -d '\"' -f2").stdout
      shell("/usr/bin/env curl -X POST --form 'token=#{authtoken}' http://gitlab/api/v4/runners/verify") do |r|
        expect(r.stdout).to eq('200')
      end
    end
  end
end
