package Data::Verifier;
use Moose;

our $VERSION = '0.03';

use Data::Verifier::Filters;
use Data::Verifier::Results;
use Moose::Util::TypeConstraints;

has 'filters' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] }
);

has 'profile' => (
    is => 'ro',
    isa => 'HashRef',
    required => 1
);

sub verify {
    my ($self, $params) = @_;

    my $results = Data::Verifier::Results->new;
    my $profile = $self->profile;

    foreach my $key (keys(%{ $profile })) {

        # Get the profile part that is pertinent to this field
        my $fprof = $profile->{$key};

        my $val = $params->{$key};

        # Pass through global filters
        if($self->filters) {
            $val = $self->_filter_value($self->filters, $val);
        }

        # And now per-field ones
        if($fprof->{filters}) {
            $val = $self->_filter_value($fprof->{filters}, $val);
        }

        # If the param is required, verify that it's there
        if($fprof->{required}) {
            $results->set_missing($key, 1) unless defined($params->{$key});
        }

        # Set the value
        $results->set_value($key, $val);

        # Validate it
        if($fprof->{type}) {
            my $cons = Moose::Util::TypeConstraints::find_type_constraint($fprof->{type});
            die "Unknown type constraint '$cons'" unless defined($cons);

            # if($fprof->{coerce}) {
            #     $val = $cons->coerce($val);
            # }

            $results->set_invalid($key, 1) unless $cons->check($val);
            $results->set_value($key, undef);
        }
    }

    return $results;
}

sub _filter_value {
    my ($self, $filters, $value) = @_;
    if(!ref($filters)) {
        $filters = [ $filters ];
    }

    foreach my $f (@{ $filters }) {
        if(Data::Verifier::Filters->can($f)) {
            $value = Data::Verifier::Filters->$f($value);
        }
    }

    return $value;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Verifier - Profile based data verification with Moose type constraints.

=head1 SYNOPSIS

Data::Verifier allows you verify data (such as web forms, which was the
original idea) by leveraging the power of Moose's type constraint system.

    use Data::Verifier;

    my $dv = Data::Verifier->new(
        filters => [ qw(trim) ]
        profile => {
            name => {
                required    => 1,
                type        => 'Str',
                filters     => [ qw(collapse) ]
            }
            age  => {
                type        => 'Int';
            },
            sign => {
                required    => 1,
                type        => 'Str'
            }
        }
    );

    my $results = $dv->verify({
        name => 'Cory', age => 'foobar'
    });

    $results->success; # no

    $results->is_invalid('name'); # no
    $results->is_invalid('age');  # yes

    $results->is_missing('name'); # no
    $results->is_missing('sign'); # yes

    $results->get_value('name'); # Filtered, valid value
    $results->get_value('age');  # undefined, as it's invalid

=head1 MOTIVATION

Data::Verifier firstly intends to leverage Moose's type constraint system,
which is significantly more powerful than anything I could create for the
purposes of this module.  Secondly it aims to keep a fairly simple interface
by leveraging the aforementioned type system to keep options to a minumum.

=head1 WARNING

This module is under very active development and, while the current API
will likely not be changed, features will be added rapidly.

=head1 ATTRIBUTES

=head2 filters

An optional arrayref of filter names through which B<all> values will be
passed.

=head2 profile

The profile is a hashref.  Each value you'd like to verify is a key.  The
values specify all the options to use with the field.  The available options
are:

=over 4

=item filters

An optional list of filters through which this specific value will be run. 
See the documentation for L<Data::Verifier::Filters> to learn more.  This value
may be either a string or an arrayref of strings.  

=item required

Determines if this field is required for verification.

=item type

The name of the Moose type constraint to use with verifying this field's
value.

=back

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

