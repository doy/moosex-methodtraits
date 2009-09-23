#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Test::Moose;

BEGIN {
    package Foo::Exporter;
    use MooseX::MethodTraits;

    MooseX::MethodTraits->setup_import_methods(
        with_traits => {
            alias => {
                traits => ['Foo::Alias'],
                munge  => sub {
                    my $meta = shift;
                    my $alias_name = shift;
                    my $name = shift;
                    return sub { shift->$name(@_) },
                           { aliased_from => $name, @_ };
                },
            }
        }
    );
}

{
    package Foo::Alias;
    use Moose::Role;

    has aliased_from => (
        is  => 'ro',
        isa => 'Str',
    );
}

{
    package Foo;
    use Moose;
    BEGIN { Foo::Exporter->import }

    sub foo { 'FOO' }
    alias bar => 'foo';
}

my $foo = Foo->new;
can_ok($foo, 'bar');
my $method = Foo->meta->get_method('bar');
does_ok($method, 'Foo::Alias');
is($method->aliased_from, 'foo', 'method knows where it came from');
is($foo->bar, 'FOO', 'aliased properly');
