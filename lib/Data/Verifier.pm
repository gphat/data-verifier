package Data::Verifier;
use Moose;

our $VERSION = '0.01';

use Data::Verifier::Results;
use Moose::Util::TypeConstraints;

has 'profile' => (
    is => 'ro',
    isa => 'HashRef',
    required => 1
);

has '_proxy' => (
    is => 'rw'
);

sub verify {
    my ($self, $params) = @_;

    my $results = Data::Verifier::Results->new;
    my $profile = $self->profile;

    foreach my $key (keys(%{ $profile })) {

        # Get the profile part that is pertinent to this field
        my $fprof = $profile->{$key};

        my $val = $params->{$key};
        # XX Need to filter here

        # If the param is required, verify that it's there
        if($fprof->{required}) {
            $results->set_missing($key, 1) unless defined($params->{$key});
        }

        # Set the value
        $results->set_value($key, $val);

        # Validate it
        if($fprof->{type}) {
            unless($self->_validate_value($fprof->{type}, $params->{$key})) {
                $results->set_invalid($key, 1);
            }
        }
    }

    return $results;
}

sub _validate_value {
    my ($self, $type, $value) = @_;

    my $cons = Moose::Util::TypeConstraints::find_type_constraint($type);
    die "Unknown type constraint '$cons'" unless defined($cons);

    return $cons->check($value);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Verifier - The great new Data::Verifier!

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Data::Verifier;

    my $foo = Data::Verifier->new(profile => {
        param1  => {
            required    => 1,
            type        => 'Some::Moose::Type';
        }
    });
    ...

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

