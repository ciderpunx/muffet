package Spider::Muffet::Filter::Reader::Pdf;
use Moose;
use CAM::PDF;

extends 'Spider::Muffet::Filter::Reader';

# have to override without +content here as I want to use a trigger, which
# moose does not allow
has 'content' => (
    is       => 'rw',
    isa      => 'Str',
    trigger =>  sub {
        my $self         = shift;
        my $doc  = CAM::PDF->new($self->content);
        my $text = '';

        foreach my $p (1..$doc->numPages()) {
          $text .= $doc->getPageText($p);
        }
        $text=~s/[\r\n]+/ /g;
        $self->body($text);

    } 
);
no Moose;
__PACKAGE__->meta->make_immutable;
1;
