use strict;
use Test::More;

use Data::Verifier;
use Moose::Util::TypeConstraints;

{
    my %table = ( 'one' => 1, 'two' => 2, 'three' => 3 );

    coerce 'Int'
        => from 'Str'
            => via { $table{ $_ } };


    my $verifier = Data::Verifier->new(
        profile => {
            num => {
                type   => 'Int',
                coerce => 1,
            },
        }
    );

    my $results = $verifier->verify({ num => 'two' });

    ok($results->success, 'success');
    cmp_ok($results->get_value('num'), '==', 2, 'get_value(num) is 2');
}

{

    my $verifier = Data::Verifier->new(
        profile => {
            str => {
                type     => 'Str',
                coercion => Data::Verifier::coercion(from => 'Int', via => sub { (qw[ one two three ])[ ($_ - 1) ] }),
            },
        }
    );

    my $results = $verifier->verify({ str => 2 });

    ok($results->success, 'success');
    cmp_ok($results->get_value('str'), 'eq', 'two', 'get_value(str) is two');
}

done_testing;
