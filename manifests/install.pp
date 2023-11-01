#
# DESCRIPTION: This module will install and configure IPA server based on the
#              role of the client.  The first run of this may take up to 15
#              minutes to complete on the master or replica servers, be patient.
#
class ipa::install {
  $auto_home_share     = $ipa::automount_home_share
  $auto_location       = $ipa::automount_location
  $autofs_package      = $ipa::params::autofs_package_name
  $configure_dns       = $ipa::final_configure_dns_server
  $install_ad_trust    = $ipa::install_trust_ad
  $install_autofs      = $ipa::install_autofs
  $install_epel        = $ipa::install_epel
  $install_ipa_server  = $ipa::install_ipa_server
  $install_sssd        = $ipa::install_sssd
  $install_sssd_tools  = $ipa::install_sssdtools
  $ipa_role            = $ipa::ipa_role
  $sssd_package_name   = $ipa::params::sssd_package_name
  $sssd_tools_package  = $ipa::params::sssdtools_package_name

  # Do we want to do this or rely on Satellite repository?
  if $install_epel and $facts['os']['family'] == 'RedHat' {
    contain epel

    # if CentOS 8+, need to enabled the "idm" DNF module version "DL1" that includes
    # both the client and server installs
    $os_name = $facts['os']['name']
    $os_maj = $facts['os']['release']['major']
    if ($os_name == 'CentOS' and versioncmp($os_maj, '8') >= 0 and !defined(Package['idm'])) {
      package { 'idm':
        ensure   => 'DL1',
        provider => 'dnfmodule',
      }
    }
  }

  # Configure firewall rules if enabled.
  if $ipa_role == 'master' or $ipa_role == 'replica' {
    case $facts['os']['family'] {
      'RedHat': {
        case $facts['os']['release']['major'] {
          /(7)/, /(8)/: {}
        default: { fail("ERROR: Server can only be installed on RHEL 7+, \
            not RHEL version: ${facts['os']['full']}")
          }
        }
      }
    default: { fail("ERROR: Server can only be installed on RHEL 7+, \
        not on operating system: ${facts['os']['family']}")
      }
    }

    contain ipa::helpers::firewalld
  }

  if $install_sssd {
    contain ipa::install::sssd
  }

  if $install_sssd_tools {
    package { $sssd_tools_package:
      ensure => present,
    }
  }

  # install AutoFS here so both clients and servers get the package if they ask for it
  # otherwise we would have to put this in both server and client manifests
  if $install_autofs {
    ensure_resource('package', $autofs_package, { 'ensure' => 'present' })
  }

  # Install client if setting up replica server
  if $ipa_role == 'client' or $ipa_role == 'replica' {
    contain ipa::install::client
  }

  if $ipa_role == 'master' or $ipa_role == 'replica' {
    if $configure_dns {
      $dns_packages = [
        'ipa-server-dns',
        'bind-dyndb-ldap',
      ]
      package { $dns_packages:
        ensure => present,
      }
    }

    # Call server install mainfest
    if $install_ipa_server {
      contain ipa::install::server
    }

    # Call trust_ad install manifest
    if $install_ad_trust == true and $facts['trust_ad'] == undef {
      contain ipa::install::server::trust_ad
    }

    # Call autofs install mainfest
    if $ipa_role == 'master' {
      if $install_autofs {
        class { 'ipa::install::server::autofs':
          automount_home_share => $auto_home_share,
          automount_location   => $auto_location,
        }
        contain ipa::install::server::autofs
      }
    }
  }

  # Define helper
  ipa::helpers::flushcache { "server_${$facts['networking']['fqdn']}": }
}
