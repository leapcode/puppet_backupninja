# Run rsync as part of a backupninja run.
# Based on backupninja::rdiff

define backupninja::rsync(
  $order = 90, $ensure = present, $user = false, $home = false, $host = false,
  $ssh_dir_manage = true, $ssh_dir = false, $authorized_keys_file = false
  $installuser = true, $installkey = true, $key = false, $backuptag = false
  $home = false, $backupkeytype = "rsa", $backupkeystore = false, $extras = false,
  $nagios2_description = 'backups', $subfolder = 'rsync',

  $rm = false, $cp = false, $touch = false, $mv = false, $fsck = false,

  $log = false, $partition = false, $fscheck = false, $read_only = false,
  $mountpoint = false, $backupdir = false, $format = false, $days = '5',
  $keepdaily = false, $keepweekly = false, $keepmonthly = false, $lockfile = false,
  $nicelevel = 0, $enable_mv_timestamp_bug = false, $tmp = false, $multiconnection = false,

  $from = 'local', $rsync = false, $rsync_options = false,
  $testconnect = false, $protocol = false, $ssh = false, $port = false,
  $bandwidthlimit = false, $remote_rsync = false, $id_file = false,
  $batch = false, $filelist = false, $filelistbase = false,

  $exclude = [ "/home/*/.gnupg", "/home/*/.local/share/Trash", "/home/*/.Trash",
               "/home/*/.thumbnails", "/home/*/.beagle", "/home/*/.aMule",
               "/home/*/gtk-gnutella-downloads" ],
  $include = [ "/var/spool/cron/crontabs", "/var/backups", "/etc", "/root",
               "/home", "/usr/local/*bin", "/var/lib/dpkg/status*" ],

  $exclude_vserver = false, $numericids = false, $compress = false,

  $dest = false, $fakesuper = false, $batchname = false,

  $initscripts = false, $service = false)
{
  include backupninja::client::rsync

  case $dest {
    'remote': {
      case $host { false: { err("need to define a host for remote backups!") } }

      $real_backuptag = $backuptag ? {
          false   => "backupninja-$fqdn",
          default => $backuptag
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
        nagios2_description  => $nagios2_description
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

  file { "${backupninja::client::defaults::configdir}/${order}_${name}.rsync":
    ensure  => $ensure,
    content => template('backupninja/rsync.conf.erb'),
    owner   => root,
    group   => root,
    mode    => 0600,
    require => File["${backupninja::client::defaults::configdir}"]
  }
}
