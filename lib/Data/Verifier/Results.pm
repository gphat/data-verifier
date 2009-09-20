package Data::Verifier::Results;
use Moose;
use MooseX::AttributeHelpers;
use MooseX::Storage;

with Storage(format => 'JSON', io => 'File');

has 'fields' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        get     => 'get_field',
        set     => 'set_field'
    }
);

sub get_value {
    my ($self, $key) = @_;

    my $f = $self->get_field($key);
    return undef unless defined($f);
    return $f->value;
}

sub is_invalid {
    my ($self, $field) = @_;

    my $f = $self->get_field($field);

    return 0 unless defined($f);
    return $f->valid ? 0 : 1;
}

sub is_missing {
    my ($self, $field) = @_;

    my $f = $self->get_field($field);

    return 1 unless defined($f);
    return 0;
}

sub is_valid {
    my ($self, $field) = @_;

    my $f = $self->get_field($field);

    return 0 unless defined($f);
    return $f->valid ? 1 : 0;
}

sub merge {
    my ($self, $other) = @_;

    foreach my $f (keys %{ $other->fields }) {
        $self->set_field($f, $other->get_field($f));
    }
}

sub invalid_count {
    my ($self) = @_;

    return scalar($self->invalids);
}

sub invalids {
    my ($self) = @_;

    return grep(
        { my $field = $self->get_field($_); defined($field) && !$field->valid; }
        keys %{ $self->fields }
    );
}

sub missing_count {
    my ($self) = @_;

    return scalar($self->missings);
}

sub missings {
    my ($self) = @_;

    return grep(
        { my $field = $self->get_field($_); !defined($field) }
        keys %{ $self->fields }
    );
}

sub success {
    my ($self) = @_;

    if($self->missing_count || $self->invalid_count) {
        return 0;
    }

    return 1;
}

sub valids {
    my ($self) = @_;

    return grep(
        { my $field = $self->get_field($_); defined($field) && $field->valid; }
        keys %{ $self->fields }
    );
}

sub valid_count {
    my ($self) = @_;

    return scalar($self->valids);
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

=head1 FIELDS

=head2 get_field ($name)

Gets the field object, if it exists, for the name provided.

=head2 set_field ($name)

Sets the field object (you shouldn't be doing this directly) for the name
provided.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.