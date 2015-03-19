class backupninja::client::sys inherits backupninja::client::defaults {
  case $operatingsystem {
    debian,ubuntu: {
      if !defined(Package["debconf-utils"]) {
	if $debconf_utils_ensure_version == '' { $debconf_utils_ensure_version = 'installed' }
	package { 'debconf-utils':
	  ensure => $debconf_utils_ensure_version,
	}
      }
      if !defined(Package["hwinfo"]) {
	if $hwinfo_ensure_version == '' { $hwinfo_ensure_version = 'installed' }
	package { 'hwinfo':
	  ensure => $hwinfo_ensure_version,
	}
      }
    }
    default: {}
  }
}
