class backupninja (
  $ensure_backupninja_version = 'installed',
  $ensure_rsync_version = 'installed',
  $ensure_rdiffbackup_version = 'installed',
  $ensure_debconfutils_version = 'installed',
  $ensure_hwinfo_version = 'installed',
  $ensure_duplicity_version = 'installed',
  $configdir = '/etc/backup.d',
  $keystore = "${::fileserver}/keys/backupkeys",
  $keystorefspath = false,
  $keytype = 'rsa',
  $keydest = '/root/.ssh',
  $keyowner = 0,
  $keygroup = 0,
  $keymanage = true,
  $configfile = '/etc/backupninja.conf',
  $loglvl = 4,
  $when = 'everyday at 01:00',
  $reportemail = 'root',
  $reportsuccess = false,
  $reportwarning = true,
  $reporthost = undef,
  $reportuser = undef,
  $reportdirectory = undef,
  $logfile = '/var/log/backupninja.log',
  $configdir = '/etc/backup.d',
  $scriptdir = '/usr/share/backupninja',
  $libdir = '/usr/lib/backupninja',
  $usecolors = true,
  $vservers = false
) {

  # install client dependencies
  ensure_resource('package', 'backupninja', {'ensure' => $ensure_backupninja_version})

  # set up backupninja config directory
  file { $configdir:
    ensure => directory,
    mode => 750, owner => 0, group => 0;
  }

  define key(
    $user = $name,
    $createkey = false,
    $keymanage = $backupninja::keymanage,
    $keyowner = $backupninja::keyowner,
    $keygroup = $backupninja::keygroup,
    $keystore= $backupninja::keystore,
    $keystorefspath = $backupninja::keystorefspath,
    $keytype = $backupninja::keytype,
    $keydest = $backupninja::keydest,
    $keydestname = "id_${backupninja::keytype}" )
  {

    # generate the key
    if $createkey == true {
      if $keystorefspath == false {
        err("need to define a destination directory for sshkey creation!")
      }
      $ssh_keys = ssh_keygen("${keystorefspath}/${keydestname}")
    }

    # deploy/manage the key
    if $keymanage == true {
      $keydestfile = "${keydest}/${keydestname}"
      ensure_resource('file', $keydest, {
          'ensure' => 'directory',
          'mode'   => '0700',
          'owner'  => $keyowner,
          'group'  => $keygroup
      })
      ensure_resource('file', $keydestfile, {
          'ensure'  => 'present',
          'source'  => "${keystore}/${real_user}_id_${key_type}",
          'mode'    => '0700',
          'owner'   => $keyowner,
          'group'   => $keygroup,
          'require' => File["$keydest"],
      })
    }
  }

 file { $configfile:
    content => template('backupninja/backupninja.conf.erb'),
    owner => root,
    group => 0,
    mode => '0644'
  }

}
