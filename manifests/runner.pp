# @summary This configures a Gitlab CI runner.
#
# @example Add a simple runner
#   gitlab_ci_runner::runner { 'testrunner':
#     config               => {
#       'url'              => 'https://gitlab.com',
#       'token'            => '123456789abcdefgh', # Note this is different from the registration token used by `gitlab-runner register`
#       'executor'         => 'shell',
#     },
#   }
#
# @example Add a autoscaling runner with DigitalOcean as IaaS
#   gitlab_ci_runner::runner { 'autoscale-runner':
#     config => {
#      url      => 'https://gitlab.com',
#      token    => 'RUNNER_TOKEN', # Note this is different from the registration token used by `gitlab-runner register`
#      name     => 'autoscale-runner',
#      executor => 'docker+machine',
#      limit    => 10,
#      docker   => {
#        image => 'ruby:2.6',
#      },
#      machine  => {
#        OffPeakPeriods   => [
#          '* * 0-9,18-23 * * mon-fri *',
#          '* * * * * sat,sun *',
#        ],
#        OffPeakIdleCount => 1,
#        OffPeakIdleTime  => 1200,
#        IdleCount        => 5,
#        IdleTime         => 600,
#        MaxBuilds        => 100,
#        MachineName      => 'auto-scale-%s',
#        MachineDriver    => 'digitalocean',
#        MachineOptions   => [
#          'digitalocean-image=coreos-stable',
#          'digitalocean-ssh-user=core',
#          'digitalocean-access-token=DO_ACCESS_TOKEN',
#          'digitalocean-region=nyc2',
#          'digitalocean-size=4gb',
#          'digitalocean-private-networking',
#          'engine-registry-mirror=http://10.11.12.13:12345',
#        ],
#      },
#      cache    => {
#        'Type' => 's3',
#        s3     => {
#          ServerAddress => 's3-eu-west-1.amazonaws.com',
#          AccessKey     => 'AMAZON_S3_ACCESS_KEY',
#          SecretKey     => 'AMAZON_S3_SECRET_KEY',
#          BucketName    => 'runner',
#          Insecure      => false,
#        },
#      },
#     },
#   }
#
# @param config
#   Hash with configuration options.
#   See https://docs.gitlab.com/runner/configuration/advanced-configuration.html for all possible options.
#   If you omit the 'name' configuration, we will automatically use the $title of this define class.
#
define gitlab_ci_runner::runner (
  Hash $config,
) {
  include gitlab_ci_runner

  $config_path       = $gitlab_ci_runner::config_path
  # $serverversion is empty on 'puppet apply' runs. Just use clientversion.
  $_serverversion    = getvar('serverversion') ? {
    undef   => $clientversion,
    default => $serverversion,
  }
  $supports_deferred = (versioncmp($clientversion, '6.0') >= 0 and versioncmp($_serverversion, '6.0') >= 0)

  # Use title parameter if config hash doesn't contain one.
  $_config     = $config['name'] ? {
    undef   => $config + { name => $title },
    default => $config,
  }

  # Puppet < 6 doesn't include the Deferred type and will therefore
  # fail with an compilation error while trying to load the type
  if $supports_deferred {
    if $_config['registration-token'] {
      $deferred_call = Deferred('gitlab_ci_runner::register_to_file', [ $_config['url'], $_config['registration-token'], $_config['name']])

      # Remove registration-token and add a 'token' key to the config with a Deferred function to get it.
      $__config = ($_config - 'registration-token') + { 'token' => $deferred_call }
    } else {
      $__config = $_config
    }

    $content = $__config['token'] =~ Deferred ? {
      true  => Deferred('gitlab_ci_runner::to_toml', [{ runners => [ $__config ], }]),
      false => gitlab_ci_runner::to_toml({ runners => [ $__config ], }),
    }
  } else {
    $content = gitlab_ci_runner::to_toml({ runners => [ $_config ], })
  }

  concat::fragment { "${config_path} - ${title}":
    target  => $config_path,
    order   => 2,
    content => $content,
  }
}
