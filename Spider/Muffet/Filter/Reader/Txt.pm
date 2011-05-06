package Spider::Muffet::Filter::Reader::Txt;
use Moose;

extends 'Spider::Muffet::Filter::Reader';

# have to override without +content here as I want to use a trigger, which
# moose does not allow
has 'content' => (
    is       => 'rw',
    isa      => 'Str',
    trigger =>  sub {
        my $self         = shift;
        my $text = $self->content;
        $text=~s/[\r\n]+/ /g;
        $self->body($text);
    } 
);
no Moose;
__PACKAGE__->meta->make_immutable;
1;
