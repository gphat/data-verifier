package Data::Verifier::Results;
use Moose;
use MooseX::AttributeHelpers;
use MooseX::Storage;

with Storage(format => 'JSON', io => 'File');

has '_statuses' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        exists  => 'is_statused',
        get     => 'get_status',
        set     => 'set_status'
    }
);

has '_values' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        count   => 'value_count',
        delete  => 'delete_value',
        # exists  => 'is_valid',
        get     => 'get_value',
        keys    => 'values',
        set     => 'set_value',
    }
);

__PACKAGE__->meta->add_method('valids' => __PACKAGE__->can('values'));
__PACKAGE__->meta->add_method('valid_count' => __PACKAGE__->can('value_count'));

sub _is_something {
    my ($self, $status, $field) = @_;

    if($self->is_statused($field)) {
        return $self->get_status($field) eq $status;
    }

    return 0;
}

sub _somethings {
    my ($self, $status) = @_;

    return grep({ $self->get_status($_) eq $status } keys %{ $self->_statuses });
}


sub is_invalid {
    my ($self, $field) = @_;

    return $self->_is_something('invalid', $field);
}

sub is_missing {
    my ($self, $field) = @_;

    return $self->_is_something('missing', $field);
}

sub is_valid {
    my ($self, $field) = @_;

    return $self->_is_something('valid', $field);
}

sub merge {
    my ($self, $other) = @_;

    foreach my $i ($other->invalids) {
        $self->set_status($i, 'invalid');
    }

    foreach my $m ($other->missings) {
        $self->set_status($m, 'missing');
    }

    foreach my $k ($other->valids) {
        $self->set_value($k, $other->get_value($k));
    }
}

sub invalid_count {
    my ($self) = @_;

    return scalar($self->invalids);
}

sub invalids {
    my ($self) = @_;

    return $self->_somethings('invalid');
}

sub missing_count {
    my ($self) = @_;

    return scalar($self->missings);
}

sub missings {
    my ($self) = @_;

    return $self->_somethings('missing');
}

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

The values present in the result are the filtered, valid values.  These may
differ from the ones supplied to the verify method due to either filters
or coercions.

=head2 valid_count

Returns the number of valid fields in this Results.

=head2 values

Returns a hashref of all the fields this profiled verified as the keys and
the values that remain after verification.

=head2 delete_value ($name)

Deletes the specified value from the results.

=head2 get_value ($name)

Returns the value for the specified field.  The value may be different from
the one originally supplied due to filtering or coercion.

=head2 value_count

Returns the number of values in this Results.

=head1 VALID FIELDS

=head2 is_valid ($name)

Returns true if the field is valid.

=head2 valids

Returns a list of keys for which we have valid values.

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