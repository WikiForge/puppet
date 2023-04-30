#!/usr/bin/env php
<?php

error_reporting( 0 );

require_once '/srv/mediawiki/config/initialise/WikiForgeFunctions.php';

echo implode( "\n", WikiForgeFunctions::MEDIAWIKI_VERSIONS );
