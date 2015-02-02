package Textmining::Assert::Storable;

use Storable qw(store_fd fd_retrieve);

#TODO Test for _store
sub store($$) {
    my $data        =   shift;
    my $location    =   shift;

    open  my $FH , ">", $location || return undef;
    store_fd \$data, $FH;
    close $FH;
}

#TODO Test for _retrieve
sub retrieve($) {
    my $location    = shift;

    open  my $FH , "<", $location || return undef;
    my $data = fd_retrieve($FH);
    close $FH;
    return ${$data};
}

