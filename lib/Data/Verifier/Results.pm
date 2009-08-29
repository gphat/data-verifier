package Data::Verifier::Results;
use Moose;
use MooseX::AttributeHelpers;

has '_invalids' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        set     => 'set_invalid',
        get     => 'is_invalid',
        keys    => 'invalids',
        count   => 'invalid_count'
    }
);

has '_missings' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        set     => 'set_missing',
        get     => 'is_missing',
        keys    => 'missings',
        count   => 'missing_count'
    }
);

has '_values' => (
    metaclass => 'Collection::Hash',
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    provides => {
        get     => 'get_value',
        set     => 'set_value',
        keys    => 'values'
    }
);

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