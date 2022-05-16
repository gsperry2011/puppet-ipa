#
class ipa::install::client (
  String            $ad_domain            = $ipa::ad_domain,
  String            $ad_ldap_search_base  = $ipa::ad_ldap_search_base,
  String            $ad_site              = $ipa::ad_site,
  String            $automount_location   = $ipa::automount_location,
  String            $automount_home_dir   = $ipa::automount_home_dir,
  Boolean           $client_configure_ntp = $ipa::configure_ntp,
  String            $client_ensure        = $ipa::params::ipa_client_package_ensure,
  Boolean           $client_install_ldap  = $ipa::client_install_ldaputils,
  String            $client_package_name  = $ipa::params::ipa_client_package_name,
  Boolean           $client_trust_dns     = $ipa::trust_dns,
  String            $domain_name          = $ipa::domain,
  Boolean           $ignore_group_members = $ipa::ignore_group_members,
  Boolean           $install_autofs       = $ipa::install_autofs,
  String            $ipa_role             = $ipa::ipa_role,
  String            $ipa_master_fqdn      = $ipa::ipa_master_fqdn,
  String            $ldap_package_name    = $ipa::params::ldaputils_package_name,
  Boolean           $make_homedir         = $ipa::mkhomedir,
  Optional[String]  $override_homedir     = $ipa::override_homedir,
  Sensitive[String] $principal_pass       = $ipa::final_domain_join_password,
  String            $principal_user       = $ipa::final_domain_join_principal,
  String            $sssd_debug_level     = $ipa::sssd_debug_level,
  String            $sssd_package_name    = $ipa::params::sssd_package_name,
  Array[String]     $sssd_services        = $ipa::sssd_services,
) inherits ipa {
  package{ 'ipa-client':
    ensure => $client_ensure,
    name   => $client_package_name,
  }

  if $client_install_ldap {
    package { $ldap_package_name:
      ensure => present,
    }
  }

  if $client_trust_dns {
    $client_dns_opts = '--ssh-trust-dns'
  } else {
    # Fix is not using DNS for host resolution
    $client_dns_opts = "--server=${ipa_master_fqdn}"
  }

  if $client_configure_ntp {
    $client_ntp_opts = ''
  } else {
    $client_ntp_opts = '--no-ntp'
  }

  # Build client install command
  $client_install_cmd = @("EOC"/)
    ipa-client-install \
    --domain=${domain_name} \
    --principal="${principal_user}" \
    --password=\$IPA_JOIN_PASSWORD \
    ${client_dns_opts} \
    ${client_ntp_opts} \
    --unattended
    | EOC

  exec { "client_install_${$facts['fqdn']}":
    command     => $client_install_cmd,
    environment => [ "IPA_JOIN_PASSWORD=${principal_pass.unwrap}" ],
    path        => ['/bin', '/sbin', '/usr/sbin', '/usr/bin'],
    timeout     => 0,
    unless      => "cat /etc/ipa/default.conf | grep -i \"${domain_name}\"",
    creates     => '/etc/ipa/default.conf',
    logoutput   => 'on_failure',
    provider    => 'shell',
    notify      => Ipa::Helpers::Flushcache["server_${$facts['fqdn']}"],
  }

  # This will customize the sssd.conf file for EMS specifics.
  # NOTE: Needed to place outside of master loop to allow for IPA install to
  #       create original version and then update it on the master server.
  file { '/etc/sssd/sssd.conf':
    ensure  => file,
    content => epp('ipa/sssd.conf.epp', {
      ad_domain            => $ad_domain,
      ad_ldap_search_base  => $ad_ldap_search_base,
      ad_site              => $ad_site,
      automount_location   => $automount_location,
      domain               => $domain_name,
      fqdn                 => $facts['fqdn'],
      ignore_group_members => $ignore_group_members,
      install_autofs       => $install_autofs,
      ipa_master_fqdn      => $ipa_master_fqdn,
      ipa_role             => $ipa_role,
      override_homedir     => $override_homedir,
      sssd_debug_level     => $sssd_debug_level,
      sssd_services        => $sssd_services,
    }),
    mode    => '0600',
    require => [
      Package[$sssd_package_name],
      Exec["client_install_${$facts['fqdn']}"],
    ],
    notify  => Ipa::Helpers::Flushcache["server_${$facts['fqdn']}"],
  }

  if $automount_home_dir != undef and !$automount_home_dir.empty() {
    exec { 'client_create_automount_home_dir':
      command => "mkdir -p ${automount_home_dir}",
      path    => ['/bin', '/usr/bin'],
      creates => $automount_home_dir,
    }

    # Update nsswitch if autofs enabled.
    ~> file_line { '/etc/nsswitch.conf_automount':
      path   => '/etc/nsswitch.conf',
      line   => 'automount:  files sss',
      match  => '^automount:.*',
      notify => Ipa::Helpers::Flushcache["server_${$facts['fqdn']}"],
    }
  }

  # Update nsswitch with sudoers config
  file_line { '/etc/nsswitch.conf_sudoers':
    path   => '/etc/nsswitch.conf',
    line   => 'sudoers:  files sss',
    match  => '^sudoers:.*',
    notify => Ipa::Helpers::Flushcache["server_${$facts['fqdn']}"],
  }

  # Required for cross-domain lookups (example, AD joined hosts) lookup.
  file_line { 'krb5.conf_dns_realm':
    path    => '/etc/krb5.conf',
    line    => '  dns_lookup_realm = true',
    match   => '^  dns_lookup_realm =',
    require => Exec["client_install_${$facts['fqdn']}"],
  }

  file_line { 'krb5.conf_dns_kdc':
    path    => '/etc/krb5.conf',
    line    => '  dns_lookup_kdc = true',
    match   => '^  dns_lookup_kdc =',
    require => Exec["client_install_${$facts['fqdn']}"],
  }
}
