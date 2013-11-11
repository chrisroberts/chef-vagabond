default[:vagabond][:bases][:ubuntu_1004][:template] = 'ubuntu'
default[:vagabond][:bases][:ubuntu_1004][:template_options] = {'--release' => 'lucid'}
default[:vagabond][:bases][:ubuntu_1204][:template] = 'ubuntu'
default[:vagabond][:bases][:ubuntu_1204][:template_options] = {'--release' => 'precise'}
default[:vagabond][:bases][:ubuntu_1210][:template] = 'ubuntu'
default[:vagabond][:bases][:ubuntu_1210][:template_options] = {'--release' => 'quantal'}
default[:vagabond][:bases][:centos_58][:template] = 'centos'
default[:vagabond][:bases][:centos_58][:template_options] = {'--release' => '5', '--releaseminor' => '8'}
default[:vagabond][:bases][:centos_63][:template] = 'centos'
default[:vagabond][:bases][:centos_63][:template_options] = {'--release' => '6', '--releaseminor' => '3'}
default[:vagabond][:bases][:centos_64][:template] = 'centos'
default[:vagabond][:bases][:centos_64][:template_options] = {'--release' => '6', '--releaseminor' => '4'}
default[:vagabond][:bases][:centos_5][:template] = 'centos'
default[:vagabond][:bases][:centos_5][:template_options] = {'--release' => '5'}
default[:vagabond][:bases][:centos_6][:template] = 'centos'
default[:vagabond][:bases][:centos_6][:template_options] = {'--release' => '6'}
default[:vagabond][:bases][:debian_6][:template] = 'debian'
default[:vagabond][:bases][:debian_6][:create_environment] = {'SUITE' => 'squeeze'}
default[:vagabond][:bases][:debian_7][:template] = 'debian'
default[:vagabond][:bases][:debian_7][:create_environment] = {'SUITE' => 'wheezy'}
default[:vagabond][:customs] = {}
default[:vagabond][:server][:erchefs] = [] #['11.0.8'] # versions
default[:vagabond][:server][:base] = 'ubuntu_1204'
default[:vagabond][:server][:prefix] = 'vb-server-'
default[:vagabond][:server][:zero_lxc_name] = 'vb-zero-server'
default[:vagabond][:server][:zero_path] = nil
default[:vagabond][:host_cookbook_store] = Chef::Config[:cookbook_path]
