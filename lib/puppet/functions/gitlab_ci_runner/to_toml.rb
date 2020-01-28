require 'toml-rb'
# @summary Convert a data structure and output to TOML. This function requires the 'toml-rb' gem.
#
# @example How to output TOML to a file
#   file { '/tmp/config.toml':
#     ensure  => file,
#     content => to_toml($myhash),
#   }
#
Puppet::Functions.create_function(:'gitlab_ci_runner::to_toml') do
  # @param data Data structure which needs to be converted into TOML
  # @return [String] Converted data as TOML string
  dispatch :to_toml do
    required_param 'Hash', :data
    return_type 'String'
  end

  def to_toml(data)
    TomlRB.dump(data)
  end
end
