package Textmining::Assert::Storable;

use Exporter 'import';
use Storable qw(store_fd fd_retrieve);

our @EXPORT_OK = (
    qw(store retrieve)
);

#TODO Test for _store
sub store($$) {
    my $data        =   shift;
    my $location    =   shift;

    open  my $FH , ">", $location or return undef;
    store_fd \$data, $FH;
    close $FH;
}

#TODO Test for _retrieve
sub retrieve($) {
    my $location    = shift;

    open  my $FH , "<", $location or return undef;
    my $data = fd_retrieve($FH);
    close $FH;
    return ${$data};
}

