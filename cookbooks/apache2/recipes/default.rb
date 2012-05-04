
package "apache2-mpm-#{node.apache2.mpm}"


Chef::Config.exception_handlers << ServiceErrorHandler.new("apache2", ".*apache2.*")

service "apache2" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

template "/etc/apache2/apache2.conf" do
  if node.apache2.mpm_config.prefork == "auto"
    mpm_auto = { 
      :prefork => {
        :start => node.cpu.total * 4,
        :min_spare => node.cpu.total * 8,
        :max_spare => node.cpu.total * 16,
        :server_limit => node.cpu.total * 512,
        :max_clients => node.cpu.total * 512,
        :max_request_per_child => node.cpu.total * 1024,
      }
    }
    variables :mpm => mpm_auto, :tuning => node.apache2.tuning
  else 
    variables :mpm => node.apache2.mpm_config, :tuning => node.apache2.tuning
  end
  source "apache2.conf.erb"
  notifies :reload, resources(:service => "apache2")
end

template "/etc/apache2/envvars" do
  source "envvars.erb"
  notifies :reload, resources(:service => "apache2")
end

[
  "/etc/apache2/sites-enabled/000-default",
  "/etc/apache2/sites-available/default",
  "/etc/apache2/sites-available/default-ssl",
  "/etc/apache2/conf.d/security"
  ].each do |f|
  file f do
    action :delete
    notifies :reload, resources(:service => "apache2")
  end
end

node.apache2.modules.each do |m|
  apache2_enable_module m
end

delayed_exec "Remove useless apache2 vhost" do
  block do
    vhosts = find_resources_by_name_pattern(/^\/etc\/apache2\/sites-enabled\/.*\.conf$/).map{|r| r.name}
    Dir["/etc/apache2/sites-enabled/*.conf"].each do |n|
      unless vhosts.include? n
        Chef::Log.info "Removing vhost #{n}"
        File.unlink n
        notifies :reload, resources(:service => "apache2")
      end
    end
  end
end

delayed_exec "Remove useless apache2 modules" do
  block do
    modules = node.apache2[:modules_enabled] || []
    Dir["/etc/apache2/mods-enabled/*.load"].each do |n|
      name = n.match(/\/([^\/]+).load$/)[1]
      unless modules.include? name
        Chef::Log.info "Disabling module #{name}"
        %x{a2dismod #{name}}
        notifies :reload, resources(:service => "apache2")
      end
    end
  end
end
