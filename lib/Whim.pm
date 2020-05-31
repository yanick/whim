package Whim;
use Mojo::Base 'Mojolicious';

use Mojo::File qw(curfile);
use Whim::Core;

our $VERSION = '2020.05.18.00';

sub startup {
    my $self = shift;

    # Switch to installable home directory
    $self->home(Mojo::Home->new(curfile->sibling('Whim')));

    # Switch to installable "public" directory
    $self->static->paths->[0] = $self->home->child('public');

    # Switch to installable "templates" directory
    $self->renderer->paths->[0] = $self->home->child('templates');

    push @{ $self->commands->namespaces }, 'Whim::Command';

    # Create a 'whim' helper containing our Whim::Core object
    $self->helper(
        whim => sub {
            state $whim = Whim::Core->new(
                {   data_directory => $self->home->child('data'),
                    author_photo_directory =>
                        $self->home->child('public')->child('author_photos'),
                }
            );
        }
    );

    # Set up routes for the listener
    my $r = $self->routes;

    $r->get('/')->to('listen#default');
    $r->post('/')->to('listen#receive');

    $r->get('/display_wms')->to('display#display');

}

1;
