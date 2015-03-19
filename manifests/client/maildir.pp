class backupninja::client::maildir inherits backupninja::client::defaults {

  if !defined(Package["rsync"]) {
    if $rsync_ensure_version == '' { $rsync_ensure_version = 'installed' }
    package { 'rsync':
      ensure => $rsync_ensure_version,
    }
  }
}
