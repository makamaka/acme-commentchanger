package Acme::CommentChanger;

use 5.008;

use strict;
use warnings;
use PPI;
use Carp ();

our $VERSION = '0.01';

sub new {
    my ( $class, $opt ) = @_;
    $opt ||= {};
    bless $opt, $class;
}


sub create_ppi_document {
    my ( $self, $code, $opt ) = @_;
    my $document = PPI::Document->new( \$code ) or Carp::croak( PPI::Document->errstr );
}


sub change_code {
    my ( $self, $code, $opt ) = @_;

    Carp::croak 'Usage: change_code( $code[, $hash_ref] )' unless @_ > 1;
    Carp::croak 'Option must be a hash reference' if ( defined $opt and ref( $opt ) ne 'HASH' );

    $opt ||= {};

    my $document = $self->create_ppi_document( $code, $opt );

    return $self->handle_token(
        $document,
        $self->handler_init,
        $self->handler_token,
        $self->handler_finish,
        $opt,
    );
}


sub handle_token {
    my ( $self, $document, $handler_init, $handler_token, $handler_finish, $opt ) = @_;
    my $shebang_is_found;

    $handler_init->( $self, $document, $opt ) if ( $handler_init and ref( $handler_init ) eq 'CODE' );

    for my $token ( $document->tokens ) { # count comment line

        next unless ( $token->isa( 'PPI::Token::Comment' ) and $token->content =~ /\s*#/ );

        if ( not $shebang_is_found and substr( $token->content, 0, 2 ) eq '#!' ) {
            $shebang_is_found = 1;
            next;
        }

        $handler_token->( $self, $token );
    }

    return $handler_finish->( $self, $document );
}


#
# You overwrite these methods.
#


sub handler_init {
    return sub {
        my ( $self, $document, $opt ) = @_;
    }
}


sub handler_token {
    return sub {
        my ( $self, $token ) = @_;
        my $content = $token->content;
        $token->set_content( $content );
    }
}


sub handler_finish {
    sub {
        my ( $self, $document ) = @_;
        return $document->content;
    };
}



1;
__END__

=pod

=head1 NAME

Acme::CommentChanger - change your source comment.

=head1 SYNOPSYS

  package YourModule;
  use strict;
  use base qw( Acme::CommentChanger );
  
  sub handler_token {
      return sub {
          my ( $self, $token ) = @_; # $token is PPI::Token::Comment
          my $content = $token->content;
          
          #
          # ....
          #
          
          $token->set_content( $content );
      }
  }
  
  #
  package main;
  
  my $changer = YourModule->new;
  my $code    = 'your source code';
  
  my $changed_code = $changer->change_code( $code );


=head1 DESCRIPTION

A source code comments (#headed) changer.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Makamaka Hannyaharamitu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
