execute 'apt-get update'
package 'build-essential'
gem_package 'chef-zero'

ruby_block 'chef-zero path' do
  block do
    node.set[:vagabond][:server][:zero_path] = [
      File.join(node[:languages][:ruby][:bin_dir], 'chef-zero'),
      '/opt/chef/embedded/bin/chef-zero',
      '/opt/chef/bin/chef-zero'
    ].detect{|path| ::File.exists?(path)}
  end
end

execute 'start chef-zero' do
  command lazy{
    "start-stop-daemon --background --start --quiet --exec #{node[:vagabond][:server][:zero_path]} -- -H #{node[:ipaddress]} -p 80 start"
  }
  not_if 'netstat -lpt | grep "tcp[[:space:]]" | grep ruby'
end
