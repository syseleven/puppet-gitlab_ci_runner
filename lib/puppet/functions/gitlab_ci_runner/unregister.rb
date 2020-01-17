require_relative '../../../puppet_x/gitlab/runner.rb'

Puppet::Functions.create_function(:'gitlab_ci_runner::unregister') do
  # @summary A function that unregisters a Gitlab runner from a Gitlab instance
  # @param url The url to your Gitlab instance. Please only provide the host part (e.g https://gitlab.com)
  # @param token Runners authentication token.
  # @return Struct[{ status => Enum['success'], }]
  dispatch :register do
    param 'Stdlib::HTTPUrl', :url
    param 'String[1]', :token
    return_type "Struct[{ status => Enum['success'], }]"
  end

  def register(url, token)
    PuppetX::Gitlab::Runner.unregister(url, token: token)
    { 'status' => 'success' }
  rescue Net::HTTPError => e
    raise "Gitlab runner failed to unregister: #{e.message}"
  end
end
