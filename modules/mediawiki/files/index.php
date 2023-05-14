<?php
require_once '/srv/mediawiki/config/initialise/WikiForgeFunctions.php';
require WikiForgeFunctions::getMediaWiki( 'index.php' );
if ( $wgArticlePath === '/wiki/$1' && $_SERVER['REQUEST_URI'] === '/' ) {
	# Redirect to /wiki/ equivalent
	$output = RequestContext::getMain()->getOutput();
	$output->redirect( '/wiki/', 302 );
	exit();
}
