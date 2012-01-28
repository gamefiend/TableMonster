#!/usr/bin/perl -w

use strict;
use WWW::Mechanize;
use JSON -support_by_pp;
use URI::Escape;
use Getopt::Long;
use Data::Dumper;

my ($hashtag, $file, $suppress, $dump, $init);

my $parameters = GetOptions("hash=s" => \$hashtag,
							"file=s" => \$file,
							"suppress" => \$suppress,
							"dump" => \$dump,
							"init" => \$init
							);
# parameter sanity checking
die "need --hashtag parameter" unless $hashtag;

my $search_base = "http://search.twitter.com/search.json?q=" ;
my $search_results = "&rpp=100&result_type=mixed";
my $search_params = ($init) ? $search_results : get_since();
my $search_query = uri_escape($hashtag);
my $search_URI = $search_base . $search_query . $search_params;

print $search_URI;
#exit;

my $data = fetch_json_page($search_URI);

#Dump the data structure and leave if we pass --dump
if ($dump){
	print Dumper($data);
	exit;
}
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

since($data);


## Subroutines

sub since {
	my $write_since_data = shift;
	my @idlist = ();
	my @sorted_ids = ();
	my $since_file = ".since_" . $hashtag;
	foreach my $id (@{$write_since_data->{'results'}}){
		push @idlist, $id->{'id'};
	} 
	#testing code
	# print join "\n", @idlist;
	# exit;
	##
	if (@idlist){
	@sorted_ids = sort { $b <=> $a } @idlist; #leave the highest id at the beginning of the array.
	open my $SINCE_W, ">$since_file" or die "Unable to write to $since_file : $! \n";
	print $SINCE_W $sorted_ids[0] . "\n";
	}
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
sub get_since{
	my $since_file = ".since_" . $hashtag;
	if (-e $since_file){
		open my $SINCE, "<$since_file" || die "can't open the .since file : $!\n";
		my $id = <$SINCE>;
		chomp($id);
		my $since_str = $search_results . "&since_id=" . $id ;
		return $since_str;
	}

}
sub save_to_file {
	my $text = shift;
	my $user = shift;
	my $handle;
	open ($handle, ">>$file") or die "Can't open file for writing: $! \n";
	print $handle "$text\t$user\n";
	close ($handle);
}