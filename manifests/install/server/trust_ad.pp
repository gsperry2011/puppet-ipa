# Install and configure trust_ad if enabled
#
class ipa::install::server::trust_ad {
  $ad_admin     = $ipa::ad_trust_admin
  $ad_domain    = $ipa::ad_trust_realm
  $ad_groups    = $ipa::ad_groups
  $admin_pass   = $ipa::admin_password
  $admin_user   = $ipa::admin_user
  $ad_password  = $ipa::ad_trust_password
  $ad_realm     = $ipa::ad_trust_realm
  $ipa_role     = $ipa::ipa_role

  package { 'ipa-server-trust-ad':
    ensure => 'present',
  }

  if $ipa_role == 'master' {
    $ad_trust_install_opts = "-a ${admin_pass}"
  } else {
    $ad_trust_install_opts = '--add-agents'
  }

  # Build adtrust install command
  $adtrust_install_cmd = @("EOC")
    ipa-adtrust-install \
    ${ad_trust_install_opts} \
    --unattended
    | EOC

  # Build trust-add command
  $trust_add_cmd = @("EOC"/)
    echo \$AD_PASSWORD | ipa trust-add ${ad_realm} \
    --admin=${ad_admin} \
    --password
    | EOC

  if $ad_password != '' and str2bool($facts['trust_ad']) != true {
    include ipa::install::server::kinit

    Ipa_kinit[$admin_user]
    -> exec { 'trust_ad_install':
      command   => $adtrust_install_cmd,
      path      => ['bin', '/sbin', '/usr/sbin'],
      logoutput => 'on_failure',
      notify    => Ipa::Helpers::Flushcache["server_${$facts['networking']['fqdn']}"],
    }
    ~> exec { 'trust_ad_trust_add':
      command     => $trust_add_cmd,
      environment => ["AD_PASSWORD=${ad_password}"],
      path        => ['/bin', '/usr/bin'],
      logoutput   => 'on_failure',
      refreshonly => true,
    }
    ~> exec { 'trust_ad_kdestroy':
      command => 'kdestroy',
      path    => ['bin', '/usr/bin'],
    }

    ~> facter::fact { 'trust_ad':
      value     => true,
    }
  }

  # NOTE: If no credentials supplied:
  #  You MUST manually run "ipa trust-add ${ad_realm}" with a valid domain
  #  administrator and password to facilitate LDAP integration.
  #
  #  $ ipa trust-add <AD_DOMAIN> --admin=<AD_ADMIN> --password
  #  password: <AD_ADMIN_PASSWORD>  # Will prompt for password

  # Copy IPA helper scripts to host
  file { '/root/01_config_ipa_ldap.sh':
    ensure  => file,
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    content => epp('ipa/config_ipa_ldap.sh.epp',
      {
        ad_admin   => $ad_admin,
        ad_domain  => $ad_domain,
        ad_groups  => $ad_groups,
        ad_realm   => $ad_realm,
        admin_pass => $admin_pass,
      }
    ),
  }

  file { '/root/02_id_override.sh':
    ensure  => file,
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    content => epp('ipa/id_override.sh.epp',
      {
        ad_domain => $ad_domain,
      }
    ),
  }
}
