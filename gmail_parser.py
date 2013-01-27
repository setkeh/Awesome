## check-gmail.py -- A command line util to check GMail -*- Python -*-
## modified to display mailbox summary for conky

# ======================================================================
# Copyright (C) 2006 Baishampayan Ghose <b.ghose@ubuntu.com>
# Modified 2008 Hunter Loftis <hbloftis@uncc.edu>
# Time-stamp: Mon Jul 31, 2006 20:45+0530
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
# ======================================================================

import sys
import urllib             # For BasicHTTPAuthentication
import feedparser         # For parsing the feed
from textwrap import wrap

_URL = "https://mail.google.com/gmail/feed/atom"

uname = sys.argv[1]
password = sys.argv[2]
maxlen = sys.argv[3]

urllib.FancyURLopener.prompt_user_passwd = lambda self, host, realm: (uname, password)
	
def auth():
    '''The method to do HTTPBasicAuthentication'''
    opener = urllib.FancyURLopener()
    f = opener.open(_URL)
    feed = f.read()
    return feed


def readmail(feed, maxlen):
	'''Parse the Atom feed and print a summary'''
	atom = feedparser.parse(feed)
	print '${color1} %s new email(s)\n' % (len(atom.entries))
	for i in range(min(len(atom.entries), maxlen)):
		print '          ${color2}%s' % atom.entries[i].title
#uncomment the following line if you want to show the name of the sender
#		print '          ${color2}%s' % atom.entries[i].author
	if len(atom.entries) > maxlen:
		print ' ${color}more...'

if __name__ == "__main__":
    f = auth()  # Do auth and then get the feed
    readmail(f, int(maxlen)) # Let the feed be chewed by feedparser
