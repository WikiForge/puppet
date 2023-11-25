<?php

// Database passwords
$wgDBadminpassword = '<%= @wikiadmin_password %>';
$wgDBpassword = '<%= @mediawiki_password %>';

// Extension:AWS AWS S3 credentials
$wmgAWSAccessKey = '<%= @aws_s3_access_key %>';
$wmgAWSAccessSecretKey = '<%= @aws_s3_access_secret_key %>';

// hCaptcha secret key
$wgHCaptchaSecretKey = '<%= @hcaptcha_secretkey %>';

// LDAP 'write-user' password
$wmgLdapPassword = "<%= @ldap_password %>";

// MediaWiki secret keys
$wgUpgradeKey = '<%= @mediawiki_upgradekey %>';
$wgSecretKey = '<%= @mediawiki_secretkey %>';

// Noreply authentication
$wmgSMTPPassword = '<%= @noreply_password %>';

// Redis AUTH password
$wmgRedisPassword = '<%= @redis_password %>';

// Shellbox secret key
$wgShellboxSecretKey = '<%= @shellbox_secretkey %>';
