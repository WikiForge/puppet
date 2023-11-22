# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages {
    include mediawiki::firejail

    stdlib::ensure_packages([
        'djvulibre-bin',
        'dvipng',
        'ghostscript',
        'graphicsmagick',
        'htmldoc',
        'inkscape',
        'fonts-freefont-ttf',
        'ffmpeg',
        'locales-all',
        'oggvideotools',
        'libxi-dev',
        'libglu1-mesa-dev',
        'libglew-dev',
        'libvips-tools',
        'nodejs',
        'ploticus',
        'poppler-utils',
        'netpbm',
        'librsvg2-dev',
        'libjpeg-dev',
        'libgif-dev',
        'p7zip-full',
        'xvfb',
        'timidity',
        'librsvg2-bin',
        'python3-minimal',
        'python3-requests',
        'rsync',
        'webp',
    ])

    if !lookup(mediawiki::use_shellbox) {
        stdlib::ensure_packages(
            'lilypond',
            {
                ensure => absent,
            },
        )
    }
}
