<?php

// Database passwords
$wgDBadminpassword = '<%= @wikiadmin_password %>';
$wgDBpassword = '<%= @mediawiki_password %>';

// Redis AUTH password
$wmgRedisPassword = '<%= @redis_password %>';

// Noreply authentication
$wmgSMTPPassword = '<%= @noreply_password %>';
$wmgSMTPUsername = '<%= @noreply_username %>';

// MediaWiki secret keys
$wgUpgradeKey = '<%= @mediawiki_upgradekey %>';
$wgSecretKey = '<%= @mediawiki_secretkey %>';

// hCaptcha secret key
$wgHCaptchaSecretKey = '<%= @hcaptcha_secretkey %>';

// Shellbox secret key
$wgShellboxSecretKey = '<%= @shellbox_secretkey %>';

// Extension:DiscordNotifications global webhook
$wmgGlobalDiscordWebhookUrl = '<%= @global_discord_webhook_url %>';
$wmgDiscordExperimentalWebhook = '<%= @discord_experimental_webhook %>';

// Extension:AWS AWS S3 credentials
$wmgAWSAccessKey = '<%= @aws_s3_access_key %>';
$wmgAWSAccessSecretKey = '<%= @aws_s3_access_secret_key %>';
