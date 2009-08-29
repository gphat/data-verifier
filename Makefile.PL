use inc::Module::Install;

name     'Data-Verifier';
all_from 'lib/Data/Verifier.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More' => '0.88';

requires 'Moose' => '0.89';
requires 'MooseX::AttributeHelpers' => '0.21';

WriteAll;

