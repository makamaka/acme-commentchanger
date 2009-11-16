package Acme::BleachComment;

use strict;
use warnings;
use base qw( Acme::CommentChanger );
use PPI::Find;

our $VERSION = '0.01';


sub import {
    my ( $class ) = @_;
    my $bleach = $class->new;

    local $/ = undef;

    open ( my $fh, "<:utf8",$0 ) or die "Can't read source file $0.";
    my $code = <$fh>;
    close( $fh );

    $code = $bleach->change_code( $code );

    open ( $fh, ">:utf8",$0 ) or die "Can't write source code $0.";
    print $fh $code;
    close( $fh );

    exit;
}


#
# HANDLER
#

sub handler_token {
    sub {
        my ( $self, $token ) = @_;
        return $token->set_content('');
    }
}


sub handler_finish {
    sub {
        my ( $self, $document ) = @_;

        my $find = PPI::Find->new( sub {
            return 1 if ( $_[0]->isa( 'PPI::Statement::Include' ) );
            return 0;
        } );

        $find->start( $document ) or die "Failed to execute search";

        while ( my $elem = $find->match ) {
            next unless $elem =~ /\s*use\s+Acme::BleachComment/;
            $elem->delete;
        }

        return $document->content;
    };
}

1;
__END__

