#!/usr/bin/perl -w
#Perl script to watch a folder for new pdf files, email them,
#and back them up

#Script qui vérifie la présence de fichiers pdf dans un folder,
#envoie par email et backup les fichiers trouvés
use strict;
use MIME::Lite;
use File::Copy;

my $lock;
my $lockfile = qq{/tmp/pdfscanlock};

#Si une autre instance du script tourne deja, on quitte.
if(-e $lockfile){
    print qq{Lockfile "$lockfile" exists. This script is already running, or something has gone wrong.\n};
    exit;
}

#Subroutine qui email et backup les fichiers. Elle prends 2 arguments:
#le username UNIX et une addresse mail.
sub sendnewfiles{
    my $user;
    my $mailaddr;
    my $folder;
    my $file;
    my $uid;
    my $gid;
    my $login;
    my $pass;
    my @array;
    ($user,$mailaddr) = @_;
    #Ici on décrète que les home sont dans /home. A mettre à jour éventuellement avec une variable d'environnement.
    $folder = qq{/home/$user/pdfscan/};
    #On créé le folder de destination des documents scannés
    mkdir($folder, 0700);
    #On chope les infos du user
    ($login,$pass,$uid,$gid) = getpwnam($user);
    #On rends le user propriétaire du folder
    chown($uid,$gid,$folder);
    #On regarde le contenu du folder et on fait notre ratatouille.
    opendir( DIR, $folder );
    while( $file = readdir( DIR ) ){
        push( @array, $file );
    }
    foreach( @array ){
        #Si ya des fichier .pdf on les email au user et on les backup
        if( $_ =~ /.*\.pdf$/ ){
            #On créé le message à envoyer. Ce truc est génial, il utilise le mailer du systeme;
            #Par défaut sendmail.
            my $msg = MIME::Lite->new(
            #From    => q{Admin@maison.local},
            To      => $mailaddr,
            Subject => qq{Scanned Document: $_},
            Type    => q{TEXT},
            Data    => q{Here are your scanned documents. If not, contact your admin.}
            );
            $msg->attach(
            Type     => q{application/pdf},
            Path     => qq{$folder/$_},
            Filename => $_
            );
            $msg->send;
            move(qq{$folder/$_},qq{$folder/$_.bak});
            print qq{$mailaddr\n$user\n$folder\n};
        }
    }
}

#on créé notre "lockfile".
open($lock, '>', $lockfile) or die(qq{can't open lockfile: $!\n});
close($lock);
#on balance la sauce.
sendnewfiles(q{username},q{username@example.com});
#On vire le lockfile.
unlink($lockfile);
__END__
