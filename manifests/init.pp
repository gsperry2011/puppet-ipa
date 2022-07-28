# == Class: ipa
#
# Manages IPA masters, replicas and clients.
# Parameters
# ----------
# `manage`
#      (boolean) Manage ipa with Puppet. Defaults to true. Setting this to
#                to false is useful when a handful of hosts have unsupported
#                operating systems and you'd rather exclude them from FreeIPA
#                instead of including the others individually. Use this with
#                a separate Hiera level (e.g. $facts['lsbdistcodename']) for maximum
#                convenience.
# `domain`
#      (string) The name of the IPA domain to create or join.
# `ipa_role`
#      (string) What role the node will be. Options are 'master', 'replica', and 'client'.
#
# `admin_password`
#      (string) Password which will be assigned to the IPA account named 'admin'.
#
# `automount_location`
#      (string) Define automount location.
#
# `debug_level`
#      (string) Set debug level for SSSD logs.
#
# `ds_password`
#      (string) Password which will be passed into the ipa setup's parameter named "--ds-password".
#
# `ds_ssl_ciphers`
#      (Array[String]) List of SSL ciphers for use by the 389 directory service (dirsrv).
#      If you want to use the default ciphers for IPA, specify an array with a single element:
#        ['default']
#      Reference: https://directory.fedoraproject.org/docs/389ds/design/nss-cipher-design.html
#
# `$ds_ssl_min_version`
#      (String) Minimum version of SSL/TLS to allow for incoming connections.
#      Reference: https://directory.fedoraproject.org/docs/389ds/design/nss-cipher-design.html#ssl-version-configuration
#
# `allow_zone_overlap`
#      (boolean) if set to true, allow creating of (reverse) zone even if the zone is already
#                resolvable. Using this option is discouraged as it result in later problems with
#                domain name. You may have to use this, though, when migrating existing DNS
#                domains to FreeIPA.
#
# `no_dnssec_validation`
#      (boolean) if set to true, DNSSEC validation is disabled.
#
# `client_install_ldaputils`
#      (boolean) If true, then the ldaputils packages are installed if ipa_role is set to client.
#
# `configure_dns_server`
#      (boolean) If true, then the parameter '--setup-dns' is passed to the IPA server installer.
#                Also, triggers the install of the required dns server packages.
#
# `configure_replica_ca`
#      (boolean) If true, then the parameter '--setup-ca' is passed to the IPA replica installer.
#
# `configure_ntp`
#      (boolean) If false, then the parameter '--no-ntp' is passed to the IPA client and server
#                installers.
#
# `configure_sshd`
#      (boolean) If false, then the parameter '--no-sshd' is passed to the IPA client and server
#                installers.
#
# `custom_dns_forwarders`
#      (array[string]) Each element in this array is prefixed with '--forwarder '
#                      and passed to the IPA server installer.
#
# `domain_join_principal`
#      (string) The principal (usually username) used to join a client or replica to the IPA domain.
#
# `domain_join_password`
#      (string) The password for the domain_join_principal.
#
# `enable_hostname`
#      (boolean) If true, then the parameter '--hostname' is populated with the parameter 'ipa_server_fqdn'
#                and passed to the IPA installer.
#
# `fixed_primary`
#      (boolean) If true, then the parameter '--fixed-primary' is passed to the IPA installer.
#
# `idstart`
#      (integer) From the IPA man pages: "The starting user and group id number".
#
# `install_autofs`
#      (boolean) If true, then the autofs packages are installed.
#
# `install_epel`
#      (boolean) If true, then the epel repo is installed. The epel repo is usually required for sssd packages.
#
# `install_kstart`
#      (boolean) If true, then the kstart packages are installed.
#
# `install_sssdtools`
#      (boolean) If true, then the sssdtools packages are installed.
#
# `install_ipa_client`
#      (boolean) If true, then the IPA client packages are installed if the parameter 'ipa_role' is set to 'client'.
#
# `install_ipa_server`
#      (boolean) If true, then the IPA server packages are installed if the parameter 'ipa_role' is not set to 'client'.
#
# `install_sssd`
#      (boolean) If true, then the sssd packages are installed.
#
# `ipa_server_fqdn`
#      (string) Actual fqdn of the IPA server or client.
#
# `ipa_master_fqdn`
#      (string) FQDN of the server to use for a client or replica domain join.
#
# `manage_host_entry`
#      (boolean) If true, then a host entry is created using the parameters 'ipa_server_fqdn'
#
# `mkhomedir`
#      (boolean) If true, then the parameter '--mkhomedir' is passed to the IPA server and client
#      installers.
#
# `no_ui_redirect`
#      (boolean) If true, then the parameter '--no-ui-redirect' is passed to the IPA server installer.
#
# 'nss_ssl_ciphers'
#      (string) SSL ciphers to enable for the Apache service in a format compatible with
#      the Apache NSS module.
#      Reference: https://github.com/tiran/mod_nss/blob/master/nss_engine_cipher.c
#
# 'nss_ssl_protocols'
#      (string) SSL protocols to enable for Apache (NSS module).
#
# 'override_homedir'
#      (string) If defined, will add homedir override to sssd.conf
#
# `pki_ssl_ciphers`
#      (Array[String]) List of SSL ciphers to enable for the PKI CA service Dogtag.
#      Reference: https://www.dogtagpki.org/wiki/Tomcat_JSS_7.3_Configuration
#
# `pki_ssl_protocol_range`
#      (String) Range of SSL protocols to enable. This is of the format:
#          "min:max"  (example: "tls1_0:tls1_2")
#
#      To enforce the latest version, set the min and max to the same value:
#          "tls1_2:tls1_2"
#
#      If you do not specify a range, the PKI dogtag service will throw an error.
#      Reference: https://www.dogtagpki.org/wiki/Tomcat_JSS_7.3_Configuration
#
# `realm`
#      (string) The name of the IPA realm to create or join.
#
# `server_install_ldaputils`
#      (boolean) If true, then the ldaputils packages are installed if ipa_role is not set to client.
#
# `sssd_services`
#      (string) Define what services are configured with SSSD.
#
#      (boolean) If true, then /etc/httpd/conf.d/ipa.conf is written to exclude kerberos support for
#                incoming requests whose HTTP_HOST variable match the parameter 'webio_proxy_external_fqdn'.
#                This allows the IPA Web UI to work on a proxied port, while allowing IPA client access to
#                function as normal.
#
#      (boolean) If true, then httpd is configured to act as a reverse proxy for the IPA Web UI. This allows
#                for the Web UI to be accessed from different ports and hostnames than the default.
#
#      (boolean) If true, then /etc/httpd/conf.d/ipa-rewrite.conf is modified to force all connections to https.
#                This is necessary to allow the WebUI to be accessed behind a reverse proxy when using nonstandard
#                ports.
#
#      (string) The public or external FQDN used to access the IPA Web UI behind the reverse proxy.
#
#      (integer) The HTTPS port to use for the reverse proxy. Cannot be 443.
#
class ipa (
  String               $admin_user               = 'admin',
  String               $admin_password           = '',
  String               $ad_domain                = '',
  Array[String]        $ad_groups                = [],
  Optional[String]     $ad_ldap_search_base      = '',
  Optional[String]     $ad_site                  = '',
  String               $ad_trust_admin           = '',
  String               $ad_trust_password        = '',
  String               $ad_trust_realm           = '',
  Boolean              $allow_zone_overlap       = false,
  String               $automount_location       = 'default',
  String               $automount_home_dir       = '',
  String               $automount_home_share     = '',
  Boolean              $client_install_ldaputils = false,
  Boolean              $configure_dns_server     = false,
  Boolean              $configure_ldap_search    = false,
  Boolean              $configure_ntp            = false,
  Boolean              $configure_replica_ca     = false,
  Boolean              $configure_sshd           = true,
  Array[String]        $custom_dns_forwarders    = [],
  String               $sssd_debug_level         = '3',
  String               $ds_password              = '',
  Optional[Array[String]] $ds_ssl_ciphers        = $ipa::params::ds_ssl_ciphers,
  Optional[Enum['', 'TLS1.0','TLS1.1','TLS1.2', 'TLS1.3']] $ds_ssl_min_version = $ipa::params::ds_ssl_min_version,
  String               $domain                   = '',
  String               $domain_join_password     = '',
  String               $domain_join_principal    = '',
  Boolean              $enable_hostname          = true,
  Boolean              $fixed_primary            = false,
  Integer              $idstart                  = $ipa::params::idstart,
  Boolean              $ignore_group_members     = false,
  Boolean              $install_autofs           = true,
  Boolean              $install_epel             = false,
  Boolean              $install_ipa_client       = true,
  Boolean              $install_ipa_server       = true,
  Boolean              $install_kstart           = false,
  Boolean              $install_sssdtools        = false,
  Boolean              $install_sssd             = true,
  Boolean              $install_trust_ad         = true,
  String               $ipa_master_fqdn          = '',
  String               $ipa_role                 = 'client',
  String               $ipa_server_fqdn          = $facts['fqdn'],
  Boolean              $manage_host_entry        = true,
  Boolean              $manage                   = true,
  Boolean              $mkhomedir                = false,
  Boolean              $no_dnssec_validation     = false,
  Boolean              $no_ui_redirect           = false,
  Optional[Array[String]] $nss_ssl_ciphers       = $ipa::params::nss_ssl_ciphers,
  Optional[Array[String]] $nss_ssl_protocols     = $ipa::params::nss_ssl_protocols,
  Optional[String]     $override_homedir         = undef,
  Optional[Array[String]] $pki_ssl_ciphers       = $ipa::params::pki_ssl_ciphers,
  Optional[String]     $pki_ssl_protocol_range   = $ipa::params::pki_ssl_protocol_range,
  String               $realm                    = '',
  Boolean              $server_install_ldaputils = true,
  Array[String]        $sssd_services            = ['nss','sudo','pam','ssh','autofs'],
  Boolean              $trust_dns                = true,
) inherits ipa::params {

  if $manage {

    # Include per-OS parameters and fail on unsupported OS
    include ipa::params

    if $realm != '' {
      $final_realm = $realm
    } else {
      $final_realm = upcase($domain)
    }

    $master_principals = suffix(
      prefix(
        [$ipa_server_fqdn],
        'host/'
      ),
      "@${final_realm}"
    )

    if $domain_join_principal != '' {
      $final_domain_join_principal = $domain_join_principal
    } else {
      $final_domain_join_principal = 'admin'
    }

    if $domain_join_password != '' {
      $final_domain_join_password = Sensitive($domain_join_password)
    } else {
      $final_domain_join_password = Sensitive($ds_password)
    }

    if $ipa_role == 'client' {
      $final_configure_dns_server = false
    } else {
      $final_configure_dns_server = $configure_dns_server
    }

    class {'ipa::validate_params':}
    -> class {'ipa::install':}
  }

}
