require 'spec_helper'

describe 'Gitlab_ci_runner::Register' do
  [
    {},
    {description: 'foo'},
    {info: {foo: 'bar'}},
    {active: true},
    {active: false},
    {locked: true},
    {locked: false},
    {run_untagged: true},
    {run_untagged: false},
    {tag_list: ['foo', 'bar']},
    {access_level: 'not_protected'},
    {access_level: 'ref_protected'},
    {maximum_timeout: 1},
  ].each do |value|
    it { is_expected.to allow_value(value) }
  end

  [:undef, 1, '', 'leave-runner', 'docker-host', true, false, 42]. each do |value|
    it { is_expected.not_to allow_value(value) }
  end
end
