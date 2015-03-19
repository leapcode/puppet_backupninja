class backupninja::client::duplicity inherits backupninja::client::defaults {

  if !defined(Package["duplicity"]) {
    if $duplicity_ensure_version == '' { $duplicity_ensure_version = 'installed' }
    package { 'duplicity':
      ensure => $duplicity_ensure_version,
    }
  }
}
