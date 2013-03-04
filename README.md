Downloader
==========

Simple Perl script to download files linked in a HTTP(S) source. Requires wget, aria2 and libhtml-parser-perl.

Usage: downloader.pl < config >

The output filename will be: "$tag$title$extension"

Configuration
=============

The configuration file is written using Perl syntax, and supports the following
configuration options:

$location
---------

Download location

Default: Not set

$username
---------

HTTP(S) username

Default: Not set

$password
---------

HTTP(S) password

Default: Not set

$regex
------

Regex used to extract individual items.

Default: Matches RSS items

$titleGroup
-----------

Regex group used as the item filename

Default: 0

$urlGroup
---------

Regex group used as the download URL

Default: 1



$tag
----

Tag used for filename.

Default: None

$fileExtension
--------------

File extension to add after title.

Default: None

$connectionCount
----------------

Number of download threads used for each download.

Default: 1

$history
--------

History file. If it exists it will be used to track downloaded items.

Default: < config >.history

$cookiesFile
------------

Path to cookies file used by wget to download source. Not used to download items.

Default: None
