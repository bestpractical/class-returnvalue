           use inc::Module::Install;

           name('Class-ReturnValue');
           abstract('A smart return value object');
           author('Jesse Vincent <jesse@bestpractical.com>');
	   version_from('lib/Class/ReturnValue.pm');
           license('perl');
           include_deps('Test::More', 5.004);
           include_deps('Test::Inline');
           requires('Test::More');
           requires('Test::Inline');
           requires('Devel::StackTrace');	
           check_nmake();      # check and download nmake.exe for Win32


{

    package MY;

    sub top_targets {
        my ($self) = @_;
        my $out = "POD2TEST_EXE = pod2test\n";

        $out .= $self->SUPER::top_targets(@_);
       # $out =~ s/^(pure_all\b.*)/$1 testifypods/m;

        $out .= "\n\ntestifypods : \n";
        foreach
          my $pod ( keys %{ $self->{MAN1PODS} }, keys %{ $self->{MAN3PODS} } )
        {
            ( my $test = $pod ) =~ s/\.(pm|pod)$//;
            $test =~ s|/|-|g;
            $test =~ s/^lib\W//;
            $test =~ s/\W/-/;
            $test = "embedded-$test.t";
            $out .= "\t$self->{NOECHO}\$(POD2TEST_EXE) " . "$pod t/$test\n";
        }

        return $out;
    }
}
	&Meta->write;
           &Makefile->write;

