# Write a "main" configuration file for backupninja.  Effectively, it does
# little more than just take the config options you specify in the define and
# write them to the config file as-is.
#
define backupninja::config(
  $configfile = '/etc/backupninja.conf', $loglvl = 4, $when = 'everyday at 01:00',
  $reportemail = 'root', $reportsuccess = false, $reportwarning = true,
  $reporthost = $reporthost, $reportuser = $reportuser,
  $reportdirectory = $reportdirectory,
  $logfile = '/var/log/backupninja.log', $configdir = '/etc/backup.d',
  $scriptdir = '/usr/share/backupninja', $libdir = '/usr/lib/backupninja',
  $usecolors = true, $vservers = false)
{
  file { $configfile:
    content => template('backupninja/backupninja.conf.erb'),
    owner => root,
    group => root,
    mode => 0644
  }
}

# Write the backupninja cron job, allowing you to specify an alternate backupninja
# command (if you want to wrap it in any other commands, e.g. to allow it to use
# the monkeysphere for authentication), or a different schedule to run it on.
define backupninja::cron(
  $backupninja_cmd = '/usr/sbin/backupninja',
  $backupninja_test_cmd = $backupninja_cmd,
  $cronfile = "/etc/cron.d/backupninja",
  $min = "0", $hour = "*", $dom = "*", $month = "*",
  $dow = "*")
{
  file { $cronfile:
    content => template('backupninja/backupninja.cron.erb'),
    owner => root,
    group => root,
    mode => 0644
  }
}
