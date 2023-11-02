# Validates input configs from init.pp.
#
class ipa::validate_params {
  $admin_pass     = $ipa::admin_password
  $domain         = $ipa::domain
  $ds_password    = $ipa::ds_password
  $idstart        = $ipa::idstart
  $ipa_master     = $ipa::ipa_master_fqdn
  $ipa_realm      = $ipa::final_realm
  $ipa_role       = $ipa::ipa_role
  $join_password  = $ipa::final_domain_join_password

  case $ipa_role {
    'client': {}
    'master': {}
    'replica': {}
    default: { fail('The parameter ipa_role must be set to client, master, or replica.') }
  }

  if $idstart < 10000 {
    fail('Parameter "idstart" must be an integer greater than 10000.')
  }

  if ($domain !~ Stdlib::Fqdn) {
    fail("ipa::domain '${ipa::domain}' is not a valid FQDN. We expect a match for Stdlib::Fqdn")
  }
  if ($ipa_realm !~ Stdlib::Fqdn) {
    fail("ipa::realm '${ipa_realm}' is not a valid FQDN. We expect a match for Stdlib::Fqdn")
  }

  if $ipa_role == 'master' {
    if length($admin_pass) < 8 {
      fail('When ipa_role is set to master, the parameter admin_password must be populated and at least of length 8.')
    }

    if length($ds_password) < 8 {
      fail("\
    #When ipa_role is set to master, the parameter ds_password \
    #must be populated and at least of length 8."
      )
    }
  }

  if $ipa_role != 'master' { # if replica or client

    # TODO: validate_legacy
    if $ipa_master == '' {
      fail("When creating a ${ipa_role} the parameter named ipa_master_fqdn cannot be empty.")
    }

    if ($ipa_master !~ Stdlib::Fqdn) {
      fail("ipa::ipa_master_fqdn '${ipa_master} is not a valid FQDN. We expect a match for Stdlib::Fqdn")
    }

    if $join_password.unwrap == '' {
      fail("When creating a ${ipa_role} the parameter named domain_join_password cannot be empty.")
    }
  }
}
