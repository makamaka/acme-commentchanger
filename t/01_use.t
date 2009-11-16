#!/usr/bin/perl

use strict;
use Test::More tests => 1;

BEGIN {
    use_ok "Acme::CommentTeller";
    plan skip_all => "Acme::CommentTeller" if $@;
}
