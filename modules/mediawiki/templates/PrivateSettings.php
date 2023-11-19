<?php

// Database passwords
$wgDBadminpassword = '<%= @wikiadmin_password %>';
$wgDBpassword = '<%= @mediawiki_password %>';

// Extension:AWS AWS S3 credentials
$wmgAWSAccessKey = '<%= @aws_s3_access_key %>';
$wmgAWSAccessSecretKey = '<%= @aws_s3_access_secret_key %>';

// Extension:DiscordNotifications global webhook
$wmgGlobalDiscordWebhookUrl = '<%= @global_discord_webhook_url %>';
$wmgDiscordExperimentalWebhook = '<%= @discord_experimental_webhook %>';

// hCaptcha secret key
$wgHCaptchaSecretKey = '<%= @hcaptcha_secretkey %>';

// LDAP 'write-user' password
$wmgLdapPassword = "<%= @ldap_password %>";

// MediaWiki secret keys
$wgUpgradeKey = '<%= @mediawiki_upgradekey %>';
$wgSecretKey = $wi->wikifarm === 'wikitide' ?
	'<%= @mediawiki_wikitide_secretkey %>' :
	'<%= @mediawiki_wikiforge_secretkey %>';

// Noreply authentication
$wmgSMTPPassword = '<%= @noreply_password %>';
$wmgSMTPUsername = '<%= @noreply_username %>';

// Redis AUTH password
$wmgRedisPassword = '<%= @redis_password %>';

// Shellbox secret key
$wgShellboxSecretKey = '<%= @shellbox_secretkey %>';

// Miscellaneous

// External Data credentials for cslmodswikitide
$wmgExternalDataCredsCslmodswikitide = '<%= @mediawiki_externaldata_cslmodswikitide %>';
