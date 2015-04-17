#!/usr/bin/perl -w

# This script is designed to check a backup directory populated with
# subdirectories named after hosts, within which there are backups of various
# types.
#
# Example:
# /home/backup:
# foo.example.com
# 
# foo.example.com:
# rdiff-backup .ssh
#
# rdiff-backup:
# root home rdiff-backup-data usr var
#
# There are heuristics to determine the backup type. Currently, the following
# types are supported:
#
# rdiff-backup: assumes there is a rdiff-backup/rdiff-backup-data/backup.log file
# duplicity: assumes there is a dup subdirectory, checks the latest file
# dump files: assumes there is a dump subdirectory, checks the latest file
#
# This script returns output suitable for send_nsca to send the results to
# nagios and should therefore be used like this:
#
# checkbackups.sh | send_nsca -H nagios.example.com

use Getopt::Std;

# XXX: taken from utils.sh from nagios-plugins-basic
my $STATE_OK=0;
my $STATE_WARNING=1;
my $STATE_CRITICAL=2;
my $STATE_UNKNOWN=3;
my $STATE_DEPENDENT=4;

# gross hack: we look into subdirs to find vservers
my @vserver_dirs = qw{/var/lib/vservers /vservers};

our $opt_d = "/backup";
our $opt_c = 48 * 60 * 60;
our $opt_w = 24 * 60 * 60;
our $opt_v = 0;
our $opt_o;

if (!getopts('d:c:w:vo')) {
	print <<EOF
Usage: $0 [ -d <backupdir> ] [ -c <threshold> ] [ -w <threshold> ] [ -o ] [ -v ]
EOF
	;
	exit();
}

sub check_rdiff {
    my ($host, $dir, $subdir, $optv) = @_;
    my $flag="$dir/$subdir/rdiff-backup-data/backup.log";
    my $extra_msg = '';
    my @vservers;
    if (open(FLAG, $flag)) {
        while (<FLAG>) {
            if (/StartTime ([0-9]*).[0-9]* \((.*)\)/) {
                $last_bak = $1;
                $extra_msg = ' [backup.log]';
                $opt_v && print STDERR "found timestamp $1 ($2) in backup.log\n";
            }
        }
        if (!$last_bak) {
            print_status($host, $STATE_UNKNOWN, "cannot parse backup.log for a valid timestamp");
            next;
        }
    } else {
        $opt_v && print STDERR "cannot open backup.log\n";
    }
    close(FLAG);
    ($state, $delta) = check_age($last_bak);
    print_status($host, $state, "$delta seconds old$extra_msg");
    foreach my $vserver_dir (@vserver_dirs) {
        $vsdir = "$dir/${subdir}$vserver_dir";
        if (opendir(DIR, $vsdir)) {
            @vservers = grep { /^[^\.]/ && -d "$vsdir/$_" } readdir(DIR);
            $opt_v && print STDERR "found vservers $vsdir: @vservers\n";
            closedir DIR;
        } else {
            $opt_v && print STDERR "no vserver in $vsdir\n";
        }
    }
    my @dom_sufx = split(/\./, $host);
    my $dom_sufx = join('.', @dom_sufx[1,-1]);
    foreach my $vserver (@vservers) {
        print_status("$vserver.$dom_sufx", $state, "$delta seconds old$extra_msg, same as parent: $host");
    }
}

sub check_age {
    my ($last_bak) = @_;
    my $t = time();
    my $delta = $t - $last_bak;
    if ($delta > $opt_c) {
        $state = $STATE_CRITICAL;
    } elsif ($delta > $opt_w) {
        $state = $STATE_WARNING;
    } elsif ($delta >= 0) {
        $state = $STATE_OK;
    }
    return ($state, $delta);
}

sub print_status {
    my ($host, $state, $message) = @_;
    printf "$host\tbackups\t$state\t$message\n";
}

sub check_flag {
    my ($host, $flag) = @_;
    my @stats = stat($flag);
    if (not @stats) {
        print_status($host, $STATE_UNKNOWN, "cannot stat flag $flag");
    }
    else {
        ($state, $delta) = check_age($stats[9]);
        print_status($host, $state, "$delta seconds old");
    }
}

my $backupdir= $opt_d;

my @hosts;
if (defined($opt_o)) {
	@hosts=qx{hostname -f};
} else {
	# XXX: this should be a complete backup registry instead
	@hosts=qx{ls $backupdir | grep -v lost+found};
}

chdir($backupdir);
my ($delta, $state, $host);
foreach $host (@hosts) {
	chomp($host);
	if ($opt_o) {
		$dir = $backupdir;
	} else {
		$dir = $host;
	}
	my $flag="";
	if (-d $dir) {
		# guess the backup type and find a proper stamp file to compare
		# XXX: the backup type should be part of the machine registry
		my $last_bak;
		if (-d "$dir/rdiff-backup") {
                    check_rdiff($host, $dir, 'rdiff-backup', $opt_v);
		} elsif (-d "$dir/dump") {
			# XXX: this doesn't check backup consistency
			$flag="$dir/dump/" . `ls -tr $dir/dump | tail -1`;
			chomp($flag);
			check_flag($host, $flag);
		} elsif (-d "$dir/dup") {
			# XXX: this doesn't check backup consistency
			$flag="$dir/dup/" . `ls -tr $dir/dup | tail -1`;
			chomp($flag);
			check_flag($host, $flag);
		} elsif (-r "$dir/rsync.log") {
			# XXX: this doesn't check backup consistency
			$flag="$dir/rsync.log";
			check_flag($host, $flag);
		} else {
                        print_status($host, $STATE_UNKNOWN, 'unknown system');
		}
	} else {
            print_status($host, $STATE_UNKNOWN, 'no directory');
	}
}
