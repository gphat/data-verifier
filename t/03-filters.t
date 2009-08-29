use strict;
use Test::More;

use Data::Verifier;

my $verifier = Data::Verifier->new(
    profile => {
        name => {
            filters => [ qw(collapse) ]
        },
        address1 => {
            filters => [ qw(trim) ]
        },
        address2 => {
            filters => [ qw(collapse trim) ]
        },
        foo => {
            filters => 'upper'
        },
        bar => {
            filters => 'lower'
        }
    }
);

{
    my $results = $verifier->verify({
        name        => "foo\tbar",
        address1    => "  123 test  \n",
        address2    => "  123\n    test\t\n",
        foo         => 'Abc',
        bar         => 'Abc'
    });

    ok($results->success, 'success');
    cmp_ok($results->get_value('name'), 'eq', 'foo bar', 'collapse');
    cmp_ok($results->get_value('address1'), 'eq', '123 test', 'trim');
    cmp_ok($results->get_value('address2'), 'eq', '123 test', 'trim + collapse');
    cmp_ok($results->get_value('foo'), 'eq', 'ABC', 'upper');
    cmp_ok($results->get_value('bar'), 'eq', 'abc', 'lower');
}

done_testing;