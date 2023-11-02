#
class ipa::install::server::autofs {
  $ad_domain             = $ipa::ad_trust_realm
  $admin_user            = $ipa::admin_user
  $autofs_package        = $ipa::params::autofs_package_name
  $automount_home_dir    = "/home/ipa/${ad_domain}"
  $automount_home_share  = undef
  $automount_location    = undef

  include ipa::install::server::kinit

  # automount map home command
  $map_home_cmd = "ipa automountmap-add ${automount_location} auto.home"

  # Build automount auto.home key
  $key_home_cmd = @("EOC"/)
    ipa automountkey-add ${automount_location} auto.home \
    --key='*' \
    --info="-fstype=nfs4 ${automount_home_share}"
    | EOC

  # Build automount auto.master key
  $key_master_cmd = @("EOC"/)
    ipa automountkey-add ${automount_location} auto.master \
    --key="${automount_home_dir}" \
    --info=auto.home
    | EOC

  # Set default homedirectory command
  $config_homedir_cmd = "ipa config-mod --homedirectory='${automount_home_dir}'"

  # install the package
  ensure_resource('package', $autofs_package, { 'ensure' => 'present' })

  Ipa_kinit[$admin_user]
  -> exec { "automount_map_home_${$facts['networking']['fqdn']}":
    command => $map_home_cmd,
    unless  => "ipa automountmap-find ${automount_location} --map auto.home",
    path    => ['/bin', '/usr/bin'],
    notify  => Ipa::Helpers::Flushcache["server_${$facts['networking']['fqdn']}"],
  }
  ~> exec { "automount_key_home_${$facts['networking']['fqdn']}":
    command => $key_home_cmd,
    unless  => "ipa automountkey-find ${automount_location} auto.home --key='*'",
    path    => ['/bin', '/usr/bin'],
    notify  => Ipa::Helpers::Flushcache["server_${$facts['networking']['fqdn']}"],
  }
  ~> exec { "automount_key_master_${$facts['networking']['fqdn']}":
    command     => $key_master_cmd,
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
    notify      => Ipa::Helpers::Flushcache["server_${$facts['networking']['fqdn']}"],
  }
  ~> exec { 'ipa_config_mod_homedir':
    command     => $config_homedir_cmd,
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
  }

  if !defined(File[$automount_home_dir]) {
    file { $automount_home_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
    }
  }

  # Ensure nsswitch is configured for SSSD
  file_line { '/etc/nsswitch.conf':
    ensure => 'present',
    path   => '/etc/nsswitch.conf',
    line   => 'automount:  files sss',
    match  => '^automount:.*',
    notify => Ipa::Helpers::Flushcache["server_${$facts['networking']['fqdn']}"],
  }
}
