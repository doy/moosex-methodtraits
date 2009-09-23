package MooseX::MethodTraits;
use Moose::Exporter;
use Scalar::Util qw(blessed reftype);

=head1 NAME

MooseX::MethodTraits -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

sub _generate_method_creators {
    my ($package, $with_traits) = @_;

    my $package_meta = Class::MOP::Package->initialize($package);
    for my $sub (keys %$with_traits) {
        my $spec = $with_traits->{$sub};
        my $traits = $spec->{traits} || [];
        my $munge = $spec->{munge} || sub {
            my $meta = shift;
            my $name = shift;
            my $method = reftype($_[0]) && reftype($_[0]) eq 'CODE'
                ? shift : $meta->find_method_by_name($name);
            return $method, {@_};
        };

        my $code = sub {
            my ($method, $args) = $munge->(@_);
            my $meta = shift;
            my $name = shift;

            my $superclass = blessed($method) || $meta->method_metaclass;
            my $method_metaclass = Moose::Meta::Class->create_anon_class(
                superclasses => [$superclass],
                roles        => $traits,
                cache        => 1,
            );

            my $method_meta = $method_metaclass->name->wrap(
                $method,
                name         => $name,
                package_name => $meta->name,
            );

            $meta->add_method($name => $method_meta);

            return unless $args;

            for my $attr_name (map { $_->meta->get_attribute_list } @$traits) {
                next unless exists $args->{$attr_name};
                my $attr = $method_meta->meta->find_attribute_by_name($attr_name);
                $attr->set_value($method_meta, $args->{$attr_name});
            }
        };
        $package_meta->add_package_symbol('&' . $sub => $code);
    }
    return keys %$with_traits;
}

# XXX: factor some of this stuff out
sub build_import_methods {
    my $class   = shift;
    my %options = @_;
    $options{exporting_package} ||= caller;
    if (exists $options{with_traits}) {
        my $with_traits = delete $options{with_traits};
        my @extra_with_meta = _generate_method_creators(
            $options{exporting_package}, $with_traits
        );
        $options{with_meta} = [
            @{ $options{with_meta} || [] },
            @extra_with_meta,
        ];
    }
    return Moose::Exporter->build_import_methods(%options)
}

sub setup_import_methods {
    my $class   = shift;
    my %options = @_;
    $options{exporting_package} ||= caller;
    if (exists $options{with_traits}) {
        my $with_traits = delete $options{with_traits};
        my @extra_with_meta = _generate_method_creators(
            $options{exporting_package}, $with_traits
        );
        $options{with_meta} = [
            @{ $options{with_meta} || [] },
            @extra_with_meta,
        ];
    }
    return Moose::Exporter->setup_import_methods(%options)
}

sub import {
    strict->import;
    warnings->import;
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-moosex-methodtraits at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-MethodTraits>.

=head1 SEE ALSO


=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc MooseX::MethodTraits

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-MethodTraits>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-MethodTraits>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-MethodTraits>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-MethodTraits>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
