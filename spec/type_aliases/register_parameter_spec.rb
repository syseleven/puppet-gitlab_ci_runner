require 'spec_helper'

describe 'Gitlab_ci_runner::Register_parameter' do
  %w[description info active locked run_untagged run-untagged tag_list tag-list access_level access-level maximum_timeout maximum-timeout].each do |value|
    it { is_expected.to allow_value(value) }
  end

  [:undef, 1, '', 'leave-runner', 'docker-host', true, false, 42]. each do |value|
    it { is_expected.not_to allow_value(value) }
  end
end
