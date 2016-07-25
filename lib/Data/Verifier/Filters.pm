package Data::Verifier::Filters;

use strict;
use warnings;

# ABSTRACT: Filters for values

=method collapse

Collapses all consecutive whitespace into a single space

=cut

sub collapse {
    my ($self, $val) = @_;
    return $val if not defined $val;

    $val =~ s/\s+/ /g;
    return $val;
}

=method flatten

Removes B<all whitespace>.

=cut

sub flatten {
    my ($self, $val) = @_;
    return $val if not defined $val;

    $val =~ s/\s//g;
    return $val;
}

=method lower

Converts the value to lowercase.

=cut

sub lower {
    my ($self, $val) = @_;
    return $val if not defined $val;

    return lc($val);
}

=method trim

Removes leading and trailing whitespace

=cut

sub trim {
    my ($self, $val) = @_;
    return $val if not defined $val;

    $val =~ s/^\s+|\s+$//g;

    return $val;
}

=method upper

Converts the value to uppercase.

=cut

sub upper {
    my ($self, $val) = @_;
    return $val if not defined $val;

    return uc($val);
}

1;

__END__

=head1 SYNOPSIS

    use Data::Verifier;

    my $dv = Data::Verifier->new(profile => {
        name => {
            type    => 'Str',
            filters => [ qw(collapse trim) ]
        }
    });

    $dv->verify({ name => ' foo  bar  '});
    $dv->get_value('name'); # 'foo bar'

=head1 CUSTOM FILTERS

Adding a custom filter may be done by providing a coderef as one of the
filters:

  # Remove all whitespace
  my $sub = sub { my ($val) = @_; $val =~ s/\s//g; $val }

  $dv->verify({
    name => {
      type    => 'Str'
        filters => [ $sub ]
      }
  });
  $dv->get_value('name'); # No whitespace!
