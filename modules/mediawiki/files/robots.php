<?php

define( 'MW_NO_SESSION', 1 );

require_once '/srv/mediawiki/config/initialise/WikiForgeFunctions.php';
require WikiForgeFunctions::getMediaWiki( 'includes/WebStart.php' );

use MediaWiki\MediaWikiServices;

$wikiPageFactory = MediaWikiServices::getInstance()->getWikiPageFactory();
$titleFactory = MediaWikiServices::getInstance()->getTitleFactory();

$page = $wikiPageFactory->newFromTitle( $titleFactory->newFromText( 'Robots.txt', NS_MEDIAWIKI ) );

header( 'Content-Type: text/plain; charset=utf-8' );
header( 'X-WikiForge-Robots: Default' );

$articlePath = str_replace( '$1', '', $wgArticlePath );

# Throttle access to certain pages
echo "User-agent: *" . "\r\n";
echo "Allow: /w/api.php?action=mobileview&" . "\r\n";
echo "Allow: /w/load.php?" . "\r\n";
echo "Disallow: /w/" . "\r\n";
echo "Disallow: /geoip$" . "\r\n";
echo "Disallow: /rest_v1/" . "\r\n";
echo "Disallow: {$articlePath}Special:" . "\r\n";
echo "Disallow: {$articlePath}Spezial:" . "\r\n";
echo "Disallow: {$articlePath}Spesial:" . "\r\n";
echo "Disallow: {$articlePath}Special%3A" . "\r\n";
echo "Disallow: {$articlePath}Spezial%3A" . "\r\n";
echo "Disallow: {$articlePath}Spesial%3A" . "\r\n";
echo "Disallow: {$articlePath}Property:" . "\r\n";
echo "Disallow: {$articlePath}Property%3A" . "\r\n";
echo "Disallow: {$articlePath}property:" . "\r\n";
echo "Disallow: {$articlePath}Especial:" . "\r\n";
echo "Disallow: {$articlePath}Especial%3A" . "\r\n";
echo "Disallow: {$articlePath}especial:" . "\r\n\n";

# Throttle BingBot
echo "# Throttle BingBot" . "\r\n";
echo "User-agent: bingbot" . "\r\n";
echo "Crawl-delay: 5" . "\r\n\n";

# Block SemrushBot
echo "# Block SemrushBot" . "\r\n";
echo "User-agent: SemrushBot" . "\r\n";
echo "Disallow: /" . "\r\n\n";

# Block MJ12Bot
echo "# Block MJ12Bot" . "\r\n";
echo "User-agent: MJ12bot" . "\r\n";
echo "Disallow: /" . "\r\n\n";

# Block AhrefsBot
echo "# Block AhrefsBot" . "\r\n";
echo "User-agent: AhrefsBot" . "\r\n";
echo "Disallow: /" . "\r\n\n";

# Block Bytespider
echo "# Block Bytespider" . "\r\n";
echo "User-agent: Bytespider" . "\r\n";
echo "Disallow: /" . "\r\n\n";

# Block PetalBot
echo "# Block PetalBot" . "\r\n";
echo "User-agent: PetalBot" . "\r\n";
echo "Disallow: /" . "\r\n\n";

# Block DotBot
echo "# Block DotBot" . "\r\n";
echo "User-agent: DotBot" . "\r\n";
echo "User-agent: dotbot" . "\r\n";
echo "Disallow: /" . "\r\n\n";

# Block MegaIndex
echo "# Block MegaIndex" . "\r\n";
echo "User-agent: MegaIndex.ru" . "\r\n";
echo "Disallow: /" . "\r\n\n";

echo "User-agent: megaindex.com" . "\r\n";
echo "Disallow: /" . "\r\n\n";

# Block serpstatbot
echo "# Block serpstatbot" . "\r\n";
echo "User-agent: serpstatbot" . "\r\n";
echo "Disallow: /" . "\r\n\n";

# Block Barkrowler
echo "# Block Barkrowler" . "\r\n";
echo "User-agent: barkrowler" . "\r\n";
echo "Disallow: /" . "\r\n\n";

# Block SeekportBot
echo "# Block SeekportBot" . "\r\n";
echo "User-agent: SeekportBot" . "\r\n";
echo "Disallow: /" . "\r\n\n";

# Dynamic sitemap url
echo "# Dynamic sitemap url" . "\r\n";
echo "Sitemap: {$wgServer}/sitemap.xml" . "\r\n\n";

if ( $page->exists() ) {
	header( 'X-WikiForge-Robots: Custom' );

	echo "# -- BEGIN CUSTOM -- #\r\n\n";

	$content = $page->getContent();

	echo ( $content instanceof TextContent ) ? $content->getText() : '';
}
