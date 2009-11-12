use inc::Module::Install;

name     'Data-Verifier';
all_from 'lib/Data/Verifier.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More' => '0.88';

requires 'JSON::Any' => '1.22';
requires 'Moose' => '0.89';
requires 'MooseX::AttributeHelpers' => '0.21';
requires 'MooseX::Storage' => '0.21';
requires 'Test::Exception' => '0.27';
requires 'Try::Tiny' => '0.02';

WriteAll;

