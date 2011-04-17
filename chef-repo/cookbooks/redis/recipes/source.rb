#
# Cookbook Name:: redis
# Recipe:: source
#
# Author:: Gerhard Lazu (<gerhard.lazu@papercavalier.com>)
#
# Copyright 2010, Paper Cavalier, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "build-essential"

user "redis" do
  comment "Redis Administrator"
  system true
  shell "/bin/false"
end

[node[:redis][:dir], "#{node[:redis][:dir]}/bin", node[:redis][:datadir]].each do |dir|
  directory dir do
    owner "redis"
    group "redis"
    mode 0755
    recursive true
  end
end

unless `ps -A -o command | grep "[r]edis"`.include?(node[:redis][:version])
  # ensuring we have this directory
  directory "/opt/src"

  remote_file "/opt/src/redis-#{node[:redis][:version]}.tar.gz" do
    source node[:redis][:source]
    checksum node[:redis][:checksum]
    action :create_if_missing
  end

  bash "Compiling Redis #{node[:redis][:version]} from source" do
    cwd "/opt/src"
    code <<-EOH
      tar zxf redis-#{node[:redis][:version]}.tar.gz
      cd redis-#{node[:redis][:version]} && make
    EOH
  end

  move_bins = []
  node[:redis][:bins].each { |bin|
    unless File.exists?("#{node[:redis][:dir]}/bin/#{bin}") && File.read("#{node[:redis][:dir]}/bin/#{bin}") == File.read("/opt/src/redis-#{node[:redis][:version]}/src/#{bin}")
      move_bins << "cp src/#{bin} #{node[:redis][:dir]}/bin/"
    end
  }
  unless move_bins.size == 0
    bash "set_up_redis" do
      cwd "/opt/src/redis-#{node[:redis][:version]}"
      code <<-EOH
        #{move_bins.join("; ")}
      EOH
    end
  end

  environment = File.read('/etc/environment')
  unless environment.include? node[:redis][:dir]
    File.open('/etc/environment', 'w') { |f| f.puts environment.gsub(/PATH="/, "PATH=\"#{node[:redis][:dir]}/bin:") }
  end
end

file node[:redis][:logfile] do
  owner "redis"
  group "redis"
  mode 0644
  action :create_if_missing
  backup false
end

template node[:redis][:config] do
  source "redis.conf.erb"
  owner "redis"
  group "redis"
  mode 0644
  backup false
end

template "/etc/init.d/redis" do
  source "redis.init.erb"
  mode 0755
  backup false
end

[File.join(node[:redis][:datadir], node[:redis][:appendfilename]), 
 File.join(node[:redis][:datadir], node[:redis][:dbfilename])].each do |data_file|
  file data_file do
    owner "redis"
    group "redis"
    mode 0644
    backup false
  end
end

service "redis" do
  supports :start => true, :stop => true, :restart => true
  action [:enable, :start]
  subscribes :restart, resources(:template => node[:redis][:config])
  subscribes :restart, resources(:template => "/etc/init.d/redis")
end
