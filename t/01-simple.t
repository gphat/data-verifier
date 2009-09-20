use strict;
use Test::More;

use Data::Verifier;

{
    my $verifier = Data::Verifier->new(
        profile => {
            name    => {
                required => 1
            }
        }
    );

    my $results = $verifier->verify({ name => 'foo' });

    ok($results->success, 'success');
    cmp_ok($results->valid_count, '==', 1, '1 valid');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');
    ok($results->is_valid('name'), 'name is valid');
    cmp_ok($results->get_value('name'), 'eq', 'foo', 'get_value');
}

{
    my $verifier = Data::Verifier->new(
        profile => {
            name    => {
                required => 1,
            }
        }
    );

    my $results = $verifier->verify({ bar => 'foo' });

    ok(!$results->success, 'failure');
    cmp_ok($results->valid_count, '==', 0, '0 valid');
    cmp_ok($results->invalid_count, '==', 0, '0 invalid');
    cmp_ok($results->missing_count, '==', 1, '1 missing');
    ok(!$results->is_valid('name'), 'name is not valid');
    ok(!$results->is_invalid('name'), 'name is invalid');
    ok($results->is_missing('name'), 'name is missing');
    ok(!defined($results->get_value('name')), 'name has no value');
}

{
    my $verifier = Data::Verifier->new(
        profile => {
            name    => {
                required => 1
            },
            age     => {
                required => 1,
                type => 'Int'
            }
        }
    );

    my $results = $verifier->verify({ name => 'foo', age => 0 });

    ok($results->success, 'success');
    cmp_ok($results->valid_count, '==', 2, '2 valid');
    cmp_ok($results->invalid_count, '==', 0, 'none invalid');
    cmp_ok($results->missing_count, '==', 0, 'none missing');
    ok($results->is_valid('name'), 'name is valid');
    cmp_ok($results->get_value('name'), 'eq', 'foo', 'get_value');
    ok($results->is_valid('age'), 'age is valid');
}


done_testing;