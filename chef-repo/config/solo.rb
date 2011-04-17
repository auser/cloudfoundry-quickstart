cookbook_path "/etc/chef/cookbooks"
log_level :debug
file_store_path File.join(File.dirname(__FILE__), '..')
file_cache_path File.join(File.dirname(__FILE__), '..')
Chef::Log::Formatter.show_time = false
role_path "/etc/chef/roles"
