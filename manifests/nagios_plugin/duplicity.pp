class backupninja::nagios_plugin::duplicity {
  case ::operatingsystem {
    'Debian': { package { 'python-argparse': ensure => installed, } }
    'Ubuntu': { package { 'python-argh':     ensure => installed, } }
    default:  {
      notify {'Backupninja-Duplicity Nagios check needs python-argparse to be installed !':}  }
  }

  nagios::plugin { 'check_backupninja_duplicity.py':
    source => 'backupninja/nagios_plugins/duplicity/check_backupninja_duplicity.py'
  }

  # deploy helper script
  file { '/usr/lib/nagios/plugins/backupninja_duplicity_freshness.sh':
    source => 'puppet:///modules/backupninja/nagios_plugins/duplicity/backupninja_duplicity_freshness.sh',
    mode   => '0755',
    owner  => 'nagios',
    group  => 'nagios',
  }

}

