#
class ipa::install::server::replica (
  String             $admin_pass       = $ipa::admin_password,
  String             $admin_user       = $ipa::admin_user,
  String             $install_opts     = $ipa::install::server::server_install_cmd_opts_setup_ca,
  String             $ipa_role         = $ipa::ipa_role,
  Sensitive[String]  $principal_pass   = $ipa::final_domain_join_password,
  String             $principal_user   = $ipa::final_domain_join_principal,
  String             $service_restart  = $ipa::params::service_restart_epp,
  String             $sssd_service     = $ipa::params::sssd_service,
) {
  # Build replica install command
  $replica_install_cmd = @("EOC"/)
    ipa-replica-install \
    --principal=${principal_user} \
    --admin-password=\$IPA_ADMIN_PASS \
    ${install_opts} \
    --unattended
    | EOC

  contain ipa::helpers::firewalld

  if str2bool($facts['ipa_installed']) != true {
    include ipa::install::server::kinit

    # Needed to ensure ipa-replica-install succeeds if new client is installed.
    exec { 'replica_restart_sssd':
      command     => inline_epp($service_restart, {'service' => $sssd_service}),
      path        => ['/sbin', '/bin', '/usr/bin'],
      tag         => 'ipa::install::replica',
      refreshonly => true,
    }
    ~> Ipa_kinit[$admin_user]
    -> exec { 'replica_server_install':
      command     => $replica_install_cmd,
      environment => [ "IPA_ADMIN_PASS=${principal_pass.unwrap}" ],
      path        => ['/sbin', '/usr/sbin'],
      timeout     => 0,
      unless      => '/usr/sbin/ipactl status >/dev/null 2>&1',
      logoutput   => 'on_failure',
      require     => Class['ipa::helpers::firewalld'],
      notify      => Ipa::Helpers::Flushcache["server_${$facts['fqdn']}"],
    }

    # Set fact for IPA installed if successful
    -> facter::fact { 'ipa_installed':
      value => true,
    }
    # Set puppet fact for IPA role
    -> facter::fact { 'ipa_role':
      value => $ipa_role,
    }
  }

}
