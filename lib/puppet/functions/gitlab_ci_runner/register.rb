require_relative '../../../puppet_x/gitlab/runner.rb'

Puppet::Functions.create_function(:'gitlab_ci_runner::register') do
  # @summary A function that registers a Gitlab runner on a Gitlab instance
  # @param url The url to your Gitlab instance. Please only provide the host part (e.g https://gitlab.com)
  # @param token Registration token.
  # @param additional_options A hash with all additional configuration options for that runner
  # @return Struct[{ id => Integer[1], token => String[1], }]
  dispatch :register do
    param 'Stdlib::HTTPUrl', :url
    param 'String[1]', :token
    optional_param 'Gitlab_ci_runner::Register', :additional_options
    return_type 'Struct[{ id => Integer[1], token => String[1], }]'
  end

  def register(url, token, additional_options = {})
    PuppetX::Gitlab::Runner.register(url, additional_options.merge('token' => token))
  rescue Net::HTTPError => e
    raise "Gitlab runner failed to register: #{e.message}"
  end
end
