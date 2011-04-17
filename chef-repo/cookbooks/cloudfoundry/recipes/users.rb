home_dir = "/home/#{node[:cloudfoundry][:user][:uid]}"
  
group node[:cloudfoundry][:user][:gid]

user node[:cloudfoundry][:user][:uid] do
  gid node[:cloudfoundry][:user][:gid]
  shell "/bin/bash"
  home "#{home_dir}"
  system true
end

group 'rvm' do
  members node[:cloudfoundry][:user][:uid]
  append true
end

directory "#{home_dir}/.ssh" do
  owner node[:cloudfoundry][:user][:uid]
  group node[:cloudfoundry][:user][:gid]
  recursive true
  mode "0700"
end

template "#{home_dir}/.ssh/authorized_keys" do
  source "authorized_keys.erb"
  owner node[:cloudfoundry][:user][:uid]
  group node[:cloudfoundry][:user][:gid]
  mode "0600"
  variables :ssh_keys => node[:cloudfoundry][:user][:ssh_keys]
end