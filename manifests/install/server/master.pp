#
class ipa::install::server::master {
  $ad_domain            = $ipa::ad_domain
  $ad_ldap_search_base  = $ipa::ad_ldap_search_base
  $ad_site              = $ipa::ad_site
  $admin_pass           = $ipa::admin_password
  $admin_user           = $ipa::admin_user
  $automount_location   = $ipa::automount_location
  $cmd_opts_dns         = $ipa::install::server::server_install_cmd_opts_setup_dns
  $cmd_opts_dnssec      = $ipa::install::server::server_install_cmd_opts_dnssec_validation
  $cmd_opts_forwarders  = $ipa::install::server::server_install_cmd_opts_forwarders
  $cmd_opts_hostname    = $ipa::install::server::server_install_cmd_opts_hostname
  $cmd_opts_idstart     = $ipa::install::server::server_install_cmd_opts_idstart
  $cmd_opts_ntp         = $ipa::install::server::server_install_cmd_opts_no_ntp
  $cmd_opts_ui          = $ipa::install::server::server_install_cmd_opts_no_ui_redirect
  $cmd_opts_zones       = $ipa::install::server::server_install_cmd_opts_zone_overlap
  $ds_password          = $ipa::ds_password
  $ignore_group_members = $ipa::ignore_group_members
  $install_autofs       = $ipa::install_autofs
  $ipa_domain           = $ipa::domain
  $ipa_realm            = $ipa::final_realm
  $ipa_role             = $ipa::ipa_role
  $ipa_master_fqdn      = $ipa::ipa_master_fqdn
  $override_homedir     = $ipa::override_homedir
  $sssd_debug_level     = $ipa::sssd_debug_level
  $sssd_services        = $ipa::sssd_services

  # Build server-install command
  $server_install_cmd = @("EOC"/)
    ipa-server-install ${cmd_opts_hostname} \
    --realm=${ipa_realm} \
    --domain=${ipa_domain} \
    --admin-password=\$IPA_ADMIN_PASS \
    --ds-password=\$DS_PASSWORD \
    ${cmd_opts_dnssec} \
    ${cmd_opts_forwarders} \
    ${cmd_opts_idstart} \
    ${cmd_opts_ntp} \
    ${cmd_opts_ui} \
    ${cmd_opts_dns} \
    ${cmd_opts_zones} \
    --unattended
    | EOC

  # Set default login shell command
  $config_shell_cmd = 'ipa config-mod --defaultshell="/bin/bash"'

  # Set default password policy command
  $config_pw_policy_cmd = 'ipa pwpolicy-mod --maxlife=365'

  facter::fact { 'ipa_role':
    value => $ipa_role,
  }

  file { '/etc/ipa/primary':
    ensure  => 'file',
    content => 'Added by IPA Puppet module. Designates primary master. Do not remove.',
  }

  -> exec { "server_install_${$facts['networking']['fqdn']}":
    command     => $server_install_cmd,
    environment => ["IPA_ADMIN_PASS=${admin_pass}", "DS_PASSWORD=${ds_password}"],
    path        => ['/bin', '/sbin', '/usr/sbin', '/usr/bin'],
    timeout     => 0,
    unless      => '/usr/sbin/ipactl status >/dev/null 2>&1',
    creates     => '/etc/ipa/default.conf',
    logoutput   => 'on_failure',
    notify      => Ipa_kinit[$admin_user],
  }

  facter::fact { 'ipa_installed':
    value => true,
  }

  # Updated master sssd.conf file after IPA is installed.
  file { '/etc/sssd/sssd.conf':
    ensure  => file,
    content => epp('ipa/sssd.conf.epp',
      {
        ad_domain            => $ad_domain,
        ad_ldap_search_base  => $ad_ldap_search_base,
        ad_site              => $ad_site,
        automount_location   => $automount_location,
        domain               => $ipa_domain,
        fqdn                 => $facts['networking']['fqdn'],
        ignore_group_members => $ignore_group_members,
        install_autofs       => $install_autofs,
        ipa_master_fqdn      => $ipa_master_fqdn,
        ipa_role             => $ipa_role,
        override_homedir     => $override_homedir,
        sssd_debug_level     => $sssd_debug_level,
        sssd_services        => $sssd_services,
      }
    ),
    mode    => '0600',
    require => Exec["server_install_${$facts['networking']['fqdn']}"],
    notify  => Ipa::Helpers::Flushcache["server_${$facts['networking']['fqdn']}"],
  }

  include ipa::install::server::kinit

  # Configure IPA server default settings.
  Ipa_kinit[$admin_user]
  -> exec { 'ipa_config_mod_shell':
    command     => $config_shell_cmd,
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
  }

  -> exec { 'ipa_pwpolicy_mod_pass_age':
    command     => $config_pw_policy_cmd,
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
  }
}
