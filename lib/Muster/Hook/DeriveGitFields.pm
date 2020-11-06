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
use IPC::System::Simple qw(capture);
use YAML::Any;
use Carp;
use Cwd;

=head1 METHODS

=head2 register

Initialize, and register hooks.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{config} = $conf->{hook_conf}->{'Muster::Hook::DeriveGitFields'};

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
    # Do nothing if the repo does not exist
    if (! -d $self->{config}->{repo_dir})
    {
        return $leaf;
    }

    my $meta = $leaf->meta;

    # -----------------------------------------
    # Do derivations
    # -----------------------------------------
    # NOTE: I tried using Git::Wrapper but it kept on failing,
    # so I am doing a system call instead.
    # Okay, so THAT does not work either.
    # This will never work when it is called inside a git hook. (sigh)

    # Date the page was added to the repo
    # Need to use '--follow' for renames, even though sometimes it goes too far back
    # The --format=%as gives the "author date" in short format
    my @log_lines = ();
    my $cmd = sprintf('git -C %s log --diff-filter=A --format=%%as --follow -1 -- %s',
        $self->{config}->{repo_dir},
        $leaf->{filename});
    @log_lines = capture($cmd);
    $meta->{date_added} = $log_lines[0] if $log_lines[0];

    $leaf->{meta} = $meta;

    return $leaf;
} # process


1;
