<?php

// Database passwords
$wgDBadminpassword = "<%= @wikiadmin_password %>";
$wgDBpassword = "<%= @mediawiki_password %>";

// Redis AUTH password
$wmgRedisPassword = "<%= @redis_password %>";

// Noreply authentication password
$wmgSMTPPassword = "<%= @noreply_password %>";

// MediaWiki secret keys
$wgUpgradeKey = "<%= @mediawiki_upgradekey %>";
$wgSecretKey = "<%= @mediawiki_secretkey %>";

// hCaptcha secret key
$wgHCaptchaSecretKey = "<%= @hcaptcha_secretkey %>";

// Shellbox secret key
$wgShellboxSecretKey = "<%= @shellbox_secretkey %>";

// Extension:DiscordNotifications global webhook
$wmgGlobalDiscordWebhookUrl = "<%= @global_discord_webhook_url %>";
$wmgDiscordExperimentalWebhook = "<%= @discord_experimental_webhook %>";
