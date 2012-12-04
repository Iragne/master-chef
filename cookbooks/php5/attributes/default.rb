default[:php5][:php_ini] = {
  :max_execution_time => 30,
  :max_input_time => 60,
  :memory_limit => "128M",
  :display_errors => false,
  :post_max_size => "8M",
  :max_file_uploads => 20,
  :upload_max_filesize => "2M",
  :magic_quotes_gpc => false,
  :default_charset => "iso-8859-1",
  :default_mimetype => "text/html",
  :safe_mode => false,
  :safe_mode_include_dir => [],
  :safe_mode_exec_dir => [],
  :safe_mode_gid => false,
  :open_basedir => [],
  :error_log => "/var/log/php/error.log",
}

default[:php5][:cli_php_ini] = {
  :max_execution_time => 30,
  :max_input_time => 60,
  :memory_limit => "-1",
  :display_errors => false,
  :post_max_size => "8M",
  :max_file_uploads => 20,
  :upload_max_filesize => "2M",
  :magic_quotes_gpc => false,
  :default_charset => "iso-8859-1",
  :default_mimetype => "text/html",
  :safe_mode => false,
  :safe_mode_include_dir => [],
  :safe_mode_exec_dir => [],
  :safe_mode_gid => false,
  :open_basedir => [],
  :error_log => "/var/log/php/error.log",
}


default[:php5][:apc] = {
  :shm_size => 30,
}

default[:php5][:apc_vhost] = {
  :listen => "127.0.0.1:2323",
  :document_root => "/opt/apc",
}

