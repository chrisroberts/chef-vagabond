include_recipe 'apt::cacher-ng'
include_recipe 'lxc'

ruby_block 'LXC template: lxc-centos' do
  block do
    dir = %w(/usr/share /usr/lib).map do |prefix|
      if(File.directory?(d = File.join(prefix, 'lxc/templates')))
        d
      end
    end.compact.first
    raise 'Failed to locate LXC template directory' unless dir
    cfl = Chef::Resource::CookbookFile.new(
      ::File.join(dir, 'lxc-centos'),
      run_context
    )
    cfl.source 'lxc-centos'
    cfl.mode 0755
    cfl.cookbook cookbook_name.to_s
    cfl.action :nothing
    cfl.run_action(:create)
  end
end

node[:vagabond][:bases].each do |name, options|

  next unless options[:enabled] || node[:vagabond][:server][:base] == name

  pkg_coms = [
    'update -y -q',
    'upgrade -y -q',
    'install curl -y -q'
  ]
  if(!options[:template].scan(%r{debian|ubuntu}).empty?)
    pkg_man = 'apt-get'
  elsif(!options[:template].scan(%r{fedora|centos}).empty?)
    pkg_man = 'yum'
  end
  if(pkg_man)
    pkg_coms.map! do |c|
      "#{pkg_man} #{c}"
    end
  else
    pkg_coms = []
  end

  lxc_container name do
    template options[:template]
    template_opts options[:template_options]
    default_config false if options[:memory]
    create_environment options[:environment] if options[:environment]
    initialize_commands [
      'locale-gen en_US.UTF-8',
      'update-locale LANG="en_US.UTF-8"',
      'rm -f /etc/sysctl.d/10-console-messages.conf',
      'rm -f /etc/sysctl.d/10-ptrace.conf',
      'rm -f /etc/sysctl.d/10-kernel-hardening.conf'
    ] + pkg_coms + [
      'curl -L https://www.opscode.com/chef/install.sh | bash'
    ]
  end
end

node[:vagabond][:customs].each do |name, options|

  lxc_container name do
    action :create
    clone options[:base]
    if(options[:configuration])
      options[:configuration].each_pair do |subresource, attributes|
        if(attributes.is_a?(Hash))
          self.send(subresource, 'vagabond dynamic') do
            attributes.each_pair do |key, value|
              self.send(key, value)
            end
          end
        else
          self.send(subresource, attributes)
        end
      end
    end
  end

  # NOTE: This is deprecated
  if(options[:memory])
    lxc_config name do
      cgroup(
        'memory.limit_in_bytes' => options[:memory][:ram],
        'memory.memsw.limit_in_bytes' => (
          Vagabond.get_bytes(options[:memory][:ram]) +
          Vagabond.get_bytes(options[:memory][:swap])
        )
      )
    end
  end
end

solo_file = ['file_cache_path "/var/chef-host"', 'cookbook_path ["/tmp/chef-host/cookbooks"]'].join("\n")
final_solo_file = ['file_cache_path "/var/chef-host"', 'cookbook_path ["/var/chef-host/cookbooks"]'].join("\n")
dna_file = "{\"run_list\":[\"recipe[vagabond::zero]\"]}"

lxc_container node[:vagabond][:server][:zero_lxc_name] do
  action :create
  clone node[:vagabond][:server][:base]
  fstab_mount 'cookbooks: /tmp/chef-host/cookbooks' do
    file_system node[:vagabond][:host_cookbook_store]
    mount_point '/tmp/chef-host/cookbooks'
    type 'none'
    options 'bind,ro'
  end
  initialize_commands [
    "echo \"#{Base64.encode64(solo_file)}\" > /tmp/solo.rb.encoded",
    'base64 --decode /tmp/solo.rb.encoded > /etc/chef-solo-host.rb',
    "echo \"#{Base64.encode64(dna_file)}\" > /tmp/dna.json.encoded",
    'base64 --decode /tmp/dna.json.encoded > /tmp/dna.json',
    'chef-solo -j /tmp/dna.json -c /etc/chef-solo-host.rb',
    "echo \"#{Base64.encode64(final_solo_file)}\" > /tmp/solo.rb.encoded",
    'base64 --decode /tmp/solo.rb.encoded > /etc/chef-solo-host.rb',
    'cp -R /etc/ssl/private/ /etc/ssl/private.bak',
    'rm -rf /etc/ssl/private',
    'mv /etc/ssl/private.bak /etc/ssl/private' # NOTE: i have nfc what this is about
  ]
end

node[:vagabond][:server][:erchefs].each do |version|

  dna_file = "{\"chef-server\": {\"version\":\"#{version}\"},\"run_list\":[\"recipe[chef-server]\"]}"

  lxc_container "#{node[:vagabond][:server][:prefix]}#{version.gsub('.', '_')}" do
    action :create
    clone node[:vagabond][:server][:base]
    fstab_mount 'cookbooks: /tmp/chef-host/cookbooks' do
      file_system node[:vagabond][:host_cookbook_store]
      mount_point '/tmp/chef-host/cookbooks'
      type 'none'
      options 'bind,ro'
    end
    initialize_commands [
      "echo \"#{Base64.encode64(solo_file)}\" > /tmp/solo.rb.encoded",
      'base64 --decode /tmp/solo.rb.encoded > /etc/chef-solo-host.rb',
      "echo \"#{Base64.encode64(dna_file)}\" > /tmp/dna.json.encoded",
      'base64 --decode /tmp/dna.json.encoded > /tmp/dna.json',
      'chef-solo -j /tmp/dna.json -c /etc/chef-solo-host.rb',
      "echo \"#{Base64.encode64(final_solo_file)}\" > /tmp/solo.rb.encoded",
      'base64 --decode /tmp/solo.rb.encoded > /etc/chef-solo-host.rb'
    ]
  end

  ruby_block "Clean server base (version: #{version})" do
    block do
      lxc = ::Lxc.new("#{node[:vagabond][:server][:prefix]}#{version.gsub('.', '_')}")
      # Prevent server startup on initial provision
      if(File.exists?(lxc.rootfs.join('etc/init/chef-server-runsvdir.conf')))
        FileUtils.rm lxc.rootfs.join('etc/init/chef-server-runsvdir.conf')
      end
      # Remove nginx ca files that will be stale
      Dir.glob(lxc.rootfs.join('var/opt/chef-server/nginx/ca/*').to_path).each do |path|
        FileUtils.rm path
      end
    end
  end

end
