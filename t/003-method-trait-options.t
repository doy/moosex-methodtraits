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
            command => {
                traits => ['Foo::Command'],
            }
        }
    );
}

{
    package Foo::Command;
    use Moose::Role;

    has bar => (
        is => 'ro',
    );
}

{
    package Foo;
    use Moose;
    BEGIN { Foo::Exporter->import }

    command foo => sub { 'FOO' }, bar => 'BAR';
}

my $foo = Foo->new;
can_ok($foo, 'foo');
my $method = Foo->meta->get_method('foo');
does_ok($method, 'Foo::Command');
is($foo->foo, 'FOO', 'correct method is installed');
is($method->bar, 'BAR', 'method trait attribute is initialized');
