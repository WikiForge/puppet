#!/usr/bin/env php
<?php

error_reporting( 0 );

require_once '/srv/mediawiki/config/initialize/WikiForgeFunctions.php';

if ( count( $argv ) < 2 ) {
	print "Usage: getMWVersion <dbname> \n";
	exit( 1 );
}

define( 'MW_DB', $argv[1] );

echo WikiForgeFunctions::getMediaWikiVersion( $argv[1] ) . "\n";
