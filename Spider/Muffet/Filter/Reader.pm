package Spider::Muffet::Filter::Reader;
use Moose;
use CAM::PDF;

has 'content' => (
   is       => 'rw',
   isa      => 'Str',
);

has 'body' => (
   is       => 'rw',
   isa      => 'Str',
);
no Moose;
__PACKAGE__->meta->make_immutable;
1;
