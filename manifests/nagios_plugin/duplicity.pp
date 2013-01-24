class backupninja::nagios_plugin::duplicity {
  case $::operatingsystem {
    'Debian': { package { 'python-argparse': ensure => installed, } }
    'Ubuntu': { package { 'python-argh':     ensure => installed, } }
    default:  {
      notify {'Backupninja-Duplicity Nagios check needs python-argparse to be installed !':}  }
  }

  file { '/usr/lib/nagios/plugins/check_backupninja_duplicity.py':
    source => 'puppet:///modules/backupninja/nagios_plugins/duplicity/check_backupninja_duplicity.py',
    mode   => '0755',
    owner  => 'nagios',
    group  => 'nagios',
  }

  # deploy helper script
  file { '/usr/lib/nagios/plugins/backupninja_duplicity_freshness.sh':
    source => 'puppet:///modules/backupninja/nagios_plugins/duplicity/backupninja_duplicity_freshness.sh',
    mode   => '0755',
    owner  => 'nagios',
    group  => 'nagios',
  }

  nagios::nrpe::command { 'check_backupninja_duplicity':
    command_line => "${::nagios::nrpe::nagios_plugin_dir}/check_backupninja_duplicity"
  }

  nagios::service { 'Backupninja Duplicity':
    use_nrpe              => true,
    check_command         => 'check_backupninja_duplicity',
    nrpe_timeout          => '60',
    # check only twice a day
    normal_check_interval => '720',
    # recheck every hour
    retry_check_interval  => '60',
  }
}
