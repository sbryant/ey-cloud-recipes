if ['util', 'app', 'app_master'].include?(node[:instance_role])
  remote_file "/data/SeattlesBest/shared/config/env.custom" do
    owner "deploy"
    group "deploy"
    mode 0644
    source "unicorn.rb"
    backup false
    action :create
  end
end
