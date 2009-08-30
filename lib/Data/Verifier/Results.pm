package Data::Verifier::Results;
use Moose;
use MooseX::AttributeHelpers;

has '_invalids' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        set     => 'set_invalid',
        get     => 'is_invalid',
        keys    => 'invalids',
        count   => 'invalid_count'
    }
);

has '_missings' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        set     => 'set_missing',
        get     => 'is_missing',
        keys    => 'missings',
        count   => 'missing_count'
    }
);

has '_values' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        get     => 'get_value',
        set     => 'set_value',
    }
);

sub success {
    my ($self) = @_;

    if($self->missing_count || $self->invalid_count) {
        return 0;
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Verifier::Results - Results of a Data::Verifier

=head1 SYNOPSIS

    use Data::Verifier;

    my $dv = Data::Verifier->new(profile => {
        name => {
            required    => 1,
            type        => 'Str',
            filters     => [ qw(collapse trim) ]
        }
        age  => {
            type        => 'Int';
        },
        sign => {
            required    => 1,
            type        => 'Str'
        }
    });

    my $results = $dv->verify({
        name => 'Cory', age => 'foobar'
    });

    $results->success; # no

    $results->is_invalid('name'); # no
    $results->is_invalid('age'); # yes

    $results->is_missing('name'); # no
    $results->is_missing('sign'); # yes

=head1 SUCCESS OR FAILURE

=head2 success

Returns true or false based on if the verification's success.

=head1 VALUES

=head2 get_value ($name)

Returns the value for the specified field.  The value may be different from
the one originally supplied due to filtering or coercion.

=head1 INVALID FIELDS

=head2 is_invalid ($name)

Returns true if the specific field is invalid.

=head2 invalids

Returns a list of invalid field names.

=head2 invalid_count

Returns the count of invalid fields in this result.

=head1 MISSING FIELDS

=head2 is_missing ($name)

Returns true if the specified field is missing.

=head2 missings

Returns a list of missing field names.

=head2 missing_count

Returns the count of missing fields in this result.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.