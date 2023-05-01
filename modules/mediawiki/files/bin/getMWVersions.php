#!/usr/bin/env php
<?php

error_reporting( 0 );

require_once '/srv/mediawiki/config/initialise/WikiForgeFunctions.php';

if ( ( $argv[1] ?? false ) === 'all' ) {
	echo json_encode( WikiForgeFunctions::MEDIAWIKI_VERSIONS );
	exit( 0 );
}

$versions = array_unique( WikiForgeFunctions::MEDIAWIKI_VERSIONS );
asort( $versions );

echo json_encode( array_combine( $versions, $versions ) );
