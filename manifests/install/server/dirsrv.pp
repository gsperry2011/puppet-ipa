# Private class to manage IPA directory services
#
# @api private
#
class ipa::install::server::dirsrv (
  String $admin_password        = $ipa::admin_password,
  Optional[Array[String]] $ds_ssl_ciphers = $ipa::params::ds_ssl_ciphers,
  Optional[String] $ds_ssl_min_version    = $ipa::params::ds_ssl_min_version,
  String $ds_password           = $ipa::ds_password,
  String $ipa_realm             = $ipa::final_realm,
) inherits ipa {
  if empty($ds_password) {
    $_ds_password = $admin_password
  } else {
    $_ds_password = $ds_password
  }

  ## Set dash name IPA realm (eg. IPA-DOMAIN-COM)
  $_ipa_realm_dash = regsubst($ipa_realm, '\.', '-', 'G')

  ## Idempotent check for change
  if $ds_ssl_min_version and !$ds_ssl_min_version.empty() {
    $chk_ds_ssl_protocols = @("EOC")
      grep -q 'sslVersionMin: ${ds_ssl_min_version}' \
        /etc/dirsrv/slapd-${_ipa_realm_dash}/dse.ldif
      | EOC

    ## dirsrv command to modify 'sslVersionMin' parameter
    $configure_ds_ssl_protocols = @("EOC")
      ldapmodify -h localhost -p 389 -D 'cn=directory manager' -w '${_ds_password}' << EOF
      dn: cn=encryption,cn=config
      changeType: modify
      replace: sslVersionMin
      sslVersionMin: ${ds_ssl_min_version}
      EOF
      | EOC

    ## Configure DS SSL minimum version
    exec { 'ds_ssl_config':
      command => $configure_ds_ssl_protocols,
      path    => '/bin',
      unless  => $chk_ds_ssl_protocols,
      notify  => Service["dirsrv@${_ipa_realm_dash}"],
    }
  }

  ## Harden SSL/TLS ciphers for dirsrv
  #
  # Reference:
  #   https://directory.fedoraproject.org/docs/389ds/design/nss-cipher-design.html
  if $ds_ssl_ciphers and !$ds_ssl_ciphers.empty() {
    $ds_ssl_ciphers_str = $ds_ssl_ciphers.join(',')

    ## Idempotent check for change
    ### -LLL : supresses a lot of verbose output
    ### -o ldif-wrap=no : Turns off line wrapping on the results so we can grep
    ###                   the full cipher suite string in one go.
    $chk_ds_ssl_ciphers = @("EOC")
      ldapsearch -LLL -o ldif-wrap=no -h localhost -p 389 -D 'cn=directory manager' \
        -w '${_ds_password}' -b "cn=encryption,cn=config" 'nsSSL3Ciphers' \
        | grep -q 'nsSSL3Ciphers: ${ds_ssl_ciphers_str}'
      | EOC

    ## dirsrv command to modify 'nsSSL3Ciphers' parameter
    $configure_ds_ssl_ciphers = @("EOC")
      ldapmodify -h localhost -p 389 -D 'cn=directory manager' -w '${_ds_password}' << EOF
      dn: cn=encryption,cn=config
      changeType: modify
      replace: nsSSL3Ciphers
      nsSSL3Ciphers: ${ds_ssl_ciphers_str}
      EOF
      | EOC

    ## Configure DS SSL minimum version
    exec { 'ds_ssl_ciphers':
      command => $configure_ds_ssl_ciphers,
      path    => '/bin',
      unless  => $chk_ds_ssl_ciphers,
      notify  => Service["dirsrv@${_ipa_realm_dash}"],
    }
  }

  ## Restart dirsrv if changed
  service { "dirsrv@${_ipa_realm_dash}":
    ensure     => running,
    hasrestart => true,
  }
}
