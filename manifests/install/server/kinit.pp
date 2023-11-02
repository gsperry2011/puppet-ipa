# Class to manage kinit as admin user
#
# @api private
#
class ipa::install::server::kinit (
  String   $admin_pass = $ipa::admin_password,
  String   $admin_user = $ipa::admin_user,
  String   $ipa_realm  = $ipa::final_realm,
) inherits ipa {
  ipa_kinit { $admin_user:
    ensure   => present,
    realm    => $ipa_realm,
    password => $admin_pass,
  }
}
