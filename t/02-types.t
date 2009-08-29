use strict;
use Test::More;

use Data::Verifier;

{
    my $verifier = Data::Verifier->new(
        name => 'some_form',
        profile => {
            age    => {
                type => 'Int'
            }
        }
    );

    my $results = $verifier->verify({ age => 'foo' });

    ok(!$results->success, 'failed');
    cmp_ok($results->invalid_count, '==', 1, '1 invalid');
    ok(defined($results->is_invalid('age')), 'age is invalid');
}

done_testing;