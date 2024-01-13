# This is the VCL file for Varnish, adjusted for WikiForge's needs.
# It was originally written by Southparkfan in 2015, but rewritten in 2022 by John.
# Some material used is inspired by the Wikimedia Foundation's configuration files.
# Their material and license is available at https://github.com/wikimedia/puppet

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.1 format.
vcl 4.1;

# Import some modules used
import directors;
import std;
import vsthrottle;

# MediaWiki configuration
probe mwhealth {
	.request = "GET /check HTTP/1.1"
		"Host: health.wikiforge.net"
		"User-Agent: Varnish healthcheck"
		"Connection: close";
	# Check each <%= @interval_check %>
	.interval = <%= @interval_check %>;
	# <%= @interval_timeout %> should be our upper limit for responding to a fair light web request
	.timeout = <%= @interval_timeout %>;
	# At least 2 out of 3 checks must be successful
	# to mark the backend as healthy
	.window = 3;
	.threshold = 2;
	.initial = 2;
	.expected_response = 204;
}

<%- @backends.each_pair do | name, property | -%>
backend <%= name %> {
	.host = "127.0.0.1";
	.port = "<%= property['port'] %>";
<%- if property['probe'] -%>
	.probe = <%= property['probe'] %>;
<%- end -%>
}

<%- if property['xdebug'] -%>
backend <%= name %>_test {
	.host = "127.0.0.1";
	.port = "<%= property['port'] %>";
}
<%- end -%>
<%- end -%>

# Initialize vcl
sub vcl_init {
	new mediawiki = directors.random();
<%- @backends.each_pair do | name, property | -%>
<%- if property['pool'] -%>
	mediawiki.add_backend(<%= name %>, 100);
<%- end -%>
<%- end -%>
}

# Debug ACL: those exempt from requiring an access key
acl debug {
	# cloud1
	"208.110.84.234";

<%- @backends.each_pair.with_index do |(name, property), index| -%>
	# <%= name %>
	"<%= property['ip_address'] %>";
<%- if index != @backends.size - 1 -%>

<%- end -%>
<%- end -%>
}

# Purge ACL
acl purge {
	# localhost
	"127.0.0.1";

<%- @backends.each_pair.with_index do |(name, property), index| -%>
	# <%= name %>
	"<%= property['ip_address'] %>";
<%- if index != @backends.size - 1 -%>

<%- end -%>
<%- end -%>
}

# Cookie handling logic
sub evaluate_cookie {
	# Replace all session/token values with a non-unique global value for caching purposes.
	if (req.restarts == 0) {
		unset req.http.X-Orig-Cookie;
		if (req.http.Cookie) {
			set req.http.X-Orig-Cookie = req.http.Cookie;
			if (req.http.Cookie ~ "([sS]ession|Token)=") {
				set req.http.Cookie = "Token=1";
			} else {
				unset req.http.Cookie;
			}
		}
	}
}

# Mobile detection logic
sub mobile_detection {
	# If the User-Agent matches the regex (this is the official regex used in MobileFrontend for automatic device detection), 
	# and the cookie does NOT explicitly state the user does not want the mobile version, we
	# set X-Device to phone-tablet. This will make vcl_backend_fetch add ?useformat=mobile to the URL sent to the backend.
	if (req.http.User-Agent ~ "(?i)(mobi|240x240|240x320|320x320|alcatel|android|audiovox|bada|benq|blackberry|cdm-|compal-|docomo|ericsson|hiptop|htc[-_]|huawei|ipod|kddi-|kindle|meego|midp|mitsu|mmp\/|mot-|motor|ngm_|nintendo|opera.m|palm|panasonic|philips|phone|playstation|portalmmm|sagem-|samsung|sanyo|sec-|semc-browser|sendo|sharp|silk|softbank|symbian|teleca|up.browser|vodafone|webos)" && req.http.Cookie !~ "(stopMobileRedirect=true|mf_useformat=desktop)") {
		set req.http.X-Subdomain = "M";
	}

	if (req.http.Cookie ~ "mf_useformat=") {
		set req.http.X-Subdomain = "M";
	}
}

# Rate limiting logic
sub rate_limit {
	# Allow higher limits for static.wikiforge.net
	if (req.http.Host == "static.wikiforge.net") {
		if (vsthrottle.is_denied("static:" + req.http.X-Real-IP, 1000, 1s)) {
			return (synth(429, "Varnish Rate Limit Exceeded"));
		}
	} else {
		# Do not limit /w/load.php, /w/resources, /favicon.ico, etc
		# Exempts rate limit for IABot
		if (
			((req.url ~ "^/(wiki)?" && req.url !~ "^/w/" && req.url !~ "^/(1\.\d{2,})/" && req.http.Host != "wikiforge.net") || req.url ~ "^/(w/)?(api|index)\.php")
			&& (req.http.X-Real-IP != "185.15.56.22" && req.http.User-Agent !~ "^IABot/2")
		) {
			if (req.url ~ "^/(wiki/)?\S+\:MathShowImage\?hash=[0-9a-z]+&mode=mathml") {
				# The Math extension at Special:MathShowImage may cause lots of requests, which should not fail
				if (vsthrottle.is_denied("math:" + req.http.X-Real-IP, 120, 10s)) {
					return (synth(429, "Varnish Rate Limit Exceeded"));
				}
			} else {
				# Fallback
				if (vsthrottle.is_denied("mwrtl:" + req.http.X-Real-IP, 24, 2s)) {
					return (synth(429, "Varnish Rate Limit Exceeded"));
				}
			}
		}
	}
}

# Artificial error handling/redirects within Varnish
sub vcl_synth {
	if (req.method != "PURGE") {
		set resp.http.X-CDIS = "int";

		if (resp.status == 752) {
			set resp.http.Location = resp.reason;
			set resp.status = 302;
			return (deliver);
		}

		// Homepage redirect to WikiForge Hub
		if (resp.reason == "WikiForge Hub Redirect") {
			set resp.reason = "Moved Permanently";
			set resp.http.Location = "https://hub.wikiforge.net/";
			set resp.http.Connection = "keep-alive";
			set resp.http.Content-Length = "0";
		}

		if (resp.reason == "Main Page Redirect") {
			set resp.reason = "Moved Permanently";
			set resp.http.Location = "https://wikiforge.net/";
			set resp.http.Connection = "keep-alive";
			set resp.http.Content-Length = "0";
		}

		// Handle CORS preflight requests
		if (
			req.http.Host == "static.wikiforge.net" &&
			resp.reason == "CORS Preflight"
		) {
			set resp.reason = "OK";
			set resp.http.Connection = "keep-alive";
			set resp.http.Content-Length = "0";

			// allow Range requests, and avoid other CORS errors when debugging with X-WikiForge-Debug
			set resp.http.Access-Control-Allow-Origin = "*";
			set resp.http.Access-Control-Allow-Headers = "Range,X-WikiForge-Debug";
			set resp.http.Access-Control-Allow-Methods = "GET, HEAD, OPTIONS";
			set resp.http.Access-Control-Max-Age = "86400";
		} else {
			call add_upload_cors_headers;
		}
	}
}

# Purge Handling
sub recv_purge {
	if (req.method == "PURGE") {
		if (!client.ip ~ purge) {
			return (synth(405, "Denied."));
		} else {
			return (purge);
		}
	}
}

sub normalize_request_nonmisc {
    // Sort query parameters to improve cache efficiency.
    set req.url = std.querysort(req.url);
}

# Main MediaWiki Request Handling
sub mw_request {
	call rate_limit;
	call mobile_detection;

	call normalize_request_nonmisc;
	
	# Assigning a backend
	if (req.http.X-WikiForge-Debug-Access-Key == "<%= @debug_access_key %>" || std.ip(req.http.X-Real-IP, "0.0.0.0") ~ debug) {
<%- @backends.each_pair do | name, property | -%>
<%- if property['xdebug'] -%>
		if (req.http.X-WikiForge-Debug == "<%= name %>.inside.wf") {
			set req.backend_hint = <%= name %>_test;
			return (pass);
		}
<%- end -%>
<%- end -%>
	} else {
		unset req.http.X-WikiForge-Debug;
	}

	# Redirect requests to dedicated hosts
	if (
		# AVID
		req.http.Host == "www.avid.wiki" ||
		req.http.Host == "avid.wiki" ||
		req.http.Host == "avid.your.wf"
	) {
		set req.backend_hint = mwdedi1;
	} elseif (
		# Harry Potter
		req.http.Host == "harrypotter.wiki" ||
		req.http.Host == "www.harrypotter.wiki" ||
		req.http.Host == "theharrypotter.wiki" ||
		req.http.Host == "www.theharrypotter.wiki"
	) {
		set req.backend_hint = mwdedi2;
	} else {
		set req.backend_hint = mediawiki.backend();
	}

	# Rewrite hostname to static.wikiforge.net for caching
	if (req.url ~ "^/static/") {
		set req.http.Host = "static.wikiforge.net";
	}

	# Numerous static.wikiforge.net specific code
	if (req.http.Host == "static.wikiforge.net") {
		unset req.http.X-Range;

		if (req.http.Range) {
			set req.hash_ignore_busy = true;
		}

		# We can do this because static.wikiforge.net should not be capable of serving such requests anyway
		# This could also increase cache hit rates as Cookies will be stripped entirely
		unset req.http.Cookie;
		unset req.http.Authorization;

		# CORS Prelight
		if (req.method == "OPTIONS" && req.http.Origin) {
			return (synth(200, "CORS Preflight"));
		}

		# From Wikimedia: https://gerrit.wikimedia.org/r/c/operations/puppet/+/120617/7/templates/varnish/upload-frontend.inc.vcl.erb
		# required for Extension:MultiMediaViewer
		if (req.url ~ "(?i)(\?|&)download(=|&|$)") {
			set req.http.X-Content-Disposition = "attachment";
		}

		// Strip away all query parameters
		set req.url = regsub(req.url, "\?.*$", "");
		
		// Replace double slashes
		set req.url = regsuball(req.url, "/{2,}", "/");

		// Thumb fixups
		if (req.url ~ "(?i)/thumb/") {
			// Normalize end of thumbnail URL (redundant filename)
			// Lowercase last part of the URL, to avoid case variations on extension or thumbnail parameters
			// eg. /hubwiki/thumb/0/06/Foo.jpg/120px-FOO.JPG => /hubwiki/thumb/0/06/Foo.jpg/120px-foo.jpg
			set req.url = regsub(req.url, "^(.+/)[^/]+$", "\1") + std.tolower(regsub(req.url, "^.+/([^/]+)$", "\1"));

			// Copy canonical filename from beginning of URL to thumbnail parameters at the end
			// eg. /hubwiki/thumb/0/06/Foo.jpg/120px-bar.jpg => /hubwiki/thumb/0/06/Foo.jpg/120px-Foo.jpg.jpg
			// Skips timestamps for archived files
			// eg. /hubwiki/thumb/archive/0/06/20231023012934!Foo.jpg/120px-bar.jpg => /hubwiki/thumb/archive/0/06/20231023012934!Foo.jpg/120px-Foo.jpg.jpg
			set req.url = regsub(req.url, "/(archive/\w/\w\w/\d{14}(?:%21|!))?([^/]+)/((?:qlow-)?(?:lossy-)?(?:lossless-)?(?:page\d+-)?(?:lang[0-9a-z-]+-)?\d+px-[-]?(?:(?:seek=|seek%3d)\d+-)?)[^/]+\.(\w+)$", "/\1\2/\3\2.\4");

			// Last pass, clean up any redundant extension
			// .jpg.jpg => .jpg, .JPG.jpg => .JPG
			// eg. /hubwiki/thumb/0/06/Foo.jpg/120px-Foo.jpg.jpg => /hubwiki/thumb/0/06/Foo.jpg/120px-Foo.jpg
			if (req.url ~ "(?i)(.*)(\.\w+)\2$") {
				set req.url = regsub(req.url, "(?i)(.*)(\.\w+)\2$", "\1\2");
			}
		}

		// Fixup borked client Range: headers
		if (req.http.Range ~ "(?i)bytes:") {
			set req.http.Range = regsub(req.http.Range, "(?i)bytes:\s*", "bytes=");
		}
	}

	# If a user is logged out, do not give them a cached page of them logged in
	if (req.http.If-Modified-Since && req.http.Cookie ~ "LoggedOut") {
		unset req.http.If-Modified-Since;
	}

	# Don't cache a non-GET or HEAD request
	if (req.method != "GET" && req.method != "HEAD") {
		return (pass);
	}

	# Do not cache dumps and also pipe requests.
	if ( req.http.Host == "static.wikiforge.net" && req.url ~ "^/.*wiki/dumps" ) {
		return (pipe);
	}

	# Don't cache certain things on static
	if (
		req.http.Host == "static.wikiforge.net" &&
		(
			req.url !~ "^/.*wiki" || # If it isn't a wiki folder, don't cache it
			req.url ~ "^/(.+)wiki/sitemaps" # Do not cache sitemaps
		)
	) {
		return (pass);
	}

	# We can rewrite those to one domain name to increase cache hits
	if (req.url ~ "^/(1\.\d{2,})/(skins|resources|extensions)/" ) {
		set req.http.Host = "hub.wikiforge.net";
	}

	call evaluate_cookie;

	if (req.url ~ "^/w/rest.php/.*" ) {
		return (pass);
	}

	# A request via OAuth should not be cached or use a cached response elsewhere
	if (req.http.Authorization ~ "OAuth") {
		return (pass);
	}

	if (req.http.Authorization ~ "^OAuth ") {
		return (pass);
	}
}

# Initial sub route executed on a Varnish request, the heart of everything
sub vcl_recv {
	call recv_purge; # Check purge

	unset req.http.Proxy; # https://httpoxy.org/

	unset req.http.X-CDIS;

	if (req.restarts == 0) {
		unset req.http.X-Subdomain;
	}

	# Health checks, do not send request any further, if we're up, we can handle it
	if (req.http.Host == "health.wikiforge.net" && req.url == "/check") {
		return (synth(200));
	}

	if (req.http.host == "hub.wikiforge.net" && req.url == "/wiki/WikiForge" && req.http.User-Agent ~ "(G|g)ooglebot") {
		return (synth(301, "Main Page Redirect"));
	}

	if (req.http.host == "static.wikiforge.net" && req.url == "/") {
		return (synth(301, "WikiForge Hub Redirect"));
	}

	if (
		req.url ~ "^/\.well-known" ||
		req.http.Host == "ssl.inside.wf" ||
		req.http.Host == "acme.inside.wf"
	) {
		set req.backend_hint = puppet1;
		return (pass);
	}

	if (req.http.Host ~ "^(alphatest|betatest|stabletest|test1|test)\.(wikiforge\.net)") {
		set req.backend_hint = test1;
		return (pass);
	}

	# Only cache js files from Matomo
	if (req.http.Host == "analytics.inside.wf") {
		set req.backend_hint = matomo1;

		# Yes, we only care about this file
		if (req.url ~ "^/matomo.js") {
			return (hash);
		} else {
			return (pass);
		}
	}

	# Do not cache requests from this domain
	if (req.http.Host == "monitoring.inside.wf" || req.http.Host == "grafana.inside.wf") {
		# set req.backend_hint = mon1;

		if (req.http.upgrade ~ "(?i)websocket") {
			return (pipe);
		}

		return (pass);
	}

	# Do not cache requests from this domain
	if (
		req.http.Host == "support.wikiforge.net" ||
		req.http.Host == "phorge-static.wikiforge.net" ||
		req.http.Host == "blog.wikiforge.net"
	) {
		set req.backend_hint = phorge1;
		return (pass);
	}

	# Do not cache requests from this domain
	if (req.http.Host == "webmail.inside.wf") {
		set req.backend_hint = mail1;
		return (pass);
	}

	# MediaWiki specific
	call mw_request;

	return (hash);
}

# Defines the uniqueness of a request
sub vcl_hash {
	# FIXME: try if we can make this ^/wiki/ only?
	if ((req.http.Host != "wikiforge.net" && req.url ~ "^/(wiki/)?") || req.url ~ "^/w/load.php") {
		hash_data(req.http.X-Subdomain);
	}
}

sub vcl_pipe {
	// for websockets over pipe
	if (req.http.upgrade) {
		set bereq.http.upgrade = req.http.upgrade;
		set bereq.http.connection = req.http.connection;
	}
}

# Initiate a backend fetch
sub vcl_backend_fetch {
	# Restore original cookies
	if (bereq.http.X-Orig-Cookie) {
		set bereq.http.Cookie = bereq.http.X-Orig-Cookie;
		unset bereq.http.X-Orig-Cookie;
	}

	if (bereq.http.X-Range) {
		set bereq.http.Range = bereq.http.X-Range;
		unset bereq.http.X-Range;
	}
}

sub mf_admission_policies {
	// hit-for-pass objects >= 8388608 size. Do cache if Content-Length is missing.
	if (bereq.http.Host == "static.wikiforge.net" && std.integer(beresp.http.Content-Length, 0) >= 262144) {
		// HFP
		set beresp.http.X-CDIS = "pass";
		return(pass(beresp.ttl));
	}

	// hit-for-pass objects >= 67108864 size. Do cache if Content-Length is missing.
	if (bereq.http.Host != "static.wikiforge.net" && std.integer(beresp.http.Content-Length, 0) >= 67108864) {
		// HFP
		set beresp.http.X-CDIS = "pass";
		return(pass(beresp.ttl));
	}

	return (deliver);
}

# Backend response, defines cacheability
sub vcl_backend_response {
	// This prevents the application layer from setting this in a response.
	// We'll be setting this same variable internally in VCL in hit-for-pass
	// cases later.
	unset beresp.http.X-CDIS;

	if (bereq.http.Cookie ~ "([sS]ession|Token)=") {
		set bereq.http.Cookie = "Token=1";
	} else {
		unset bereq.http.Cookie;
	}

	if (beresp.http.Content-Range) {
		// Varnish itself doesn't ask for ranges, so this must have been
		// a passed range request
		set beresp.http.X-Content-Range = beresp.http.Content-Range;
	}

	# Assign restrictive Cache-Control if one is missing
	if (!beresp.http.Cache-Control) {
		set beresp.http.Cache-Control = "private, s-maxage=0, max-age=0, must-revalidate";
		set beresp.ttl = 0s;
		// translated to hit-for-pass below
	}

	/* Don't cache private, no-cache, no-store objects. */
	if (beresp.http.Cache-Control ~ "(?i:private|no-cache|no-store)") {
		set beresp.ttl = 0s;
		// translated to hit-for-pass below
	}

	/* Especially don't cache Set-Cookie responses. */
	if ((beresp.ttl > 0s || beresp.http.Cache-Control ~ "public") && beresp.http.Set-Cookie) {
		set beresp.ttl = 0s;
		// translated to hit-for-pass below
	}
	// Set a maximum cap on the TTL for 404s. Objects that don't exist now may
	// be created later on, and we want to put a limit on the amount of time
	// it takes for new resources to be visible.
	elsif (beresp.status == 404 && beresp.ttl > 10m) {
		set beresp.ttl = 10m;
	}

	# Cookie magic as we did before
	if (bereq.http.Cookie ~ "([Ss]ession|Token)=") {
		set bereq.http.Cookie = "Token=1";
	} else {
		unset bereq.http.Cookie;
	}

	# Do not cache a backend response if HTTP code is above 400, except a 404, then limit TTL
	if (beresp.status >= 400 && beresp.status != 404) {
		set beresp.uncacheable = true;
	} elseif (beresp.status == 404 && beresp.ttl > 10m) {
		set beresp.ttl = 10m;
	}

	// Set keep, which influences the amount of time objects are kept available
	// in cache for IMS requests (TTL+grace+keep). Scale keep to the app-provided
	// TTL.
	if (beresp.ttl > 0s) {
		if (beresp.http.ETag || beresp.http.Last-Modified) {
			if (beresp.ttl < 1d) {
				set beresp.keep = beresp.ttl;
			} else {
				set beresp.keep = 1d;
			}
		}

		// Hard TTL cap on all fetched objects (default 1d)
		if (beresp.ttl > 1d) {
			set beresp.ttl = 1d;
		}

		set beresp.grace = 20m;
	}

	# Distribute caching re-calls where possible
	if (beresp.ttl >= 60s) {
		set beresp.ttl = beresp.ttl * std.random( 0.95, 1.00 );
	}

	if (beresp.http.Set-Cookie) {
		set beresp.uncacheable = true; # We do this just to be safe - but we should probably log this to eliminate it?
	}

	# Cache 301 redirects for 12h (/, /wiki, /wiki/ redirects only)
	if (beresp.status == 301 && bereq.url ~ "^/?(wiki/?)?$" && !beresp.http.Cache-Control ~ "no-cache") {
		set beresp.ttl = 43200s;
	}

	# Cache non-modified robots.txt for 12 hours, otherwise 5 minutes
	if (bereq.url == "/robots.txt") {
		if (beresp.http.X-WikiForge-Robots == "Custom") {
			set beresp.ttl = 300s;
		} else {
			set beresp.ttl = 43200s;
		}
	}

	// Compress compressible things if the backend didn't already, but
	// avoid explicitly-defined CL < 860 bytes.  We've seen varnish do
	// gzipping on CL:0 302 responses, resulting in output that has CE:gzip
	// and CL:20 and sends a pointless gzip header.
	// Very small content may actually inflate from gzipping, and
	// sub-one-packet content isn't saving a lot of latency for the gzip
	// costs (to the server and the client, who must also decompress it).
	// The magic 860 number comes from Akamai, Google recommends anywhere
	// from 150-1000.  See also:
	// https://webmasters.stackexchange.com/questions/31750/what-is-recommended-minimum-object-size-for-gzip-performance-benefits
	if (beresp.http.content-type ~ "json|text|html|script|xml|icon|ms-fontobject|ms-opentype|x-font|sla"
		&& (!beresp.http.Content-Length || std.integer(beresp.http.Content-Length, 0) >= 860)) {
			set beresp.do_gzip = true;
	}

	// SVGs served by MediaWiki are part of the interface. That makes them
	// very hot objects, as a result the compression time overhead is a
	// non-issue. Several of them tend to be requested at the same time,
	// as the browser finds out about them when parsing stylesheets that
	// contain multiple. This means that the "less than 1 packet" rationale
	// for not compressing very small objects doesn't apply either. Lastly,
	// since they're XML, they contain a fair amount of repetitive content
	// even when small, which means that gzipped SVGs tend to be
	// consistantly smaller than their uncompressed version, even when tiny.
	// For all these reasons, it makes sense to have a lower threshold for
	// SVG. Applying it to XML in general is a more unknown tradeoff, as it
	// would affect small API responses that are more likely to be cold
	// objects due to low traffic to specific API URLs.
	if (beresp.http.content-type ~ "svg" && (!beresp.http.Content-Length || std.integer(beresp.http.Content-Length, 0) >= 150)) {
		set beresp.do_gzip = true;
	}

	// set a 601s hit-for-pass object based on response conditions in vcl_backend_response:
	//    Calculated TTL <= 0 + Status < 500:
	//    These are generally uncacheable responses.  The 5xx exception
	//    avoids us accidentally replacing a good stale/grace object with
	//    an hfp (and then repeatedly passing on potentially-cacheable
	//    content) due to an isolated 5xx response.
	if (beresp.ttl <= 0s && beresp.status < 500 && (!beresp.http.X-Cache-Int || beresp.http.X-Cache-Int !~ " hit")) {
		set beresp.grace = 31s;
		set beresp.keep = 0s;
		set beresp.http.X-CDIS = "pass";
		return(pass(601s));
	}

	if (beresp.ttl > 60s && (bereq.url ~ "mobileaction=" || bereq.url ~ "useformat=")) {
		set beresp.ttl = 60 s;
	}

	// set a 607s hit-for-pass object based on response conditions in vcl_backend_response:
	//    Token=1 + Vary:Cookie:
	//    All requests with real login session|token cookies share the
	//    Cookie:Token=1 value for Vary purposes.  This allows them to
	//    share a single hit-for-pass object here if the response
	//    shouldn't be shared between users (Vary:Cookie).
	if (
		bereq.http.Cookie == "Token=1"
		&& beresp.http.Vary ~ "(?i)(^|,)\s*Cookie\s*(,|$)"
	) {
		set beresp.grace = 31s;
		set beresp.keep = 0s;
		set beresp.http.X-CDIS = "pass";
		// HFP
		return(pass(607s));
	}

	// It is important that this happens after the code responsible for translating TTL<=0
	// (uncacheable) responses into hit-for-pass.
	call mf_admission_policies;

	// return (deliver);
}

# Last sub route activated, clean up of HTTP headers etc.
sub vcl_deliver {
	if (req.method != "PURGE") {
		if(req.http.X-CDIS == "hit") {
			// obj.hits isn't known in vcl_hit, and not useful for other states
			set req.http.X-CDIS = "hit/" + obj.hits;
		}

		// we copy through from beresp->resp->req here for the initial hit-for-pass case
		if (resp.http.X-CDIS) {
			set req.http.X-CDIS = resp.http.X-CDIS;
			unset resp.http.X-CDIS;
		}

		if (!req.http.X-CDIS) {
			set req.http.X-CDIS = "bug";
		}

		if (resp.http.X-Cache-Int) {
			set resp.http.X-Cache-Int = resp.http.X-Cache-Int + ", <%= @facts['networking']['hostname'] %> " + req.http.X-CDIS;
		} else {
			set resp.http.X-Cache-Int = "<%= @facts['networking']['hostname'] %> " + req.http.X-CDIS;
		}

		set resp.http.X-Cache = resp.http.X-Cache-Int;

		set resp.http.X-Cache-Status = regsuball(resp.http.X-Cache, "cp[0-9] (hit|miss|pass|int)(?:/[0-9]+)?", "\1");

		unset resp.http.X-Cache-Int;
		unset resp.http.Via;

		if (resp.http.X-Cache-Status ~ "hit$") {
			set resp.http.X-Cache-Status = "hit-front";
		} elsif (resp.http.X-Cache-Status ~ "hit,[^,]+$") {
			set resp.http.X-Cache-Status = "hit-local";
		} elsif (resp.http.X-Cache-Status ~ "hit") {
			set resp.http.X-Cache-Status = "hit-remote";
		} elsif (resp.http.X-Cache-Status ~ "int$") {
			set resp.http.X-Cache-Status = "int-front";
		} elsif (resp.http.X-Cache-Status ~ "int,[^,]+$") {
			set resp.http.X-Cache-Status = "int-local";
		} elsif (resp.http.X-Cache-Status ~ "int") {
			set resp.http.X-Cache-Status = "int-remote";
		} elsif (resp.http.X-Cache-Status ~ "miss$") {
			set resp.http.X-Cache-Status = "miss";
		} elsif (resp.http.X-Cache-Status ~ "pass$") {
			set resp.http.X-Cache-Status = "pass";
		} else {
			set resp.http.X-Cache-Status = "unknown";
		}
	}

	// Provides custom error html if error response has no body
	if (resp.http.Content-Length == "0" && resp.status >= 400) {
		return(synth(resp.status));
	}

	if (resp.http.X-Content-Range) {
		set resp.http.Content-Range = resp.http.X-Content-Range;
		unset resp.http.X-Content-Range;
	}

	if ( req.http.Host == "static.wikiforge.net" ) {
		unset resp.http.Set-Cookie;
		unset resp.http.Cache-Control;

		if (req.http.X-Content-Disposition == "attachment") {
			set resp.http.Content-Disposition = "attachment";
		}

		// Prevent browsers from content sniffing.
		set resp.http.X-Content-Type-Options = "nosniff";

		call add_upload_cors_headers;
	}

	if ( req.url ~ "^(?i)\/w\/img_auth\.php\/(.+)" ) {
		call add_upload_cors_headers;
	}

	# Client side caching for load.php
	if (req.url ~ "^/w/load\.php" ) {
		set resp.http.Age = 0;
	}

	# Do not index certain URLs
	if (req.url ~ "^(/(w/)?(api|index|rest)\.php*|/(wiki/)?Special(\:|%3A)(?!WikiForum)).+$") {
		set resp.http.X-Robots-Tag = "noindex";
	}

	# Disable Google ad targeting (FLoC)
	set resp.http.Permissions-Policy = "interest-cohort=(), browsing-topics=()";

	# Content Security Policy
	set resp.http.Content-Security-Policy = "<%- @csp.each_pair do |type, value| -%> <%= type %> <%= value.join(' ') %>; <%- end -%>";

	# For a 500 error, do not set cookies
	if (resp.status >= 500 && resp.http.Set-Cookie) {
		unset resp.http.Set-Cookie;
	}

	if (req.http.X-Content-Disposition == "attachment") {
		set resp.http.Content-Disposition = "attachment";
	}

	return (deliver);
}

sub add_upload_cors_headers {
	set resp.http.Access-Control-Allow-Origin = "*";

	// Headers exposed for CORS:
	// - Age, Content-Length, Date, X-Cache
	//
	// - X-Content-Duration: used for OGG audio and video files.
	//   Firefox 41 dropped support for this header, but OGV.js still supports it.
	//   See <https://bugzilla.mozilla.org/show_bug.cgi?id=1160695#c27> and
	//   <https://github.com/brion/ogv.js/issues/88>.
	//
	// - Content-Range: indicates total file and actual range returned for RANGE
	//   requests. Used by ogv.js to eliminate an extra HEAD request
	//   to get the total file size.
	set resp.http.Access-Control-Expose-Headers = "Age, Date, Content-Length, Content-Range, X-Content-Duration, X-Cache";
}

# Hit code, default logic is appended
sub vcl_hit {
	set req.http.X-CDIS = "hit";
}

# Miss code, default logic is appended
sub vcl_miss {
	set req.http.X-CDIS = "miss";

	// Convert range requests into pass
	if (req.http.Range) {
		// Varnish strips the Range header before copying req into bereq. Save it into
		// a header and restore it in vcl_backend_fetch
		set req.http.X-Range = req.http.Range;
		return (pass);
	}

	return (fetch);
}

# Pass code, default logic is appended
sub vcl_pass {
	set req.http.X-CDIS = "pass";

	return (fetch);
}

# Synthetic code, default logic is appended
sub vcl_synth {
	if (req.method != "PURGE") {
		set resp.http.X-CDIS = "int";

		// we copy through from beresp->resp->req here for the initial hit-for-pass case
		if (resp.http.X-CDIS) {
			set req.http.X-CDIS = resp.http.X-CDIS;
			unset resp.http.X-CDIS;
		}

		if (!req.http.X-CDIS) {
			set req.http.X-CDIS = "bug";
		}

		// X-Cache-Int gets appended-to as we traverse cache layers
		if (resp.http.X-Cache-Int) {
			set resp.http.X-Cache-Int = resp.http.X-Cache-Int + ", <%= @facts['networking']['hostname'] %> " + req.http.X-CDIS;
		} else {
			set resp.http.X-Cache-Int = "<%= @facts['networking']['hostname'] %> " + req.http.X-CDIS;
		}
	}

	return (deliver);
}

# Backend response when an error occurs
sub vcl_backend_error {
	set beresp.http.X-CDIS = "int";
	set beresp.http.Content-Type = "text/html; charset=utf-8";

	synthetic( {"<!DOCTYPE html>
	<html lang="en">
		<head>
			<meta charset="utf-8" />
			<meta name="viewport" content="width=device-width, initial-scale=1.0" />
			<meta name="description" content="Something went wrong, try again in a few seconds." />
			<title>Something went wrong</title>
			<!-- Bootstrap core CSS -->
			<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-4bw+/aepP/YC94hEpVNVgiZdgIC5+VKNBQNGCHeKRQN+PtmoHDEXuppvnDJzQIu9" crossorigin="anonymous">
			<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Outfit">
			<style>
				/* Error Page Inline Styles */
				body {
					padding-top: 20px;
				}
				/* Layout */
				.jumbotron {
					font-size: 21px;
					font-weight: 200;
					line-height: 2.1428571435;
					color: inherit;
					padding: 10px 0px;
					text-align: center;
					background-color: transparent;
				}
				/* Everything but the jumbotron gets side spacing for mobile-first views */
				.body-content {
					padding-left: 15px;
					padding-right: 15px;
				}
				/* button */
				.jumbotron .btn {
					font-size: 21px;
					padding: 14px 24px;
				}
				/* Dark mode */
				@media (prefers-color-scheme: dark) {
					body {
						background-color: #282828;
						color: white;
					}
					h1, h2, p {
						color: white;
					}
				}
				body {
					font-family: 'Outfit', sans-serif;
				}
			</style>
		</head>
		<div class="container" style="padding: 70px 0; text-align: center;">
			<!-- Jumbotron -->
			<div class="jumbotron">
				<img src="https://static.wikiforge.net/hubwiki/8/88/WikiForge_Logo.svg" width="130" height="130" alt="WikiForge Logo" />
				<h1>Something went wrong</h1>
				<p class="lead">Give it a bit and try again. <a href="https://static-help.wikiforge.net/docs/errors/503">Learn more</a>.</p>
				<a href="javascript:document.location.reload(true);" class="btn btn-outline-primary" role="button">Try this action again</a>
			</div>
		</div>
		<div class="footer" style="position: fixed; left:0px; bottom: 125px; height:30px; width:100%;">
			<div class="text-center">
				<p class="lead">When reporting this, please include the information below:</p>

				Error "} + beresp.status + " " + beresp.reason + {", forwarded for "} + bereq.http.X-Forwarded-For + {" <br />
				(Varnish XID "} + bereq.xid + {") via "} + server.identity + {" at "} + now + {".
				<br /><br />
			</div>
		</div>
	</html>
	"} );

	return (deliver);
}
