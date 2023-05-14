<?php
require_once '/srv/mediawiki/config/initialise/WikiForgeFunctions.php';
require WikiForgeFunctions::getMediaWiki( 'index.php' );
if ( $wgArticlePath === '/wiki/$1' ) {
	# Redirect to /wiki/ equivalent
	$output = RequestContext::getMain()->getOutput();
	$output->redirect( '/wiki' . $_SERVER['REQUEST_URI'], 302 );
	exit();
}
