package Data::Verifier;
use Moose;

our $VERSION = '0.01';

use Data::Verifier::Filters;
use Data::Verifier::Results;
use Moose::Util::TypeConstraints;

has 'filters' => (
    is => 'ro',
    isa => 'ArrayRef[Str]'
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
    $results->is_invalid('age'); # yes

    $results->is_missing('name'); # no
    $results->is_missing('sign'); # yes

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

