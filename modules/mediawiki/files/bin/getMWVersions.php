#!/usr/bin/env php
<?php

error_reporting( 0 );

require_once '/srv/mediawiki/config/initialise/WikiForgeFunctions.php';

$versions = array_unique( WikiForgeFunctions::MEDIAWIKI_VERSIONS );
asort( $versions );

echo implode( "\n", $versions );
