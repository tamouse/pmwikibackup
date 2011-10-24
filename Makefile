# Makefile
#
# @author Tamara Temple <tamara@tamaratemple.com>
# @since 2011/10/23
# @version Time-stamp: <2011-10-23 19:46:13 tamara>
# @copyright (c) Tamara Temple Web Development
# @license GPLv3
#

build: wikibackups.zip

wikibackups.zip: doc wikibackups.pl sample.wbu.rc
	zip wikibackups.zip wikibackups.pl wikibackups.1.man wikibackups.html sample.wbu.rc Makefile


doc: wikibackups.html wikibackups.1.man

wikibackups.html: wikibackups.1.man
	groff -mandoc wikibackups.1.man -T html > wikibackups.html

wikibackups.1.man: wikibackups.pl
	pod2man --center="PmWiki Backups Using Rsync" --name=wikibackups.pl --release="0.1" --section=1 --verbose wikibackups.pl wikibackups.1.man


clean:
	rm wikibackups.html wikibackups.1.man *~
