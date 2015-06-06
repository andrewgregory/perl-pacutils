use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'PacUtils',
    VERSION_FROM  => 'lib/PacUtils.pm',
    PREREQ_PM     => { 'Test::More' => 0, 'Exporter' => '5.57' },
    ABSTRACT_FROM => 'lib/PacUtils.pm',
    AUTHOR        => 'Andrew Gregory <andrew.gregory.8@gmail.com>',
    LIBS          => ['-lpacutils -lalpm'],
    DEFINE        => '',
    INC           => '-I.',
    OBJECT        => '$(O_FILES)',
);
