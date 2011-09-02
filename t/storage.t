use strict;
use Test::More;

use Data::Verifier;
use Moose::Util::TypeConstraints;

{
    my $verifier = Data::Verifier->new(
        profile => {
            num => {
                type   => 'Int',
            },
            name => {
                type => 'ArrayRef[Str]'
            },
            place => {
                type => 'Str'
            }
        }
    );

    my $results = $verifier->verify({ num => 2, name => [ qw(foo bar) ], place => 'Hoboken' });

    ok($results->success, 'success');
    cmp_ok($results->get_original_value('num'), 'eq', '2', 'get_original_value');
    cmp_ok($results->get_value('num'), '==', 2, 'get_value(num) is 2');
    cmp_ok(scalar(@{ $results->get_value('name') }), '==' , 2, 'name is an arrayref');
    cmp_ok($results->get_value('place'), 'eq', 'Hoboken');

    my $ser = $results->freeze({ format => 'JSON' });

    my $deresults = Data::Verifier::Results->thaw($ser, { format => 'JSON' });

    ok(!defined($deresults->get_value('num')), 'undefined value for num');
    ok($deresults->get_original_value('num'), 'got original value');
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
    cmp_ok($results->get_original_value('str'), '==', 2, 'get_original_value');
    cmp_ok($results->get_value('str'), 'eq', 'two', 'get_value(str) is two');

    my $ser = $results->freeze({ format => 'JSON' });

    my $deresults = Data::Verifier::Results->thaw($ser, { format => 'JSON' });

    ok(!defined($deresults->get_value('str')), 'undefined value for num');
    cmp_ok($deresults->get_original_value('str'), '==', 2, 'got original value');
}

{
    my $verifier = Data::Verifier->new(
        profile => {
            num => {
                type   => 'Int',
            },
            silly_nesting => {
                type => 'ArrayRef[HashRef[ArrayRef[Str]]]'
            },
        }
    );

    my $data = {
        num => 2,
        silly_nesting => [
            { foo1 => [ 'bar1', 'baz1' ] },
            { foo2 => [ 'bar2', 'baz2' ] },
        ],
    };

    my $results = $verifier->verify($data);

    ok($results->success, 'success');
    cmp_ok($results->get_original_value('num'), 'eq', '2', 'get_original_value');
    cmp_ok($results->get_value('num'), '==', 2, 'get_value(num) is 2');
    is_deeply( $results->get_value('silly_nesting'), $data->{silly_nesting}, 'same nested structure' );

    my $ser = $results->freeze({ format => 'JSON' });

    my $deresults = Data::Verifier::Results->thaw($ser, { format => 'JSON' });

    ok(!defined($deresults->get_value('num')), 'undefined value for num');
    ok($deresults->get_original_value('num'), 'got original value');

    is_deeply( $results->get_original_value('silly_nesting'), $data->{silly_nesting}, 'same nested structure from frozen structure' );
}

done_testing;
