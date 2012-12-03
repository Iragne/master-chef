
define :php5_apache2, {
  :options => {}
} do

  php5_apache2_params = params

  package "libapache2-mod-php5" do
    notifies :reload, resources(:service => "apache2")
  end

  apache2_enable_module "php5"

  options = {}
  if php5_apache2_params[:options]
    php5_apache2_params[:options].each do |k, v|
      options[k.is_a?(String) ? k : k.to_s] = v
    end
  end

  config = node.php5.php_ini.to_hash.merge(options)

  template "/etc/php5/apache2/php.ini" do
    mode 0644
    cookbook "php5"
    source "php5.ini.erb"
    variables config
    notifies :reload, resources(:service => "apache2")
  end

  template "/etc/php5/cli/php.ini" do
    mode 0644
    cookbook "php5"
    source "php-cli.ini.erb"
    variables config
    notifies :reload, resources(:service => "apache2")
  end

  if config["error_log"]

    directory File.dirname(config["error_log"]) do
      owner "www-data"
      mode 0755
      recursive true
    end

  end

end