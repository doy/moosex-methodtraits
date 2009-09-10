package MooseX::MethodTraits;
use Moose::Exporter;

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
        my $munge = $spec->{munge} || sub { shift, \@_ };

        my $code = sub {
            my $meta = shift;
            my $name = shift;
            # XXX: need to do something with $args - these should be for
            # initializing attributes in the method traits that are applied
            my ($method, $args) = $munge->(@_);

            my $method_metaclass = Moose::Meta::Class->create_anon_class(
                superclasses => [$meta->method_metaclass],
                roles        => $traits,
                cache        => 1,
            );

            $meta->add_method(
                $name => $method_metaclass->name->wrap(
                    $method,
                    name         => $name,
                    package_name => $meta->name,
                )
            );
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
