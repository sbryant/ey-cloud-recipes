#
# Cookbook Name:: system
# Recipe:: default
#
# create a yaml file containing instance info, used in rake tasks
if ['app_master', 'app', 'util'].include? node[:instance_role]
  require 'json'
  ruby_block "create-instances-yaml" do
    block do
      json = File.new('/etc/chef/dna.json', 'r').read
      dna = JSON.parse(json)
      utility_instances = dna['engineyard']['environment']['instances']
      File.open('/data/homedirs/deploy/instances.yml', 'wb') do |f|
        f.write(utility_instances.to_yaml)
      end
    end
  end
end
