#!/usr/bin/perl
# Download anything script
# -- Christian Auby (DesktopMan)

# Import libraries
use HTML::Entities;

# Check if configuration file exists
die "Usage: downloader.pl <config file>\n" if ! -f @ARGV[0];

my $configFile = @ARGV[0];

print "Using configuration '$configFile'\n";

# Default regex (matches RSS)
$regex = '<item>.*?<title>(.*?)<\/title>.*?<enclosure url="(.*?)".*?<\/item>';

# default group number for title
$titleGroup = 0;

# Default group number for url
$urlGroup = 1;

# Default file tag
$tag = "";

# Default file extension
$fileExtension = "";

# Default connection count
$connectionCount = 1;

# History file
my $history = $configFile . ".history";

# Cookies file
$cookiesFile = "";

# Load configuration
do "$configFile";

# Check configuration
die "Download location not defined.\n" if !defined $location;
die "Download location is not a valid directory.\n" if ! -d $location;
die "URL not defined.\n" if !defined $url;

my $data = "";

if("$cookiesFile" eq "") {
	$data = `wget -q -O - --no-check-certificate --user="$username" --password="$password" "$url"`;
} else {
	$data = `wget -q --load-cookies "$cookies" -O - --no-check-certificate --user="$username" --password="$password" "$url"`;
}

@items = ($data =~ m/$regex/igs);

if(@items == 0)
{
	print "No items found. Exiting.\n";
	exit 1;
}

# Match count is result count / group count
my $count = @items / 2;

print "Found $count items.\n";

# Download each item unless already downloaded
for (my $i = 0; $i < $count; $i++)
{
	# Extract item information
	my $title = decode_entities(@items[$i * 2 + $titleGroup]);
	my $url = decode_entities(@items[$i * 2 + $urlGroup]);
	
	# Skip items with empty title or URL
	next if $title eq "";
	next if $url eq "";

	# Generate and clean up filename
	my $filename = $tag . $title . $fileExtension;

	$filename =~ s/\//-/g;
	$filename =~ s/:/ -/g;
	$filename =~ s/\?//g;
	$filename =~ s/\"//g;

	$filepath = "$location/$filename";

	print "Downloading \"$title\" ... ";
	
	# Check if file is in history, skip if it does
	if (checkHistory($title))
	{
		print "Skipping, found in history.\n";
		next;
	}

	# Check if file already exists, skip if it does
	if (-e $filepath)
	{
		print "Skipping, file exists.\n";
		next;
	}

	# Try to download
	$result = system("aria2c -x$connectionCount -d \"$location\" -o \"$filename\" \"$url\"");

	# Wait to prevent server trashing
	sleep(5);

	# Check for aria2c errors and clean up if there are any
	if ($result != 0)
	{
		print "Error. Skipping.\n";

		if (-e $filepath)
		{
			unlink($filepath);
		}
	}
	else
	{
		# Add file to history
		addHistory($title);
		
		print "Done.\n";
	}
}

sub checkHistory()
{
	my $file = $_[0];
	
	# If the history file does not exist return false
	open FILE, "$history" or return 0;
	
	# Check each line in history file
	while(my $line = <FILE>)
	{
		chomp $line;
		
		# Return true on match
		if($file eq $line)
		{
			close(FILE);
			return 1;
		}
	}
	
	close(FILE);
	
	return 0;
}

sub addHistory()
{
	# Return if history file does not exist
	return if ! -f $history;
	
	my $line = $_[0];
	
	# Open history file for appending
	open FILE, ">>$history" or return;
	
	print FILE "$line\n";
	
	close(FILE);
}

