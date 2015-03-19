class backupninja::client inherits backupninja::client::defaults {
  define key(
    $user = false, $host = false, $createkey=false, $installkey=false,
    $keyowner=false, $keygroup=false, $keystore=false, $keystorefspath='',
    $keytype=false,
    $keydest=false, $keydestname=false )
  {
    $real_user = $user ? {
      false => $name,
      default => $user
    }
    $real_host = $host ? {
      false => $user,
      default => $host
    }
    $install_key = $installkey ? {
    	false => "${backupninja::client::defaults::real_keymanage}",
	default => $installkey,
    }
    $key_owner = $keyowner ? {
    	false => "${backupninja::client::defaults::real_keyowner}",
	default => $keyowner,
    }
    $key_group = $keygroup ? {
    	false => "${backupninja::client::defaults::real_keygroup}",
	default => $keygroup,
    }
    $key_store = $keystore ? {
    	false => "${backupninja::client::defaults::real_keystore}",
	default => $keystore,
    }
    $key_type = $keytype ? {
    	''    => "${backupninja::client::defaults::real_keytype}",
    	false => "${backupninja::client::defaults::real_keytype}",
	default => $keytype,
    }
    $key_dest = $keydest ? {
      false   => "${backupninja::client::defaults::real_keydestination}",
      default => $keydest,
    }
    $key_dest_name = $keydestname ? {
      false => "id_$key_type",
      default => $keydestname,
    }
    $key_dest_file = "${key_dest}/${key_dest_name}"

    if $createkey == true {
      if $keystorefspath == false {
        err("need to define a destination directory for sshkey creation!")
      }
      $ssh_keys = ssh_keygen("${keystorefspath}/${key_dest_name}")
    }
      

    case $install_key {
      true: {
        if !defined(File["$key_dest"]) {
          file { "$key_dest":
            ensure => directory,
            mode => 0700, owner => $key_owner, group => $key_group,
          }
        }
        if !defined(File["$key_dest_file"]) {
          file { "$key_dest_file":
            source => "${key_store}/${key_dest_name}",
            mode => 0400, owner => $key_owner, group => $key_group,
            require => File["$key_dest"],
          }
        }
      }
    }
  }
}
