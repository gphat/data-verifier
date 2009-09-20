package Data::Verifier::Field;
use Moose;
use MooseX::AttributeHelpers;
use MooseX::Storage;

with Storage(format => 'JSON', io => 'File');

has reason => (
    is => 'rw',
    isa => 'Str',
    predicate => 'has_reason'
);

has value => (
    is => 'rw',
    isa => 'Any',
);

has valid => (
    is => 'rw',
    isa => 'Bool',
    default => 1
);

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Data::Verifier::Field - Field from a Data::Verifier profile

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


    my $field = $results->get_field('name);
    say $field->value;

=head1 ATTRIBUTES

=head2 reason

If this field is invalid then this attribute should contain a "reason".  Out
of the box it will always contain a string.  One of:

=over 4

=item B<dependent>

A dependent check failed.

=item B<max_length>

The value was larger than the field's max length.

=item B<min_length>

The value was shorter than the field's min length.

=item B<post_check>

The post check failed.

=item B<type_constraint>

The value did not pass the type constraint.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.