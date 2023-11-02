# IPA server install manifest
#
class ipa::install::server {
  $allow_zone_overlap   = $ipa::allow_zone_overlap
  $config_replica_ca    = $ipa::configure_replica_ca
  $configure_dns        = $ipa::final_configure_dns_server
  $configure_ntp        = $ipa::configure_ntp
  $dns_forwarders       = $ipa::custom_dns_forwarders
  $enable_hostname      = $ipa::enable_hostname
  $idstart              = $ipa::idstart
  $install_kstart       = $ipa::install_kstart
  $install_ldaputils    = $ipa::server_install_ldaputils
  $ipa_package_name     = $ipa::params::ipa_server_package_name
  $ipa_role             = $ipa::ipa_role
  $ipa_server_name      = $ipa::ipa_server_fqdn
  $kstart_package_name  = $ipa::params::kstart_package_name
  $ldap_package_name    = $ipa::params::ldaputils_package_name
  $make_homedir         = $ipa::mkhomedir
  $set_no_dnssec        = $ipa::no_dnssec_validation
  $set_no_ui_redirect   = $ipa::no_ui_redirect

  package { $ipa_package_name:
    ensure => present,
  }

  if $install_kstart {
    package { $kstart_package_name:
      ensure => present,
    }
  }

  if $install_ldaputils {
    package { $ldap_package_name:
      ensure => present,
    }
  }

  $server_install_cmd_opts_idstart = "--idstart=${idstart}"

  if $allow_zone_overlap {
    $server_install_cmd_opts_zone_overlap = '--allow-zone-overlap'
  } else {
    $server_install_cmd_opts_zone_overlap = ''
  }

  if $set_no_dnssec {
    $server_install_cmd_opts_dnssec_validation = '--no-dnssec-validation'
  } else {
    $server_install_cmd_opts_dnssec_validation = ''
  }

  if $enable_hostname {
    $server_install_cmd_opts_hostname = "--hostname=${ipa_server_name}"
  } else {
    $server_install_cmd_opts_hostname = ''
  }

  if $configure_dns {
    $server_install_cmd_opts_setup_dns = '--setup-dns'
  } else {
    $server_install_cmd_opts_setup_dns = ''
  }

  if $config_replica_ca {
    $server_install_cmd_opts_setup_ca = '--setup-ca'
  } else {
    $server_install_cmd_opts_setup_ca = ''
  }

  if $configure_ntp {
    $server_install_cmd_opts_no_ntp = ''
  } else {
    $server_install_cmd_opts_no_ntp = '--no-ntp'
  }

  if $configure_dns {
    if size($dns_forwarders) > 0 {
      $server_install_cmd_opts_forwarders = join(prefix($dns_forwarders, '--forwarder '), ' ')
    }
    else {
      $server_install_cmd_opts_forwarders = '--no-forwarders'
    }
  }
  else {
    $server_install_cmd_opts_forwarders = ''
  }

  if $set_no_ui_redirect {
    $server_install_cmd_opts_no_ui_redirect = '--no-ui-redirect'
  } else {
    $server_install_cmd_opts_no_ui_redirect = ''
  }

  if $make_homedir {
    $server_install_cmd_opts_mkhomedir = '--mkhomedir'
  } else {
    $server_install_cmd_opts_mkhomedir = ''
  }

  # This will install either the master or replica IPA server depending on role.
  if $ipa_role == 'master' {
    contain ipa::install::server::master
  } elsif $ipa_role == 'replica' {
    contain ipa::install::server::replica
  }

  # This will set the SSL protocols to use.
  service { 'httpd':
    ensure => running,
    enable => true,
  }

  # harden the SSL ciphers and protocols for Apache using the NSS module
  $nss_ssl_ciphers = join($ipa::params::nss_ssl_ciphers, ',')
  $nss_ssl_protocols = join($ipa::params::nss_ssl_protocols, ',')

  if $nss_ssl_ciphers != undef and !$nss_ssl_ciphers.empty() {
    file_line { 'nss_ssl_cipher':
      path   => '/etc/httpd/conf.d/nss.conf',
      match  => '^NSSCipherSuite',
      line   => "NSSCipherSuite ${nss_ssl_ciphers}",
      notify => Service['httpd'],
    }
  }

  if $nss_ssl_protocols != undef and !$nss_ssl_protocols.empty() {
    file_line { 'nss_ssl_protocols':
      path   => '/etc/httpd/conf.d/nss.conf',
      match  => '^NSSProtocol',
      line   => "NSSProtocol ${nss_ssl_protocols}",
      notify => Service['httpd'],
    }
  }

  # Configure PKI (Dogtag) certificate server
  contain ipa::install::server::pki

  # Configure directory server parameters.
  contain ipa::install::server::dirsrv

  ## This will restart ipa services if any are detected as stopped after install.
  if $facts['ipa_role'] == 'master' or $facts['ipa_role'] == 'replica' {
    exec { 'start_ipa_services':
      command   => 'ipactl restart',
      path      => ['/bin', '/sbin', '/usr/sbin'],
      onlyif    => 'grep "STOPPED" <<< $(ipactl status 2>/dev/null)',
      logoutput => 'on_failure',
    }
  }
}
