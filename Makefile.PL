use ExtUtils::MakeMaker;

use YAML::Any qw(LoadFile);
my $file = "plugins/StoreFront/config.yaml";
my $version = LoadFile($file)->{version} ||
    die "No version found in $file";

WriteMakefile(
    NAME            => 'Store Front',
    VERSION         => $version,
    DISTNAME        => 'StoreFront',
);
