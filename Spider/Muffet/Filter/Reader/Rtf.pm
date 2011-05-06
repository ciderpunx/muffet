package Spider::Muffet::Filter::Reader::Rtf;
use Moose;
use RTF::TEXT::Converter;

extends 'Spider::Muffet::Filter::Reader';

# have to override without +content here as I want to use a trigger, which
# moose does not allow
has 'content' => (
    is       => 'rw',
    isa      => 'Str',
    trigger =>  sub {
        my $self         = shift;
        my $text = '';
        my $object = RTF::TEXT::Converter->new(
                                output => \$text
                                                );

        $object->parse_string($self->content);
        $text=~s/[\r\n]+/ /g;
        $self->body($text);
    } 
);
no Moose;
__PACKAGE__->meta->make_immutable;
1;
