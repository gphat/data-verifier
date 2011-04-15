package main;

use warnings;
use strict;

use Test::More;

my $verifier = Data::Verifier->new(
    profile => {
        'foos[]' => {
            type => 'Str',
            post_check => sub {
                # $_->get_value('...') wont work here, maybe $_?
                return $_ =~ /^Foo/;
            }
        }
    }
);

my $results = $verifier->verify({
    foos => [
        'Foo 1',
        'Foo 2',
        'Invalid on post check',
        'Foo 3',
        'Foo 4',
        5, # Invalid on type? Probably not, but whatever :)
    ]
});

ok( !$results->success, 'verification is not successful' );
is_deeply(
    $results->get_value('foos'),
    [
        'Foo 1',
        'Foo 2',
        'Foo 3',
        'Foo 4',
    ],
    'get_value on list returns only valids'
);

done_testing;
