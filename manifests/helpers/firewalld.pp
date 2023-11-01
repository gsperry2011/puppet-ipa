# Manifest to open ports for IPA server
class ipa::helpers::firewalld {
  include firewalld

  # Open ports for DNS if enabled
  if $ipa::final_configure_dns_server {
    firewalld_service { 'Open DNS ports':
      ensure  => 'present',
      service => 'dns',
      zone    => 'public',
    }
  }

  # Open ports for NTP if enabled
  if $ipa::configure_ntp {
    firewalld_service { 'Open NTP ports':
      ensure  => 'present',
      service => 'ntp',
      zone    => 'public',
    }
  }

  # Open ports for trust_ad if enabled
  if $ipa::install_trust_ad {
    firewalld_service { 'Open trust_ad ports':
      ensure  => 'present',
      service => 'freeipa-trust',
      zone    => 'public',
    }
  }

  # Open ports for IPA server
  firewalld_service { 'Open LDAPS server ports':
    ensure  => 'present',
    service => 'freeipa-ldaps',
    zone    => 'public',
  }

  firewalld_service { 'Open LDAP server ports':
    ensure  => 'present',
    service => 'freeipa-ldap',
    zone    => 'public',
  }
}
