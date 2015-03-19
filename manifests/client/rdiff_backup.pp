class backupninja::client::rdiff_backup inherits backupninja::client::defaults {

  if !defined(Package["rdiff-backup"]) {
    if $rdiff_backup_ensure_version == '' { $rdiff_backup_ensure_version = 'installed' }
    package { 'rdiff-backup':
      ensure => $rdiff_backup_ensure_version,
    }
  }
}
