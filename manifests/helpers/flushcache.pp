#
define ipa::helpers::flushcache {
  include ipa::params

  exec { 'stop_sssd':
    command     => inline_epp($ipa::params::service_stop_epp,
    { 'service' => $ipa::params::sssd_service }),
    path        => ['/sbin', '/bin', '/usr/bin'],
    refreshonly => true,
  }
  ~> exec { 'clear sssd cache':
    command     => 'rm -rf /var/lib/sss/db/* /var/lib/sss/mc/*',
    path        => ['/sbin', '/bin', '/usr/bin'],
    refreshonly => true,
  }
  ~> service { 'sssd':
    ensure => true,
    enable => true,
  }

  if $ipa::install_autofs {
    exec { 'stop_autofs':
      command     => inline_epp($ipa::params::service_stop_epp,
      { 'service' => $ipa::params::autofs_service }),
      path        => ['/sbin', '/bin', '/usr/bin'],
      refreshonly => true,
      subscribe   => Service['sssd'],
    }
    ~> exec { 'wait_for_sssd':
      command     => 'sleep 3',
      path        => ['/sbin', '/bin', '/usr/bin'],
      refreshonly => true,
    }
    ~> service { 'autofs':
      ensure => true,
      enable => true,
    }
  }
}
