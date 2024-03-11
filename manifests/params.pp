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

  $ds_ssl_min_version_tls12 = 'TLS1.2'
  $ds_ssl_ciphers_tls12 = [
    '+TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
    '+TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
    '+TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
    '+TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
  ]
  $ds_ssl_ciphers_tls13 = [
    '+TLS_AES_128_GCM_SHA256',
    '+TLS_AES_256_GCM_SHA384',
    '+TLS_CHACHA20_POLY1305_SHA256',
  ]
  $pki_ssl_ciphers_tls12 = $ds_ssl_ciphers_tls12
  $pki_ssl_ciphers_tls13 = $ds_ssl_ciphers_tls13
  $pki_ssl_protocol_range_tls12 = 'tls1_2:tls1_2'

  $nss_ssl_ciphers_tls12 = [
    '+ecdhe_ecdsa_aes_128_gcm_sha_256',
    '+ecdhe_ecdsa_aes_256_gcm_sha_384',
    '+ecdhe_ecdsa_chacha20_poly1305_sha_256',
    '+ecdhe_rsa_aes_128_gcm_sha_256',
    '+ecdhe_rsa_aes_256_gcm_sha_384',
    '+ecdhe_rsa_chacha20_poly1305_sha_256',
  ]
  $nss_ssl_protocols_tls12 = ['TLSv1.2']

  case $facts['os']['family'] {
    'RedHat': {
      case $facts['os']['release']['major'] {
        /(7)/: {
          $service_stop_epp    = 'systemctl stop <%= $service %>'
          $service_restart_epp = 'systemctl restart <%= $service %>'

          $ds_ssl_ciphers         = $ds_ssl_ciphers_tls12
          $ds_ssl_min_version     = $ds_ssl_min_version_tls12
          $nss_ssl_ciphers        = $nss_ssl_ciphers_tls12
          $nss_ssl_protocols      = $nss_ssl_protocols_tls12
          $pki_ssl_ciphers        = $pki_ssl_ciphers_tls12
          $pki_ssl_protocol_range = $pki_ssl_protocol_range_tls12
        }
        /(8)/,/(9)/: {
          $service_stop_epp    = 'systemctl stop <%= $service %>'
          $service_restart_epp = 'systemctl restart <%= $service %>'

          # dirsrv allows for TLS 1.2 and 1.3
          # note: if you don't have TLS 1.3 enabled, you'll get an SSL error when trying to register clients:
          # Joining realm failed: Unable to initialize STARTTLS session
          #     Connect error: error:14094410:SSL routines:ssl3_read_bytes:sslv3 alert handshake failure
          # Failed to bind to server!
          # Retrying with pre-4.0 keytab retrieval method...
          # Unable to initialize STARTTLS session
          #     Connect error: error:14094410:SSL routines:ssl3_read_bytes:sslv3 alert handshake failure
          # Failed to bind to server!
          # Failed to get keytab
          # child exited with 9
          #$ds_ssl_ciphers         = $ds_ssl_ciphers_tls12 + $ds_ssl_ciphers_tls13
          #$ds_ssl_min_version     = $ds_ssl_min_version_tls12
          $ds_ssl_ciphers         = []
          $ds_ssl_min_version     = ''

          # IPA on RHEL/CentOS 8 switched to mod_ssl, away from mod_nss
          # mod_ssl in RHEL/CentOS 8 uses the "system" cryto policy for its ciphers and protocols
          # see:
          # https://www.redhat.com/en/blog/how-customize-crypto-policies-rhel-82
          # https://access.redhat.com/articles/3642912
          # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/using-the-system-wide-cryptographic-policies_security-hardening
          $nss_ssl_ciphers        = []
          $nss_ssl_protocols      = []

          # Dogtag PKI Tomcat
          # you _must_ set both the TLS 1.2 and 1.3 ciphers here though, otherwise you'll get an error
          # when registering your clients:
          # Joining realm failed: HTTP POST to URL 'https://freeipa.maludy.home:443/ipa/xml' failed.  libcurl failed even to execute the HTTP transaction, explaining:  SSL certificate problem: EE certificate key too weak
          #$pki_ssl_ciphers        = $pki_ssl_ciphers_tls12 + $pki_ssl_ciphers_tls13
          $pki_ssl_ciphers        = []
          # PKI Tomcat doesn't, yet, support tls1_3 protocol, so leave it to 1.2
          # if you try to set it to tls1_2:tls1_3 pki-tomcatd@pki-tomcat.service service will fail to start
          #$pki_ssl_protocol_range = $pki_ssl_protocol_range_tls12
          $pki_ssl_protocol_range = ''
        }
        default: { fail("ERROR: Unsupported RHEL release: ${facts['os']['release']['full']}") }
      }
      $ldaputils_package_name    = 'openldap-clients'
      $ipa_client_package_name   = 'ipa-client'
      $ipa_client_package_ensure = 'present'
    }
    'Debian': {
      case $facts['os']['release']['major'] {
        /(16.04)/,/(18.04)/,/(20.04)/,/(22.04)/: {
          $service_stop_epp    = 'systemctl stop <%= $service %>'
          $service_restart_epp = 'systemctl restart <%= $service %>'

          $ds_ssl_ciphers         = undef
          $ds_ssl_min_version     = undef
          $nss_ssl_ciphers        = undef
          $nss_ssl_protocols      = undef
          $pki_ssl_ciphers        = undef
          $pki_ssl_protocol_range = undef
        }
        default: { fail("ERROR: Unsupported Ubuntu release: ${facts['os']['release']['full']}") }
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

  # In order to avoid this error:
  #   ipa-server-install: error: idstart (1234) must be larger than UID_MAX/GID_MAX (60000) setting in /etc/login.defs.
  #
  # Always make sure it's larger than 65535
  #   https://en.wikipedia.org/wiki/User_identifier#Reserved_ranges
  $uid_gid_min = 65536
  # allows for the fact to be empty/undef
  $uid_gid_max = max(pick(dig($facts, 'ipa_login_defs', 'UID_MAX'), $uid_gid_min),
  pick(dig($facts, 'ipa_login_defs', 'GID_MAX'), $uid_gid_min))

  $idstart = (fqdn_rand('10737') + max($uid_gid_max, $uid_gid_min))
}
