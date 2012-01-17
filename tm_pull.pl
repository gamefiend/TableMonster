#!/usr/bin/perl -w

use strict;
use WWW::Mechanize;
use JSON -support_by_pp;
use URI::Escape;
use Getopt::Long;
use Data::Dumper;

my $search_base = "http://search.twitter.com/search.json?q=" ;
my $search_params = "&rpp=100&result_type=mixed";
my ($hashtag, $file, $suppress);

my $parameters = GetOptions("hash=s" => \$hashtag,
							"file=s" => \$file,
							"suppress" => \$suppress,
							);
# parameter sanity checking
die "need --hashtag parameter" unless $hashtag;

my $search_query = uri_escape($hashtag);
my $search_URI = $search_base . $search_query . $search_params;

my $data = fetch_json_page($search_URI);

foreach my $result (@{$data->{'results'}}){
	my $rtext = $result->{'text'};
	next if $rtext =~ /RT/;
	my @rtags = get_tags($rtext);
	$rtext =~ s/#\w*//g;
	my $rfrom_user = $result->{'from_user'};
	if (!$suppress){
		print "TEXT:\n" . $rtext . "\n";
		print "USER: " . $rfrom_user;
		print "\tTAG: ";
		print join ' ',@rtags; 
		print "\n\n";
	}
	if ($file){
		print "Saving to file...\n";
		save_to_file($rtext,$rfrom_user);	
	}
}


sub since {
	#calculate when weshould make the 
}
sub fetch_json_page{
	my $json_url = shift;
	my $browser = WWW::Mechanize->new();
	#download json page:
	print "Getting twitter search results\n";
	$browser->get ($json_url);
	my $content = $browser->content();
	my $json = new JSON;
	my $json_text = $json->decode($content);
	return $json_text;
}

sub get_tags{
	my $text_with_tags = shift;
	my @taglist;
	@taglist = ($text_with_tags =~ /(#\w*)/igs);
	return @taglist;
}

sub save_to_file {
	my $text = shift;
	my $user = shift;
	my $handle;
	open ($handle, ">>$file") or die "Can't open file for writing: $! \n";
	print $handle "$text\t$user\n";
	close ($handle);
}