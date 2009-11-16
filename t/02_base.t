#!/usr/bin/perl

use strict;
use Test::More tests => 10;
use utf8;

BEGIN {
    use_ok "Acme::CommentTeller";
    plan skip_all => "Acme::CommentTeller" if $@;
}

diag( "the story is equal or short than the comment" );

my $code  = join( '', <DATA> );
my $story = q{
あ
い
う
え
お
か
き
};

my $teller = Acme::CommentTeller->new();

is( $teller->change_comment_with_story( $code, $story ),
    q{#!/usr/bin/perl
use strict;

# あ

print "Hello World!\n"; # い

    # う
    # え
    # お
    print "Total comment is "; # か
    print "7\n"; # き
}
);


$story = q{
あいうえお
かき
};

is( $teller->change_comment_with_story( $code, $story, { auto_width => 0 } ),
    q{#!/usr/bin/perl
use strict;

# あいうえお

print "Hello World!\n"; # かき

    # 1comment
    # 2comment
    # 3comment
    print "Total comment is "; # foo bar
    print "7\n"; # 7
}
);

$story = q{
あいうえお
かき
くけこさしすせそ
};

is( $teller->change_comment_with_story( $code, $story, { auto_width => 0 } ),
    q{#!/usr/bin/perl
use strict;

# あいうえお

print "Hello World!\n"; # かき

    # くけこさしすせそ
    # 2comment
    # 3comment
    print "Total comment is "; # foo bar
    print "7\n"; # 7
}
);

#5

$story = q{
あいうえお
かき
くけこさしすせそ
};

is( $teller->change_comment_with_story( $code, $story, { auto_width => 1 } ),
    q{#!/usr/bin/perl
use strict;

# あいう

print "Hello World!\n"; # えお

    # かき
    # くけ
    # こさ
    print "Total comment is "; # しす
    print "7\n"; # せそ
}
);


#6

$story = q{
あいうえお
かき
くけこさしすせそ
たちつてと
};

is( $teller->change_comment_with_story( $code, $story, { auto_width => 1 } ),
    q{#!/usr/bin/perl
use strict;

# あいう

print "Hello World!\n"; # えお

    # かき
    # くけこさ
    # しすせそ
    print "Total comment is "; # たちつ
    print "7\n"; # てと
}
);

#7

$story = q{
あいうえお
かき
くけこさしすせそたちつてと
なにぬねのはひふへほ
};

is( $teller->change_comment_with_story( $code, $story, { auto_width => 1 } ),
    q{#!/usr/bin/perl
use strict;

# あいう

print "Hello World!\n"; # えお

    # かき
    # くけこさしすせ
    # そたちつてと
    print "Total comment is "; # なにぬねの
    print "7\n"; # はひふへほ
}
);


diag( "the story is long than the comment" );

$story = q{
あいうえおあいうえおあいうえおあいうえおあいうえお
かきくけこがぎぐげご
さしすせそざじずぜぞ
たちつてと
だぢづでど
なにぬねの
はひふへほ
まみむめも
やゆよらりるれろわをん
};

#8

is( $teller->change_comment_with_story( $code, $story, { auto_width => 0 } ),
    q{#!/usr/bin/perl
use strict;

# あいうえおあいうえおあいうえおあいうえおあいうえお

print "Hello World!\n"; # かきくけこがぎぐげご

    # さしすせそざじずぜぞ
    # たちつてと
    # だぢづでど
    print "Total comment is "; # なにぬねの
    print "7\n"; # はひふへほ
}
);


# 9

is( $teller->change_comment_with_story( $code, $story, { auto_width => 1 } ),
    q{#!/usr/bin/perl
use strict;

# あいうえおあいうえおあいうえおあいうえおあいうえお

print "Hello World!\n"; # かきくけこがぎぐげごさしすせそざじずぜぞ

    # たちつてとだぢづでど
    # なにぬねの
    # はひふへほ
    print "Total comment is "; # まみむめも
    print "7\n"; # やゆよらりるれろわをん
}
);

#10

$story = q{
あいうえお
かきくけこ
がぎぐげご
さしすせそ
ざじずぜぞ
たちつてと
だぢづでど
なにぬねの
はひふへほ
まみむめも
やゆよ
らりるれろ
わをん
};


is( $teller->change_comment_with_story( $code, $story, { auto_width => 1 } ),
    q{#!/usr/bin/perl
use strict;

# あいうえおかきくけこがぎぐげご

print "Hello World!\n"; # さしすせそざじずぜぞたちつてと

    # だぢづでどなにぬねのはひふへほ
    # まみむめも
    # やゆよ
    print "Total comment is "; # らりるれろ
    print "7\n"; # わをん
}
);


__DATA__
#!/usr/bin/perl
use strict;

# Well, I want to comment.

print "Hello World!\n"; # <= show "Hello World!"

    # 1comment
    # 2comment
    # 3comment
    print "Total comment is "; # foo bar
    print "7\n"; # 7
