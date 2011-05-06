package Spider::Muffet::Output::Factory;
use Spider::Muffet::Output::Writer;
use Spider::Muffet::Output::Writer::Raw;
use Spider::Muffet::Output::Writer::Xapian;
use Spider::Muffet::Output::Writer::Sitemapxml;
use Data::Dumper;
use Moose;
use List::MoreUtils qw(any);

has 'subclass_prefix' => (
   is       => 'ro',
   isa      => 'Str',
   default => 'Spider::Muffet::Output::Writer'
);

has 'available_subclasses' => (
   is       => 'ro',
   isa      => 'ArrayRef[Str]',
   default => sub { 
      [map {s/.pm$//; s/.*\///; $_;} glob 'Spider/Muffet/Output/Writer/*pm']
      #['Raw','Xapian','Htdig','Swish-e']} ,
    },
);

sub list_subclasses {
  my $self = shift;
  print join ", ", @{$self->available_subclasses};
}

sub create_writer {
   my ($self, $format) = (shift,shift);

   my $subclass = ucfirst lc $format;
   confess "\n!! $subclass is not supported or implemented yet. Try one of " 
            . join (", " , @{$self->available_subclasses}) . "\n\n==>"
       unless any { $subclass eq $_ } @{ $self->available_subclasses };
  
   my $class_name = join '::' => $self->subclass_prefix, $subclass;

   return $class_name->new;

}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
