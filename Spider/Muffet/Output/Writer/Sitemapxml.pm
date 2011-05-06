package Spider::Muffet::Output::Writer::Sitemapxml;
use Moose;
extends 'Spider::Muffet::Output::Writer';

sub BUILD {
  my $self=shift;
  $self->output_to('&STDOUT');
  my $fh = $self->out;
  print $fh '<?xml version="1.0" encoding="UTF-8"?>'
            . "\n\t"
            . '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">';

}

sub output_record {
  my $self=shift;
  my $fh = $self->out;
  print $fh "\n\t\t<url>\n\t\t\t<loc>"
            . $self->url
            . "</loc>\n\t\t</url>";
 
 # print $fh "title: " . $self->title . "\n";
 # print $fh "url: " . $self->url . "\n";
 # print $fh "body: " . $self->body . "\n";
 # print $fh "modified: " . $self->modified . "\n";
 # print $fh "category: " . $self->category . "\n";
 # print $fh "tags: " . $self->tags . "\n";
}

sub flush {
  my $self = shift;
  my $fh = $self->out;
  print $fh "\n\t</urlset>\n";

  return 1;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
