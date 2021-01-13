#
# == Class: ipa::params
#
# Traditionally this file would be used to abstract away operating system
# differences. Right now the main purpose is to prevent ipa classes from
# causing havoc (e.g. partial configurations) on unsupported operating systems
# by failing early rather than later.
#
class ipa::params {

  $autofs_service = 'autofs'
  $sssd_service   = 'sssd'

  case $facts['os']['family'] {
    'RedHat': {
      case $facts['os']['release']['major'] {
        /(7)/, /(8)/: {
          $service_stop_epp    = 'systemctl stop <%= $service %>'
          $service_restart_epp = 'systemctl restart <%= $service %>'
        }
        /(6)/: {
          $service_stop_epp    = 'service <%= $service %> stop'
          $service_restart_epp = 'service <%= $service %> restart'
        }
        default: { fail("ERROR: Unsupported RHEL version: ${facts['os']['full']}") }
      }
      $ldaputils_package_name    = 'openldap-clients'
      $ipa_client_package_name   = 'ipa-client'
      $ipa_client_package_ensure = 'present'
    }
    'Debian': {
      case $facts['os']['release']['major'] {
        /(16.04)/: {
          $service_stop_epp    = 'systemctl stop <%= $service %>'
          $service_restart_epp = 'systemctl restart <%= $service %>'
        }
        default: { fail("ERROR: Unsupported Ubuntu version: ${facts['os']['full']}") }
      }
      $ldaputils_package_name    = 'ldap-utils'
      $ipa_client_package_name   = 'freeipa-client'
      $ipa_client_package_ensure = 'present'
    }
    default: {
      fail("ERROR: Unsupported operating system: ${facts['os']['family']}")
    }
  }

  # These package names are the same on RedHat and Debian derivatives
  $autofs_package_name      = 'autofs'
  $ipa_server_package_name  = 'ipa-server'
  $kstart_package_name      = 'kstart'
  $sssd_package_name        = 'sssd-common'
  $sssdtools_package_name   = 'sssd-tools'

}
