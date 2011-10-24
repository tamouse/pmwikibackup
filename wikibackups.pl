#!/usr/bin/perl -w
#
# wikibackups - backup wikis
#
# Author: Tamara Temple <tamara@tamaratemple.com>
# Created: 2011/10/23
# Time-stamp: <2011-10-23 19:30:42 tamara>
# Copyright (c) 2011 Tamara Temple Web Development
# License: GPLv3
#

use strict;
use YAML::Syck;
use Data::Dumper;
use Getopt::Std;

my $VERSION = '0.1';

our($opt_n,$opt_d,$opt_v,$opt_V,$opt_h);
usage() unless getopts('vndVh');
usage() if $opt_h;
version() if $opt_V;

my $debug=$opt_d;
my $verbose=$opt_v;
my $dryrun=($opt_n?"--dry-run":"");

my $configfilename = $ENV{'HOME'}."/.wbu.rc";
if (! -r $configfilename) {
    die("No rc file found!");
}
my $config_ref = LoadFile($configfilename);

my $inclusions_file="/tmp/inc.$$";
my $exclusions_file="/tmp/exc.$$";



if (! $config_ref) {
    die("Errors loading rc file!");
}

my %config = %$config_ref;

print "\%config=".Dumper(%config) if $debug;

foreach my $wiki (keys %config) {
    my $thiswiki_ref = $config{$wiki};
    my %thiswiki = %$thiswiki_ref;
    backup_wiki(\%thiswiki,$wiki);
}

sub backup_wiki {
    my $wiki_ref = shift @_;
    my $wikiname = shift @_;
    my %wiki = %$wiki_ref;
    print "Backing up $wikiname\n" if $verbose;
    save_exclusions($wiki{'exclusions'},$wikiname);
    my $cmd="rsync $dryrun -azv --exclude-from=$exclusions_file.$wikiname ".$wiki{'user'}.'@'.$wiki{'host'}.':'.$wiki{'path'}." ".$wiki{'backuppath'}.$wikiname;
    print "$cmd\n" if $verbose;
    # return if $debug;
    my @result = qx{$cmd};
    die("rsync failed: $?") if $#result < 0;
    print "result:\n" if $verbose;
    print join("",@result),"\n" if $verbose;
    print "\n" if $verbose;
}

sub save_exclusions
{
    my $excl_ref = shift @_;
    my @excl = @$excl_ref;
    print Dumper(@excl) if $debug;
    @excl = map { (convert($_)) } @excl;
    print Dumper(@excl) if $debug;

    my $wikiname = shift @_;
    open(FH,">","$exclusions_file.$wikiname") or die("Could not open $exclusions_file");
    print FH join("\n",@excl)."\n";
    close FH;
    print "\nExclusions:\n" if $verbose;
    print join("\n",@excl)."\n" if $verbose;
    
}

sub convert {
    my $s = shift @_;
    $s =~ s/^i /+ /;
    $s =~ s/^e /- /;
    print "in convert: \$s=$s\n" if $debug;
    return $s;
}



sub version {
    print "$0 version: $VERSION\n";
    exit;
}

sub usage {
    print "$0 [-d] [-v] [-V]\n";
    print "\n";
    print "where:\n";
    print "   -d - turns on debug messages\n";
    print "   -v - turns on verbose mode\n";
    print "   -V - shows version\n";
    print "   -h or -? - gives this help message\n";
    print "\n";
    exit;
}


# ****************
# Documentation!!!
# ****************
    
=pod

=head1 NAME

=over 2

wikibackups.pl

=back

=head1 SYNOPSIS

=over 4

wikibackups.pl B<[-n]> B<[-v]> B<[-d]>

wikibackups.pl B<[-h]>

wikibackups.pl B<[-V]>

=back

=head1 DISCUSSION

=over 2

B<wikibackups.pl> provides a way of automating backups of L<http://www.pmwiki.org/> wikis. This script uses the C<rsync(1)> to handle the actual file transfer. Various inclusions and exclusion can be set (see L<"CONFIGURATION">).

More discussion on backing up your wiki can be found at L<http://www.pmwiki.org/wiki/PmWiki/BackupAndRestore>.

=back 

=head1 OPTIONS

=over 4

B<-n> - dry run only. If used with B<-v> will show the list of files which rsync would have transfered.

B<-v> - verbose mode. Will print out what is going on during the backup, including the output from the rsync command.

B<-d> - debug mode. Will print out all sorts of internal structure information. Useful for checking your configuration file. If you want to check your configuration, make sure to set -n and -v as well.

B<-h> - help. Prints a usage message.

B<-V> - version. Prints the script version.

=back

=head1 CONFIGURATION

=over 2

Configuration of wikibackup.pl is handled with a YAML file C<$HOME/.wbu.rc>. There currently are no options to move this file anywhere else.

YAML (see L<http://yaml.org/>) is a handy language to set up nested configurations with. It generally has the syntax of:

   item1: value1
   item2: value2
     item2.1: value2.1
     item2.2: value2.2
       item2.2.1: value2.2.1
   item2.3: value2.3

And so on.

The C<.wbu.rc> file is configured thusly:

   # 
   # Configuration file for wikibackup.pl
   #
   # This is YAML!
   wiki:
      user: remote login 
      host: remote host
      path: path/to/wiki
   # the wiki name above will be appended to the backuppath:
      backuppath: path/to/backup/root
   # Inclusions are marked by "i"
   # Exclusions are marked by "e"
      exclusions:
          - i /cookbook/
          - i /wiki.d/
          - e /wiki.d/.flock
          - e /wiki.d/.pageindex
          - e /wiki.d/.lastmod
          - e /wiki.d/*,del-*
          - e /wiki.d/*/*,del-*
          - i /pub/
          - i /local/
          - i /uploads/
          - e /*
          - e **~
          - e **.bak
          - e **.tgz
          - e **.zip
          - e **.gz
          - e **.Z

Most of the entries should make sense if you're familiar with the structure of the wiki's directories.

A breakdown of the configuration follows:

=back

=over 6

B<wiki> - this is the name you give your particular wiki. It doesn't have to be the same as C<$WikiTitle>, but it's helpful if it at least resembles that. This value will be appened to the C<backuppath> configuration value.

B<user> - this is the user you will log into the remote host with via rsync. You need ssh access to the remote host, and this will work without interruption or user intervention if you have placed your local public ssh key in the .ssh/authorized_keys file on the remote host.

B<host> - this is the remote server host name, however you access it via ssh.

B<path> - this is the path to your wiki from the user@host login directory. Examples include:

  /var/www/vhosts/example.com/htdocs/wiki
  /var/www/htdocs
  /Library/WebServer/Documents/wiki
  etc...

B<backuppath> - this is where you want your local backups stored. For the final destination, B<wiki> is appended to B<backuppath>. For example, if you wiki name is C<MyWiki>, and the backup path is C</Volumes/Archive/WikiBackups>, then the final destination will be C</Volumes/Archive/WikiBackups/MyWiki>.

B<exclusions> - here is where you list what to include and exclude from your backup. See L<"Configuring Exclusions">.

=back

=over 2

Lines that begin with an octothorpe (#) are treated a comments. 

=back

=head2 Warning about TABS in YAML input

YAML chokes on tab characters in it's input. Make sure to always use spaces to perform indenting. (Emacs has an C<untabify> function that's particularly useful for this.)

=head2 Configuring Exclusions

=over 2

This may be the most difficult part of this. C<rsync>'s method of filtering what gets sent and what doesn't is pretty arcane. Some rules of thumb, though:

=back

=over 6

=item *

Inclusions must precede Exclusions.

=item * 

If an item begins with a directory separator (/), then it is considered only at the root of the rsync path.

=item *

If an item ends with a directory separator (/) then it is treated as a directory and it's inclusion or exclusion applies to it and everything below.

=item *

Normal shell globbing is used, so C<something*> will match everything that begins with "something":

  something
  something.png
  somethingelse.txt
  something.nice.for.you.try

=item *

In the configuration file, inclusions are marked by B<i> in the configuration file -- this is converted to a B<+> for rsync's filter file. Likewise, exclusions are marked by B<e> in the configuration file -- these are converted to B<-> for rsync's filter file.

=back

=head1 EXAMPLES

=over 2

This will perform a backup of B<mywiki>, on server B<wiki.example.com>, user B<me>, with the path to wiki in the directory B<public_html/wiki> in the user's login area.

   mywiki:
      user: me
      host: wiki.example.com
      path: public_html/wiki
      backuppath: /Volumes/Archive/WikiBackups
      exclusions:
        - i /cookbook/
        - i /wiki.d/
        - e /wiki.d/.flock
        - e /wiki.d/.pageindex
        - e /wiki.d/.lastmod
        - e /wiki.d/*,del-*
        - e /wiki.d/*/*,del-*
        - i /pub/
        - i /local/
        - i /uploads/
        - e /*

The exclusions section is as follows:

=back

=over 6

B<i /cookbook/> - include the cookbook directory, but only from the top level. This will include the entire contents of the C<cookbook> directory, but it won't include any occurances of C<cookbook> in other root directories lower down.

B<i /wiki.d/> - include the C<wiki.d> directory, but again, only from the top level.

B<e /wiki.d/.flock> - exclude the .flock file that pmwiki uses to control access. This is a generated file and should not be backed up or restored.

B<e /wiki.d/.pageindex> - exclude the .pageindex file that pmwiki creates to index wiki pages. This is also a generated file and should not be backed up or restored.


B<e /wiki.d/.lastmod> - exclude the .lastmod file that pmwiki creates. This is generated as well, and should not be backed up or restored.

B<e /wiki.d/*,del-*> - this is the pattern used by pmwiki to denote delete wiki pages. If you do want to keep these in a backup, remove this line.

B<e /wiki.d/*/*,del-*> - this is similar to the above, but works when your pages are stored in group directories.

B<i /pub/> - the public directory for skins, themes, buttons, images, etc that you use to customize your wiki.

B<i /local/> - the local directory where you store you local configuration files.

B<i /uploads/> - uploads directory where attachments to pages are stored. Definitely want to keep this backed up along with the pages themselves.

B<e /*> - this is the last entry in this set -- it is telling rsync to exclude everything not explicitly included in the copy. This is the magic that makes it all work.

=back

=head2 Some additional helpful exclusions

=over 2

Sometimes, when working on a wiki installation, there may be cruft that gets left behind that you don't really want in your backups. Editor and tool backup files, downloaded archive and compressed files, etc. To deal with these, rsync looks at a double C<**> and says "match anything, regardless of directory". The single C<*> will match only within a directory (between directory separators (C</>)). The double star then makes it convenient for matching file types anywhere. Here are some examples:

          - e **~
          - e **.bak
          - e **.tgz
          - e **.zip
          - e **.gz
          - e **.Z


=back

=over 6

B<e **~> - typically editor backup files, especially C<Emacs>.

B<e **.bak> - typically utility or filter backup files, such as from C<sed> or C<perl>

B<e **.tgz> - a tarball (gzipped tar file).

B<e **.zip> - a zip compressed file.

B<e **.gz> - a gzip compressed file.

B<e **.Z> - another type of compressed file.

=back

=over 2

There are probably other kinds of files that you may have laying around that you don't really want to include in a site backup.

=back

=head1 PERIODIC BACKUPS

=over 2

Before scheduling this script automatically, make sure it works! Test the configuration using the -d, -v, and -n switches. When you are satisfied with how it is set up, then run it live once with -v turned on and make sure that you do get what you think you should. PmWikis' data doesn't tend to be very large, unless you have a lot of media stored as attachments. (If that is the case, you may consider another backup solution for your media.)

Once you're satisfied everything is working correctly, you can add the script, without paramters, to you likely cron-type queue (cron, anacron, periodic, launchd, etc.). Set it to go off on a schedule for backing up that you feel comfortable with. In a fairly active wiki, daily should be the minimum. If you're wiki doesn't change much week-to-week or month-to-month, longer backup periods can be justified. It's entirely up to you. For most people, daily will be about right.

=back

=head1 OTHER CONSIDERATIONS

=over 2

C<rsync> has a very rich feature set, this application has barely scraped the top off the barrel. C<rsync> is used as the engine for many *nix-based backup utilities because of it's robustness, speed, and versatility. Explore the C<rsync> feature set and perhaps improve upon this script.

=back

=head1 TODO

=over 6

=item *

Discuss how to restore a file from the rsync backup.

=item *

Have a better method for creating backup directories. Allow some form of rotation or advancing scheme for incremental backups and full backups.

=back


=head1 SEE ALSO

=over 2

L<http://www.pmwiki.org/wiki/PmWiki/BackupAndRestore>, L<http://www.pmwiki.org/wiki/Cookbook/BackUpPages>, Thread (L<http://thread.gmane.org/gmane.comp.web.wiki.pmwiki.user/20317>) on the pmwiki-users group

=back

=head1 AUTHOR(S)

=over 2

Tamara Temple <tamara @ tamaratemple.com> L<http://www.pmwiki.org/wiki/Profiles/Tamouse>

=back

=cut

