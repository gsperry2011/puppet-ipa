# Private class to manage IPA PKI certificate server (Dogtag)
#
# @api private
#
class ipa::install::server::pki (
  Optional[String]         $ssl_protocol_range  = $ipa::params::pki_ssl_protocol_range,
  Optional[Array[String]]  $ssl_ciphers         = $ipa::params::pki_ssl_ciphers,
) inherits ipa {
  $config_file = '/etc/pki/pki-tomcat/server.xml'

  # Setup PKI CA service (Dogtag) with secure SSL settings
  if $ssl_protocol_range and !$ssl_protocol_range.empty() {
    exec { '/etc/pki/pki-tomcat/server.xml:sslVersionRangeStream':
      command => "sed -i 's/sslVersionRangeStream=\"[^\"]*\"/sslVersionRangeStream=\"${ssl_protocol_range}\"/g' ${config_file}",
      path    => ['/bin', '/sbin', '/usr/sbin'],
      unless  => "grep -q 'sslVersionRangeStream=\"${ssl_protocol_range}\"' ${config_file}",
      notify  => Service['pki-tomcatd@pki-tomcat.service'],
    }
    exec { '/etc/pki/pki-tomcat/server.xml:sslVersionRangeDatagram':
      command => "sed -i 's/sslVersionRangeDatagram=\"[^\"]*\"/sslVersionRangeDatagram=\"${ssl_protocol_range}\"/g' ${config_file}",
      path    => ['/bin', '/sbin', '/usr/sbin'],
      unless  => "grep -q 'sslVersionRangeDatagram=\"${ssl_protocol_range}\"' ${config_file}",
      notify  => Service['pki-tomcatd@pki-tomcat.service'],
    }
  }

  if $ssl_ciphers and !$ssl_ciphers.empty() {
    $ciphers = $ssl_ciphers.join(',')

    exec { '/etc/pki/pki-tomcat/server.xml:sslRangeCiphers':
      command => "sed -i 's/sslRangeCiphers=\"[^\"]*\"/sslRangeCiphers=\"${ciphers}\"/g' ${config_file}",
      path    => ['/bin', '/sbin', '/usr/sbin'],
      unless  => "grep -q 'sslRangeCiphers=\"${ciphers}\"' ${config_file}",
      notify  => Service['pki-tomcatd@pki-tomcat.service'],
    }
  }

  service { 'pki-tomcatd@pki-tomcat.service':
    ensure => running,
  }
}
