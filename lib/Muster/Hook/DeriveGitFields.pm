package Muster::Hook::DeriveGitFields;

=head1 NAME

Muster::Hook::DeriveGitFields - Muster hook for field derivation from git repo pages

=head1 DESCRIPTION

L<Muster::Hook::DeriveGitFields> derives field values
from information available from Git, for pages which
live in a git repository.

The directory for the git repo is given in the I<repo_dir>
in the config section for this hook.

=cut

use Mojo::Base 'Muster::Hook';
use Muster::Hooks;
use Muster::LeafFile;
use Git::Wrapper;
use YAML::Any;
use Carp;

=head1 METHODS

=head2 register

Initialize, and register hooks.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{config} = $conf->{hook_conf}->{'Muster::Hook::DeriveGitFields'};
    $self->{git} = Git::Wrapper->new($self->{config}->{repo_dir});

    $hookmaster->add_hook('derivegitfields' => sub {
            my %args = @_;

            return $self->process(%args);
        },
    );
    return $self;
} # register

=head2 process

Process (scan or modify) a leaf object.
This only does stuff in the scan phase.
This expects the leaf meta-data to be populated.

  my $new_leaf = $self->process(%args);

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};

    # only does derivations in scan phase
    if ($phase ne $Muster::Hooks::PHASE_SCAN)
    {
        return $leaf;
    }

    my $meta = $leaf->meta;

    # -----------------------------------------
    # Do derivations
    # -----------------------------------------

    # Date the page was added to the repo
    # The --format=%as gives the "author date" in short format
    my @log_lines = $self->{git}->RUN('log','--diff-filter=A','--format=%as','-1','--',$leaf->{file});
    $meta->{date_added} = $log_lines[0];

    $leaf->{meta} = $meta;

    return $leaf;
} # process


1;
