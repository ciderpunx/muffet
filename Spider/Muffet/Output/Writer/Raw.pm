package Spider::Muffet::Output::Writer::Raw;
use Moose;
extends 'Spider::Muffet::Output::Writer';

sub BUILD {
  my $self=shift;
  $self->output_to('&STDOUT');
}

sub output_record {
  my $self=shift;
  my $fh = $self->out;
  print $fh "title: " . $self->title . "\n";
  print $fh "url: " . $self->url . "\n";
  print $fh "body: " . $self->body . "\n";
  print $fh "modified: " . $self->modified . "\n";
  print $fh "category: " . $self->category . "\n";
  print $fh "tags: " . $self->tags . "\n";
}

sub flush {
  return 1;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
