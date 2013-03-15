#!/usr/bin/perl

use strict;
use warnings;
use Safe;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request;

# Download anything script
# -- Christian Auby (DesktopMan)

# Import libraries
use HTML::Entities;

# Check if configuration file exists
die "Usage: downloader.pl <config file>\n" if scalar @ARGV < 1 || !-f $ARGV[0];

my $configFile = $ARGV[0];

print "Using configuration '$configFile'\n";

# Default regex (matches RSS)
my $regex =
  '<item>.*?<title>(.*?)<\/title>.*?<enclosure url="(.*?)".*?<\/item>';

# default group number for title
my $titleGroup = 0;

# Default group number for url
my $urlGroup = 1;

# Default file tag
my $tag = "";

# Default file extension
my $fileExtension = "";

# Default connection count
my $connectionCount = 1;

# History file
my $history = $configFile . ".history";

# Cookies file
my $cookiesFile = "";

# Load configuration. So dirty!
my $box    = new Safe;
my $config = $box->rdo($configFile);
print Dumper($config);

# Check configuration
die "Download location not defined.\n" if not defined $config->{location};
die "Download location is not a valid directory.\n"
  if not -d $config->{location};
die "URL not defined.\n" if not defined $config->{url};

my $data = "";

my $ua = LWP::UserAgent->new;
$ua->cookie_jar({fILE => $config->{cookies}});

my $req = HTTP::Request->new(GET => $config->{url});
$req->authorization_basic($config->{username},$config->{password});

my $res = $ua->request($req);

if ($res->is_success) {
    $data = $res->decoded_content;
} else {
    die $res->status_line;
}

my @items = ( $data =~ m/$regex/igs );

if ( @items == 0 ) {
    die "No items found. Exiting.\n";
}

# Match count is result count / group count
my $count = @items / 2;

print "Found $count items.\n";

# Download each item unless already downloaded
for ( my $i = 0 ; $i < $count ; $i++ ) {

    # Extract item information
    my $title = decode_entities( @items[ $i * 2 + $titleGroup ] );
    my $url   = decode_entities( @items[ $i * 2 + $urlGroup ] );

    # Skip items with empty title or URL
    next if $title eq "";
    next if $url   eq "";

    # Generate and clean up filename
    my $filename = $tag . $title . $fileExtension;

    $filename =~ s/\//-/g;
    $filename =~ s/:/ -/g;
    $filename =~ s/\?//g;
    $filename =~ s/\"//g;

    my $filepath = $config->{location} . "/" . $filename;

    print "Downloading \"$title\" ... ";

    # Check if file is in history, skip if it does
    if ( checkHistory($title) ) {
        print "Skipping, found in history.\n";
        next;
    }

    # Check if file already exists, skip if it does
    if ( -e $filepath ) {
        print "Skipping, file exists.\n";
        next;
    }

    # Try to download
    my $result =
      system( "aria2c -x$connectionCount -d \""
          . $config->{location}
          . "\" -o \""
          . $filename . "\" \""
          . $config->{url}
          . "\"" );

    # Wait to prevent server trashing
    sleep(5);

    # Check for aria2c errors and clean up if there are any
    if ( $result != 0 ) {
        print "Error. Skipping.\n";

        if ( -e $filepath ) {
            unlink($filepath);
        }
    }
    else {

        # Add file to history
        addHistory($title);

        print "Done.\n";
    }
}

sub checkHistory {
    my ($file) = @_;

    # If the history file does not exist return false
    open FILE, "$history" or return 0;

    # Check each line in history file
    while ( my $line = <FILE> ) {
        chomp $line;

        # Return true on match
        if ( $file eq $line ) {
            close(FILE);
            return 1;
        }
    }

    close(FILE);

    return 0;
}

sub addHistory {

    # Return if history file does not exist
    return if !-f $history;

    my ($line) = @_;

    # Open history file for appending
    open FILE, ">>$history" or return;

    print FILE "$line\n";

    close(FILE);
}

