include_recipe "mysql::server"
include_recipe "tomcat"
include_recipe "nginx"

mysql_database "sonar:database"

db_config = mysql_config "sonar:database"

build_dir = "#{node.sonar.path.build}"
sonar_file_name = "sonar-#{node.sonar.version}"

directory "#{node.sonar.path.root_path}" do
  owner node.tomcat.user
  recursive true
end

execute "install sonar home" do
  command "cd #{build_dir} && curl --location #{node.sonar.zip_url} -o #{sonar_file_name}.zip && unzip #{node.sonar.path.build}/#{sonar_file_name}.zip && rm -f #{build_dir}/#{sonar_file_name}.zip"
  not_if "[ -d #{build_dir}/#{sonar_file_name}/war ]"
end

directory "#{node.sonar.path.build}/#{sonar_file_name}" do
  owner node.tomcat.user
  mode '0755'
end

template "#{node.sonar.path.root_path}/#{sonar_file_name}/conf/sonar.properties" do
  mode '0644'
  variables :password => db_config[:password]
  source "sonar.properties.erb"
end

execute "build sonar war" do
  command "cd #{node.sonar.path.build}/sonar-#{node.sonar.version}/war && sh build-war.sh"
  not_if "[ -f #{node.sonar.path.build}/sonar-#{node.sonar.version}/war/sonar.war ]"
end

tomcat_instance "sonar:tomcat" do
  war_url "file://#{node.sonar.path.build}/#{sonar_file_name}/war/sonar.war"
  war_location node.sonar.location
end

tomcat_sonar_http_port = tomcat_config("sonar:tomcat")[:connectors][:http][:port]

nginx_add_default_location "sonar" do
  content <<-EOF

  location #{node.sonar.location} {
    proxy_pass http://tomcat_sonar_upstream;
    proxy_read_timeout 600s;
    break;
  }

EOF
  upstream <<-EOF
  upstream tomcat_sonar_upstream {
  server 127.0.0.1:#{tomcat_sonar_http_port} fail_timeout=0;
}
  EOF
end
