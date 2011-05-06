package Spider::Muffet::Filter::Factory;
use Spider::Muffet::Filter::Reader;
use Spider::Muffet::Filter::Reader::Pdf;
use Spider::Muffet::Filter::Reader::Rtf;
#use Spider::Muffet::Filter::Reader::Doc;
use Spider::Muffet::Filter::Reader::Txt;
#use Spider::Muffet::Filter::Reader::ODT;
use Moose;
use Data::Dumper;
use List::MoreUtils qw(any);

has 'subclass_prefix' => (
   is       => 'ro',
   isa      => 'Str',
   default  => 'Spider::Muffet::Filter::Reader'
);

has 'available_subclasses' => (
   is       => 'ro',
   isa      => 'ArrayRef[Str]',
   default => sub { 
      [map {s/.pm$//; s/.*\///; $_;} glob 'Spider/Muffet/Filter/Reader/*pm']
    },
);

has _content_to_subclass_map => (
  traits    => ['Hash'],
  is      => 'ro',
  isa     => 'HashRef[Str]',
  default => sub { { 
      'text/plain'      => 'Txt',
      'application/pdf' => 'Pdf', 
      'application/rtf' => 'Rtf',
    }
  },
  handles => {
    get_ct  => 'get',
  },
);

sub create_reader {
   my ($self, $format) = (shift,shift);
   my $subclass = $self->get_ct(lc $format);
   confess("\n!! $subclass content type is not supported or implemented yet. Try one of " 
            . join (", " , @{$self->available_subclasses}) )
       unless any { $subclass eq $_ } @{ $self->available_subclasses };
  
   my $class_name = join '::', $self->subclass_prefix, $subclass;

   return $class_name->new;

}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
