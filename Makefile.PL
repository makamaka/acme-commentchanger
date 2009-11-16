use 5.008;
use ExtUtils::MakeMaker;


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Acme::CommentChanger',
    'VERSION_FROM'	=> 'lib/Acme/CommentChanger.pm', # finds $VERSION
    'PREREQ_PM' => {
		      "PPI"	=> 1.200,
		      "Test::More"	=> 0,
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Acme/CommentChanger.pm', # retrieve abstract from module
       AUTHOR     => 'Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>') : ()),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl', ) : () ),
);
