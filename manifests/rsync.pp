# Run rsync as part of a backupninja run.
# Based on backupninja::rdiff

define backupninja::rsync(
  $order = 90, $ensure = present,
  $user = false, $home = false, $host = false,
  $ssh_dir_manage = true, $ssh_dir = false, $authorized_keys_file = false,
  $installuser = true, $installkey = true, $key = false, $backuptag = false,
  $home = false, $backupkeytype = $backupninja::keytype, $backupkeystore = $backupninja::keystore, $extras = false,
  $nagios_description = 'backups', $subfolder = 'rsync',

  $log = false, $partition = false, $fscheck = false, $read_only = false,
  $mountpoint = false, $backupdir = false, $format = false, $days = false,
  $keepdaily = false, $keepweekly = false, $keepmonthly = false, $lockfile = false,
  $nicelevel = 0, $enable_mv_timestamp_bug = false, $tmp = false, $multiconnection = false,

  $exclude_vserver = false,
  $exclude = [ "/home/*/.gnupg", "/home/*/.local/share/Trash", "/home/*/.Trash",
               "/home/*/.thumbnails", "/home/*/.beagle", "/home/*/.aMule",
               "/home/*/gtk-gnutella-downloads" ],
  $include = [ "/var/spool/cron/crontabs", "/var/backups", "/etc", "/root",
               "/home", "/usr/local/*bin", "/var/lib/dpkg/status*" ],

  $testconnect = false, $protocol = false, $ssh = false, $port = false,
  $bandwidthlimit = false, $remote_rsync = false, $id_file = false,
  $batch = false, $batchbase = false, $numericids = false, $compress = false,
  $fakesuper = false,

  $initscripts = false, $service = false,

  $rm = false, $cp = false, $touch = false, $mv = false, $fsck = false)
{
  # install client dependencies
  ensure_resource('package', 'rsync', {'ensure' => $backupninja::client::ensure_rsync_version})

  # Right now just local origin with remote destination is supported.
  $from = 'local'
  $dest = 'remote'

  case $dest {
    'remote': {
      case $host { false: { err("need to define a host for remote backups!") } }

      $real_backuptag = $backuptag ? {
        false   => "backupninja-$fqdn",
        default => $backuptag,
      }

      $real_home = $home ? {
        false   => "/home/${user}-${name}",
        default => $home,
      }

      $directory = "${real_home}/${subfolder}/"

      backupninja::server::sandbox { "${user}-${name}":
        user                 => $user,
        host                 => $host,
        dir                  => $real_home,
        manage_ssh_dir       => $ssh_dir_manage,
        ssh_dir              => $ssh_dir,
        key                  => $key,
        authorized_keys_file => $authorized_keys_file,
        installuser          => $installuser,
        backuptag            => $real_backuptag,
        keytype              => $backupkeytype,
        backupkeys           => $backupkeystore,
        nagios_description  => $nagios_description
      }
     
      backupninja::client::key { "${user}-${name}":
        user       => $user,
        host       => $host,
        installkey => $installkey,
        keytype    => $backupkeytype,
        keystore   => $backupkeystore,
      }
    }
  }

  file { "${backupninja::configdir}/${order}_${name}.rsync":
    ensure  => $ensure,
    content => template('backupninja/rsync.conf.erb'),
    owner   => root,
    group   => root,
    mode    => 0600,
    require => File["${backupninja::configdir}"]
  }
}
