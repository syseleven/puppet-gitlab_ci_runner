require_relative '../../../puppet_x/gitlab/runner.rb'
require 'fileutils'

# A function that registers a Gitlab runner on a Gitlab instance, if it doesn't already exist,
# _and_ saves the retrived authentication token to a file. This is helpful for Deferred functions.
Puppet::Functions.create_function(:'gitlab_ci_runner::register_to_file') do
  # @param url The url to your Gitlab instance. Please only provide the host part (e.g https://gitlab.com)
  # @param regtoken Registration token.
  # @param runner_name The name of the runner. Use as identifier for the retrived auth token.
  # @param filename The filename where the token should be saved.
  # @param additional_options A hash with all additional configuration options for that runner
  # @return [String] Returns the authentication token
  # @example Using it as a Deferred function
  #   gitlab_ci_runner::runner { 'testrunner':
  #     config               => {
  #       'url'              => 'https://gitlab.com',
  #       'token'            => Deferred('gitlab_ci_runner::register_runner_to_file', [$config['url'], $config['registration-token'], 'testrunner'])
  #       'executor'         => 'shell',
  #     },
  #   }
  #
  dispatch :register_to_file do
    # We use only core data types because others aren't synced to the agent.
    param 'String[1]', :url
    param 'String[1]', :regtoken
    param 'String[1]', :runner_name
    optional_param 'Hash', :additional_options
    optional_param 'String[1]', :filename
    return_type 'String[1]'
  end

  def register_to_file(url, regtoken, runner_name, additional_options = {}, filename = "/etc/gitlab-runner/auth-token-#{runner_name}")
    if File.exist?(filename)
      authtoken = File.read(filename).strip
    else
      begin
        authtoken = PuppetX::Gitlab::Runner.register(url, additional_options.merge('token' => regtoken))['token']

        # If this function is used as a Deferred function the Gitlab Runner config dif
        # will not exist on the first run, because the package isn't installed yet.
        dirname = File.dirname(filename)
        unless File.exist?(dirname)
          FileUtils.mkdir_p(File.dirname(filename))
          File.chmod(0o700, dirname)
        end

        File.write(filename, authtoken)
        File.chmod(0o400, filename)
      rescue Net::HTTPError => e
        raise "Gitlab runner failed to register: #{e.message}"
      end
    end

    authtoken
  end
end
