#!/usr/bin/perl -w
#Perl script to watch a folder for new pdf files, email them,
#and back them up

#Script qui vérifie la présence de fichiers pdf dans un folder,
#envoie par email et backup les fichiers trouvés
use strict;
use MIME::Lite;
use File::Copy;
use Fcntl qw(:flock SEEK_END);
use File::HomeDir;

my $lock;
my $lockfile = qq{/tmp/pdfscanlock};

open(STDOUT, '>>', qq{/var/log/}.$0.qq{.log});

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
    my $time;
    my $home;

    ($user,$mailaddr) = @_;
    $home = File::HomeDir->users_home($user);
    $folder = qq{$home/pdfscan/};

    #On créé le folder de destination des documents scannés
    if(! -d $folder){
        mkdir($folder, 0700) or return;
    }
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
            $time = scalar(localtime(time));
            print qq{$time: New document found.\n};
            print qq{$time: $mailaddr\n$time: $user\n$time: $folder\n};
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
            $time = scalar(localtime(time));
            print qq{$time: Document sent.\n};
        }
    }
}

#on créé notre "lockfile".
open($lock, '>', $lockfile) or die qq{can't open lockfile: $!\n};
flock($lock, LOCK_EX|LOCK_NB) or die qq{$0 already running! $!\n};

while(1){
    sleep(1);
    
    #on balance la sauce.
    sendnewfiles(q{quentin},q{root@localhost});
}
__END__
