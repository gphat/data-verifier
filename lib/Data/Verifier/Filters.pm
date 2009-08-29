package Data::Verifier::Filters;
use strict;

sub collapse {
    my ($self, $val) = @_;

    $val =~ s/\s+/ /g;
    return $val;
}

sub lower {
    my ($self, $val) = @_;

    return lc($val);
}


sub upper {
    my ($self, $val) = @_;

    return uc($val);
}

sub trim {
    my ($self, $val) = @_;

    $val =~ s/\s+$//;
    $val =~ s/^\s+//;

    return $val;
}

1;

=head1 NAME

Data::Verifier::Filters - Filters for values

=head1 SYNOPSIS

    $dv->verify({
        name => {
            type    => 'Str'
            filters => [ qw(collapse trim) ]
        }
    });
    $dv->get_value('name');

=head1 FILTERS

=head2 collapse

Collapses all consecutive whitespace into a single space

=head2 lower

Converts the value to lowercase.

=head2 trim

Removes leading and trailing whitespace

=head2 upper

Converts the value to uppercase.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.