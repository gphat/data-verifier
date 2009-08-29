use strict;
use Test::More;

use Data::Verifier;

{
    my $verifier = Data::Verifier->new(
        name => 'some_form',
        profile => {
            name    => {
                required => 1
            }
        }
    );

    my $results = $verifier->verify({ name => 'foo' });

    ok($results->success, 'success');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');
}

{
    my $verifier = Data::Verifier->new(
        name => 'some_form',
        profile => {
            name    => {
                required => 1,
            }
        }
    );

    my $results = $verifier->verify({ bar => 'foo' });

    ok(!$results->success, 'failure');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 1, '1 missing');
    ok($results->is_missing('name'), 'name is missing');
}


done_testing;