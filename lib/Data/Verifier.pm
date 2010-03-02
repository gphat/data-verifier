package Data::Verifier;
use Moose;

our $VERSION = '0.28';

use Data::Verifier::Field;
use Data::Verifier::Filters;
use Data::Verifier::Results;
use Moose::Util::TypeConstraints;
use Try::Tiny;

has 'filters' => (
    is => 'ro',
    isa => 'ArrayRef[Str|CodeRef]',
    default => sub { [] }
);

has 'profile' => (
    is => 'ro',
    isa => 'HashRef[HashRef]',
    required => 1
);

sub coercion {
    my %params = @_;
    Moose::Meta::TypeCoercion->new(
        type_coercion_map => [
            $params{'from'} => $params{'via'}
        ]
    );
}

sub verify {
    my ($self, $params) = @_;

    my $results = Data::Verifier::Results->new;
    my $profile = $self->profile;

    my @post_checks = ();
    foreach my $key (keys(%{ $profile })) {

        # Get the profile part that is pertinent to this field
        my $fprof = $profile->{$key};

        my $val = $params->{$key};

        # Pass through global filters
        if($self->filters && defined $val) {
            $val = $self->_filter_value($self->filters, $val);
        }

        # And now per-field ones
        if($fprof->{filters} && defined $val) {
            $val = $self->_filter_value($fprof->{filters}, $val);
        }

        # Empty strings are undefined
        if(defined($val) && $val eq '') {
            $val = undef;
        }

        my $field = Data::Verifier::Field->new(
            original_value => $val
        );

        if($fprof->{required} && !defined($val)) {
            # Set required fields to undef, as they are missing
            $results->set_field($key, undef);
        } else {
            $results->set_field($key, $field);
        }

        # No sense in continuing if the value isn't defined.
        next unless defined($val);

        # Check min length
        if($fprof->{min_length} && length($val) < $fprof->{min_length}) {
            $field->reason('min_length');
            $field->valid(0);
            next; # stop processing!
        }

        # Check max length
        if($fprof->{max_length} && length($val) > $fprof->{max_length}) {
            $field->reason('max_length');
            $field->valid(0);
            next; # stop processing!
        }

        # Validate it
        if(defined($val) && $fprof->{type}) {
            my $cons = Moose::Util::TypeConstraints::find_type_constraint($fprof->{type});
            die "Unknown type constraint '$fprof->{type}'" unless defined($cons);

            if($fprof->{coerce}) {
                $val = $cons->coerce($val);
            }
            elsif(my $coercion = $fprof->{coercion}) {
                $val = $coercion->coerce($val);
            }

            unless($cons->check($val)) {
                $field->reason('type_constraint');
                $field->valid(0);
                $field->clear_value;
                next; # stop processing!
            }
        }

        # check for dependents
        my $dependent = $fprof->{dependent};
        my $dep_results;
        if($dependent) {
            # Create a new verifier for use withe the dependents
            my $dep_verifier = Data::Verifier->new(
                filters => $self->filters,
                profile => $dependent
            );
            $dep_results = $dep_verifier->verify($params);

            # Merge the dependent's results with the parent one
            $results->merge($dep_results);

            # If the dependent isn't valid, then this field isn't either
            unless($dep_results->success) {
                $field->reason('dependent');
                $field->valid(0);
                $field->clear_value;
                next; # stop processing!
            }
        }

        # Add this key the post check so we know to run through them
        if(defined($fprof->{post_check}) && $fprof->{post_check}) {
            push(@post_checks, $key);
        }

        # Set the value
        $field->value($val);
        $field->valid(1);
    }

    # If we have any post checks, do them.
    if(scalar(@post_checks)) {
        foreach my $key (@post_checks) {
            my $fprof = $profile->{$key};
            my $field = $results->get_field($key);

            # Execute the post_check...
            my $pc = $fprof->{post_check};
            if(defined($pc) && $pc) {
                try {
                    unless($results->$pc()) {
                        # If that returned false, then this field is invalid!
                        $field->clear_value;
                        $field->reason('post_check') unless $field->has_reason;
                        $field->valid(0);
                    }
                } catch {
                    $field->reason($_);
                    $field->clear_value;
                    $field->valid(0);
                }
            }
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

        if(ref($f)) {
            $value = $value->$f($value);
        } else {
            die "Unknown filter: $f" unless Data::Verifier::Filters->can($f);
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

    $results->get_original_value('name'); # Unchanged, original value
    $results->get_value('name'); # Filtered, valid value
    $results->get_value('age');  # undefined, as it's invalid

=head1 MOTIVATION

Data::Verifier firstly intends to leverage Moose's type constraint system,
which is significantly more powerful than anything I could create for the
purposes of this module.  Secondly it aims to keep a fairly simple interface
by leveraging the aforementioned type system to keep options to a minumum.

=head1 METHODS

=head2 coercion

Define a coercion to use for verification.  This will not define a global
Moose type coercion, but is instead just a single coercion to apply to a 
specific entity.

    my $verifier = Data::Verifier->new(
        profile => {
            a_string => {
                type     => 'Str',
                coercion => Data::Verifier::coercion(
                    from => 'Int', 
                        via => sub { (qw[ one two three ])[ ($_ - 1) ] }
                ),
            },
        }
    );

Now, after C<a_string> is processed by Data::Verifier, the results will 
return the coerced and validated value.

=head1 ATTRIBUTES

=head2 filters

An optional arrayref of filter names through which B<all> values will be
passed.

=head2 profile

The profile is a hashref.  Each value you'd like to verify is a key.  The
values specify all the options to use with the field.  The available options
are:

=over 4

=item B<coerce>

If true then the value will be given an opportunity to coerce via Moose's
type system.  If this is set, coercion will be ignored.

=item B<coercion>

Set this attribute to the coercion defined for this type.  If B<coerce> is 
set this attribute will be ignored.  See the C<coercion> method above.

=item B<dependent>

Allows a set of fields to be specifid as dependents of this one.  The argument
for this key is a full-fledged profile as you would give to the profile key:

  my $verifier = Data::Verifier->new(
      profile => {
          password    => {
              dependent => {
                  password2 => {
                      required => 1,
                  }
              }
          }
      }
  );

In the above example C<password> is not required.  If it is provided then
password2 must also be provided.  If any depedents of a field are missing or
invalid then that field is B<invalid>.  In our example if password is provided
and password2 is missing then password will be invalid.

=item B<filters>

An optional list of filters through which this specific value will be run. 
See the documentation for L<Data::Verifier::Filters> to learn more.  This
value my be either a scalar (string or coderef) or an arrayref of strings or
coderefs.

=item B<max_length>

An optional length which the value may not exceed.

=item B<min_length>

An optional length which the value may not be less.

=item B<post_check>

The C<post_check> key takes a subref and, after all verification has finished,
executes the subref with the results of the verification as it's only argument.
The subref's return value determines if the field to which the post_check
belongs is invalid.  A typical example would be when the value of one field
must be equal to the other, like an email confirmation:

  my $verifier = Data::Verifier->new(
      profile => {
          email    => {
              required => 1,
              dependent => {
                  email2 => {
                      required => 1,
                  }
              },
              post_check => sub {
                  my $r = shift;
                  return $r->get_value('email') eq $r->get_value('email2');
              }
          },
      }
  );

  my $results = $verifier->verify({
      email => 'foo@example.com', email2 => 'foo2@example.com'
  });

  $results->success; # false
  $results->is_valid('email'); # false
  $results->is_valid('email2); # true, as it has no post_check

In the above example, C<success> will return false, because the value of
C<email> does not match the value of C<email2>.  C<is_valid> will return false
for C<email> but true for C<email2>, since nothing specifically invalidated it.
In this example you should rely on the C<email> field, as C<email2> carries no
significance but to confirm C<email>.

B<Note about post_check and exceptions>: If have a more complex post_check
that could fail in multiple ways, you can C<die> in your post_check coderef
and the exception will be stored in the fields C<reason> attribute.

=item B<required>

Determines if this field is required for verification.

=item B<type>

The name of the Moose type constraint to use with verifying this field's
value. Note, this will also accept an instance of
L<Moose::Meta::TypeConstraint>, although it may not serialize properly as a
result.

=back

=head1 EXECUTION ORDER

It may be important to understand the order in which the various steps of
verification are performed:

=over 4

=item Global Filters

Any global filters in the profile are executed.

=item Per-Field Filters

Any per-field filters are executed.

=item Empty String Check

If the value of the field is an empty string then it is changed to an undef.

=item Required Check

The parameter must now be defined if it is set as required.

=item Length Check

Minimum then maximum length is checked.

=item Type Check (w/Coercion)

At this point the type will be checked after an optional coercion.

=item Depedency Checks

If this field has dependents then those will not be processed.

=item Post Check

If the field has a post check it will now be executed.

=back

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 CONTRIBUTORS

J. Shirley

Stevan Little

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

