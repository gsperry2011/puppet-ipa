# puppet-ipa

## Development

* Fixed bug around nsswitch.conf which could create duplicate lines for `sudoers` and `automount`
  Contributed by Greg Perry (@gsperry2011)

* Added ability to use Ubuntu 18.04 and 20.04
  Contributed by Brad Bishop (@bishopbm1)

* Added ability to specify `mail` and any additional `ldap_attributes` for IPA users.
  Contributed by Nick Maludy (@nmaludy)

## v0.2.2 (2024-03-13)
* Added support for Ubuntu 22.04
  Contributed by Greg Perry (@gsperry2011)

## v0.2.1 (2021-01-21)
* Fixed bug with `initial_password` in `ipa_user`.
  Contributed by Nick Maludy (@nmaludy)

## v0.2.0 (2021-01-21)
* Added new resources `ipa::user` and `ipa_user` to manage IPA users and their home directories.
  Contributed by Nick Maludy (@nmaludy)

* Fixed bug in `ipa_kinit` where exired kerberos tickets weren't getting filtered out
  resulting in `ipa_kinit` thinking a valid ticket existed for a user since it was in
  the list.
  Contributed by Nick Maludy (@nmaludy)

## v0.1.1 (2021-01-15)
* Fixed bug in client install where /etc/nsswitch.conf was declared twice for file_line
  Contributed by Nick Maludy (@nmaludy)

* Fixed/added ciphers for RHEL/CentOS 8. Also allowed ciphers to be passed in empty for debugging.
  Contributed by Nick Maludy (@nmaludy)

## v0.1.0 (2021-01-14)
* Initial release
