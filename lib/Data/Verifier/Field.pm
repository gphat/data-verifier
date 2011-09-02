package Data::Verifier::Field;
use Moose;
use MooseX::Storage;

with 'MooseX::Storage::Deferred';

# ABSTRACT: Field from a Data::Verifier profile

=attr original_value

The string value of the field before any filters or coercion.  This will
survive serialization whereas value will not.

=method has_original_value

Predicate that returns true if this field has an original value.

=cut

has original_value => (
    is => 'rw',
    isa => 'Maybe[Str|ArrayRef|HashRef]',
    predicate => 'has_original_value'
);

=attr post_filter_value

The string value of the field before after filters but before coercion. This
will survive serialization whereas value will not.

=method has_post_filter_value

Predicate that returns true if this field has a post filter value.

=cut

has post_filter_value => (
    is => 'rw',
    isa => 'Maybe[Str|ArrayRef|HashRef]',
    predicate => 'has_post_filter_value'
);

=attr reason

If this field is invalid then this attribute should contain a "reason".  Out
of the box it will always contain a string.  One of:

=over 4

=item B<dependent>

A dependent check failed.

=item B<has_coerced_value>

Predicate for the C<coerced_value> attribute.

=item B<max_length>

The value was larger than the field's max length.

=item B<min_length>

The value was shorter than the field's min length.

=item B<post_check>

The post check failed.

=item B<type_constraint>

The value did not pass the type constraint.

=back

=method has_reason

Predicate that returns true if this field has a reason.

=cut

has reason => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_reason'
);

=attr valid

Boolean value representing this fields validity.

=cut

has valid => (
    is => 'rw',
    isa => 'Bool',
    default => 1
);

=attr value

The value of this field.  This will not be present if serialized, as it could
be any value, some of which we may not know how to Serialize.  See
C<original_value>.

=method clear_value

Clears the value attribute.

=cut

has value => (
    traits => [ 'DoNotSerialize' ],
    is => 'rw',
    isa => 'Any',
    clearer => 'clear_value'
);

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

    use Data::Verifier;

    my $dv = Data::Verifier->new(profile => {
        name => {
            required    => 1,
            type        => 'Str',
            filters     => [ qw(collapse trim) ]
        },
        age  => {
            type        => 'Int'
        },
        sign => {
            required    => 1,
            type        => 'Str'
        }
    });

    my $results = $dv->verify({
        name => 'Cory', age => 'foobar'
    });


    my $field = $results->get_field('name');
    print $field->value;

=head1 DESCRIPTION

Data::Verifier::Field provides all post-verification information on a given
field.

=cut
