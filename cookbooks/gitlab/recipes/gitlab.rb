
if node.lsb.codename == "squeeze"
  package "libicu44"
elsif node.lsb.codename == "lucid"
  package "libicu42"
else
  package "libicu48"
end

include_recipe "redis"

include_recipe "mysql::server"

include_recipe "rails"

rails_app "gitlab" do
  user node.gitlab.gitlab.user
  app_directory node.gitlab.gitlab.path
  mysql_database "gitlab:database"
end

unicorn_rails_app "gitlab" do
  location node.gitlab.location
end

rails_resque_worker "gitlab_resque" do
  rails_app "gitlab"
  queues 'post_receive,mailer,system_hook'
  workers 2
end

add_user_in_group node.gitlab.gitlab.user do
  group "git"
end

git_clone "#{node.gitlab.gitlab.path}/current" do
  repository node.gitlab.gitlab.url
  reference node.gitlab.gitlab.reference
  user node.gitlab.gitlab.user
  notifies :restart, resources(:service => "gitlab")
  notifies :restart, resources(:service => node.rails.resque_service_name)
end

template "#{node.gitlab.gitlab.path}/shared/gitlab.yml" do
  owner node.gitlab.gitlab.user
  source "gitlab.yml.erb"
  variables({
    :repositories => node.gitlab.gitolite.repositories,
    :hooks => "#{get_home node.gitlab.gitolite.user}/.gitolite/hooks",
    :hostname => node.gitlab.hostname,
    :port => node.gitlab.port,
    :https => node.gitlab.https,
    :mail_from => node.gitlab.mail_from,
  })
  notifies :restart, resources(:service => "gitlab")
  notifies :restart, resources(:service => node.rails.resque_service_name)
end

link "#{node.gitlab.gitlab.path}/current/config/database.yml" do
  to "#{node.gitlab.gitlab.path}/shared/database.yml"
end

link "#{node.gitlab.gitlab.path}/current/config/gitlab.yml" do
  to "#{node.gitlab.gitlab.path}/shared/gitlab.yml"
end

bash "create ssh key for gitlab user" do
  user node.gitlab.gitlab.user
  code "ssh-keygen -t rsa -f #{get_home node.gitlab.gitlab.user}/.ssh/id_rsa -b 2048 && cp #{get_home node.gitlab.gitlab.user}/.ssh/id_rsa.pub /tmp/gitlab.pub"
  not_if "[ -f #{get_home node.gitlab.gitlab.user}/.ssh/id_rsa ]"
end

bash "allow localhost connection for gitlab user" do
  user node.gitlab.gitlab.user
  code "ssh -o StrictHostKeyChecking=no git@localhost echo toto || true"
  not_if "[ -f #{get_home node.gitlab.gitlab.user}/.ssh/know_hosts ]"
end

execute_version "configure gitolite for gitlab" do
  user node.gitlab.gitolite.user
  command "cd #{node.gitlab.gitolite.path} && ./install -to #{get_home node.gitlab.gitolite.user}/bin && #{get_home node.gitlab.gitolite.user}/bin/gitolite setup -pk /tmp/gitlab.pub"
  file_storage "#{node.gitlab.gitolite.path}/.gitolite_install"
  version node.gitlab.gitolite.reference
end

execute_version "move repositories" do
  user "root"
  command <<-EOF
mv #{get_home node.gitlab.gitolite.user}/repositories #{node.gitlab.gitolite.repositories} &&
ln -s #{node.gitlab.gitolite.repositories} #{get_home node.gitlab.gitolite.user}/repositories &&
chmod -R 770 #{node.gitlab.gitolite.repositories} &&
chown -R #{node.gitlab.gitolite.user}:#{node.gitlab.gitolite.user} #{node.gitlab.gitolite.repositories}
EOF
  file_storage "#{node.gitlab.gitolite.repositories}/.installed"
end

deployed_files = %w{.bundle-option .rbenv-version .rbenv-gemsets}

directory "#{node.gitlab.gitlab.path}/shared/files" do
  owner node.gitlab.gitlab.user
end

deployed_files.each do |f|
  template "#{node.gitlab.gitlab.path}/shared/files/#{f}" do
    owner node.gitlab.gitlab.user
    source f
  end
end

cp_command = deployed_files.map{|f| "cp #{node.gitlab.gitlab.path}/shared/files/#{f} #{node.gitlab.gitlab.path}/current/#{f}"}.join(' && ')

ruby_rbenv_command "gitlab db:migrate" do
  user node.gitlab.gitlab.user
  directory "#{node.gitlab.gitlab.path}/current"
  code "rm -f .warped && #{cp_command} && rbenv warp install && rm -rf log && ln -s #{node.gitlab.gitlab.path}/shared/log . && RAILS_ENV=production rake db:migrate"
  version node.gitlab.gitlab.reference
end

ruby_rbenv_command "initialize gitlab" do
  user node.gitlab.gitlab.user
  directory "#{node.gitlab.gitlab.path}/current"
  code "RAILS_ENV=production rake gitlab:app:setup"
  file_storage "#{node.gitlab.gitlab.path}/shared/.initialized"
  version 1
end

execute_version "install gitlab hook" do
  user "root"
  command "cp #{node.gitlab.gitlab.path}/current/lib/hooks/post-receive #{get_home node.gitlab.gitolite.user}/.gitolite/hooks/common/post-receive && chown #{node.gitlab.gitolite.user}:#{node.gitlab.gitolite.user} #{get_home node.gitlab.gitolite.user}/.gitolite/hooks/common/post-receive"
  file_storage "#{node.gitlab.gitlab.path}/current/.gitlab_hook"
  version node.gitlab.gitlab.reference
end

bash "update gitolite rc" do
  user node.gitlab.gitolite.user
  code "sed -i 's/0077/0007/g' #{get_home node.gitlab.gitolite.user}/.gitolite.rc && sed -i \"s/\\(GIT_CONFIG_KEYS\\s*=>*\\s*\\).\\{2\\}/\\1\\\"\\.\\*\\\"/g\" #{get_home node.gitlab.gitolite.user}/.gitolite.rc"
  not_if "grep GIT_CONFIG_KEYS #{get_home node.gitlab.gitolite.user}/.gitolite.rc | grep '\\.\\*'"
end

file "#{get_home node.gitlab.gitlab.user}/.gitconfig" do
  owner node.gitlab.gitlab.user
  content <<-EOF
[user]
  name = Gitlab
  email = #{node.gitlab.mail_from}
  EOF
end

# charlock_holmes does not support moving after install
# following commands allow to user system magic file
file "#{get_home node.gitlab.gitlab.user}/.magic" do
  owner node.gitlab.gitlab.user
end

link "#{get_home node.gitlab.gitlab.user}/.magic.mgc" do
  to "/usr/share/file/magic.mgc"
end
