package Acme::CommentTeller;

use strict;
use warnings;
use base qw( Acme::CommentChanger );

use Encode;

our $VERSION = '0.01';

my $IMPORT_MODE;




sub import {
    my ( $class, $file ) = @_;

    return unless defined $file;

    my $asc = $class->new;

    local $/ = undef;

    open ( my $fh, "<:utf8", $file ) or die "Can't read story file $file.";
    my $story = <$fh>;
    close( $fh );

    open ( $fh, "<:utf8",$0 ) or die "Can't read source file $0.";
    my $code = <$fh>;
    close( $fh );

    $IMPORT_MODE = 1;

    $code = $asc->change_comment_with_story( $code, $story, { auto_width => 1 } );

    open ( $fh, ">:utf8",$0 ) or die "Can't write source code $0.";
    print $fh $code;
    close( $fh );

    exit;
}


#
# API
#

sub change_comment_with_story {
    my ( $self, $code, $story, $opt ) = @_;
    $self->story( $story );
    return $self->change_code( $code, ( $opt || {} ) );
}


sub story {
    my ( $self, $story ) = @_;
    $self->{ story } = $story if @_ > 1;
    $self->{ story };
}


#
# HANDLER
#

sub handler_init {
    my ( $self, $document, $opt ) = @_;
    sub {
        my ( $self, $document, $opt ) = @_;
        my $num = 0;
        # count comment number
        $self->{_comment_num} = $self->handle_token( $document, undef, sub { $num++; }, sub { return $num; } );
        # make story line
        $self->_set_story( \do{ $self->story }, $opt );
    };
}


sub handler_token {
    sub {
        my ( $self, $token ) = @_;
        return $self->_convert_token_comment( $token );
    }
}


sub handler_finish {
    sub {
        my ( $self, $document ) = @_;

        if ( $IMPORT_MODE ) {
            require PPI::Find;
            my $find = PPI::Find->new( sub {
                return 1 if ( $_[0]->isa( 'PPI::Statement::Include' ) );
                return 0;
            } );

            $find->start( $document ) or die "Failed to execute search";

            while ( my $elem = $find->match ) {
                next unless $elem =~ /\s*use\s+Acme::CommentTeller/;
                for my $token ( $elem->tokens ) {
                    if ( $token->class =~ /PPI::Token::Quote/ ) {
                        $token->set_content('');
                        print $token->previous_token->set_content('');
                    }
                }
            }

        }

        return $document->content;
    };
}


#
# INTERNAL
#

sub _convert_token_comment {
    my ( $self, $token ) = @_;

    $token->content =~ /^([\s]*)#.*(\r?\n)$/;

    my $head    = $1 || '';
    my $tail    = $2 || "";
    my $comment = $self->_next_line();

    $token->set_content( $head . '# ' . $comment . $tail ) unless $comment eq '';
}


sub _set_story {
    my ( $self, $story_ref, $opt ) = @_;

    $opt ||= {};

    my $width = $opt->{ width } || 0;

    $self->{ story_box } = [];

    utf8::upgrade( $$story_ref );

    if ( $opt->{ auto_width } and $self->{ _comment_num } and length $$story_ref ) {
        $self->_adjust_story_line( $story_ref, $opt );
        $width = 0;
    }

    for my $line ( split /\r?\n/, $$story_ref ) {

        next if ( $line =~ /^[\s]*$/ );

        if ( $width and length( $line ) > $width ) {
            while ( $line =~ /(.{1,$width})/g ) {
                push @{ $self->{ story_box } }, $1 if length $1;
            }
        }
        else {
            push @{ $self->{ story_box } }, $line;
        }
    }

    $self->{ line_num }  = scalar @{ $self->{ story_box } };
    $self->{ line_cnt }  = 0;
}


sub _adjust_story_line {
    my ( $self, $story_ref, $opt ) = @_;
    my $total = length( $$story_ref );
    my $comment_num = $self->{_comment_num};
    my $ws = [];

    for my $line ( split /\r?\n/, $$story_ref ) {
        next if ( $line =~ /^[\s]*$/ );
        my $len = length( $line );
        my $weight = int( $len / $total * $comment_num ) + 1;
        push @$ws, [ $len, $weight, $line ];
    }

    my $new_lines;

    if ( $comment_num >= @$ws ) { # コメント行数のほうが置き換えラインより多い
        my ( $min, $max ) = ( 0, $#{ $ws } );
        my @sorted = _sort_weight( $ws );

        while ( $min <= $max ) {
            if ( $sorted[ $min ]->[ 1 ] == 0 ) {
                $sorted[ $min ]->[ 1 ] = 1;
                $sorted[ $max ]->[ 1 ]--;
                @sorted = _sort_weight( $ws );
            }
            $min++;
        }

        my $total_weight = 0;
        map { $total_weight += $_->[1] } @sorted;

        while ( $total_weight > $comment_num ) {
            $sorted[ $max ]->[ 1 ]--;
            $total_weight--;
            @sorted = _sort_weight( $ws );
        }

        while ( $total_weight < $comment_num ) {
            $sorted[ $max ]->[ 1 ]++;
            $total_weight++;
            @sorted = _sort_weight( $ws );
        }

        for my $w ( @$ws ) {

            if ( $w->[1] > 1 ) {
                my $split_len = int( $w->[0] / $w->[1] + 0.5 ) || 1;
                my @ls;

                while ( $w->[2] =~ /(.{1,$split_len})/g ) {
                    push @ls, $1 . "\n";
                }

                if ( @ls > $w->[1] ) {
                    my $last_line = pop @ls;
                    chomp $ls[ -1 ];
                    $ls[ -1 ] .= $last_line;
                }

               $new_lines .= join( "\n", @ls );
            }
            else {
                $new_lines .= $w->[2] . "\n";
            }

        }
    }
    else {  # コメント行数のほうが置き換えラインより少ない
        my ( $current, $next );

        while ( scalar @$ws > $comment_num ) {
            my @sum;

            for my $i ( 0 .. $#{ $ws } - 1 ) {
                $current = $ws->[ $i ];
                $next    = $ws->[ $i + 1 ];
                push @sum, [ $i, $ws->[ $i ]->[1] + $ws->[ $i + 1 ]->[1] ];
            }

            @sum = _sort_weight( \@sum );

            my $i = $sum[0]->[0];
            $ws->[ $i ]->[ 2 ] .= $ws->[ $i + 1 ]->[ 2 ];

            my $len = $ws->[ $i ]->[0] = length( $ws->[ $i ]->[ 2 ] );
            $ws->[ $i ]->[1] = int( $len / $total * $comment_num ) + 1;

            splice( @$ws, $i + 1, 1 );
        }

        for my $w ( @$ws ) {
            $new_lines .= $w->[2] . "\n";
        }
    }

    $$story_ref = $new_lines;

    return;
}


sub _next_line {
    my $self = $_[0];
    return '' if ( $self->{ line_cnt } >= $self->{ line_num } );
    $self->{ story_box }->[ $self->{ line_cnt }++ ];
}


sub _sort_weight {
    my ( $ws ) = @_;
    return map  { $_->[0] }
           sort { $a->[1] <=> $b->[1] }
           map  { [ $_, $_->[1] ] } @$ws
    ;
}


1;
__END__

