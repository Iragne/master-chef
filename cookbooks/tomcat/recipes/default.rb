include_recipe "java"

package "libapr1"

base_user node.tomcat.user do
  home node.tomcat.home
end

bash "install tomcat via warp" do
  user node.tomcat.user
  code "cd #{node.tomcat.home} && wget #{node.warp.warp_src}/#{node.tomcat.warp_file} && sh #{node.tomcat.warp_file} && rm #{node.tomcat.warp_file}"
  not_if "[ -d #{node.tomcat.catalina_home} ]"
end

directory "#{node.tomcat.instances_base}" do
  owner node.tomcat.user
end

directory node.tomcat.log_dir do
  owner node.tomcat.user
end

if node.tomcat[:instances]

  node.tomcat.instances.keys.each do |k|
    node.tomcat.instances[k][:name] = k
    tomcat_instance "tomcat:instances:#{k}" do
      instance_name k
    end
  end

end