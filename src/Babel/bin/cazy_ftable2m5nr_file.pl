#######################################################################################################
#
# This script transforms the output from the get_cazy_table.pl script.
#
# INPUT:	A tab delimited file with following columns
#			CAZy family, ProteinID, Organism, ec, genbank protein accession, uniprotID 
#			
# OUTPUT: Two tab delimited files with following columns: 
#			md5, Cazy Protein ID, Cazy family, Organism, src
#           Cazy Protein ID , [ xref_protein_id:source ] 
#
# Author: Andreas Wilke
#
#######################################################################################################

#!/usr/bin/perl -w

use strict ;
use warnings;

use JSON;
use Getopt::Long;
use LWP::Simple;
use LWP::UserAgent ;
use HTTP::Request::Common;

use Data::Dumper;

# Define and set default parameters

my $api_url  = "http://api.metagenomics.anl.gov/m5nr" ;
my $resource = "accession"; 
my $debug    		= 0;		# flag for debug output
my $help     		= 0;		# flag for help output
my $file     		= undef;	# input file
my $header   		= 1;		# if true will skip first line of input file 	
my $md5mappingFile 	= undef ; 	# output file
my $aliasFile      	= undef ; 	# output file


# Set parameters based on user options

GetOptions (
    'url=s'      	=> \$api_url ,
    'debug'      	=> \$debug  ,
    'file=s'     	=> \$file   ,
	'help'	     	=> sub { print &help() ; exit(1) }  ,
	'no_header!' 	=> \$header ,
	'mappingFile=s' => \$md5mappingFile ,
	'aliasFile=s'   => \$aliasFile ,
    );

if ($help) {
	print &help() ;
	 exit 0; 
}


my $ua = LWP::UserAgent->new;
$ua->agent("Cazy2m5nr/0.1 ");

my $json = JSON->new->allow_nonref;

# Create a request
my $url = $api_url ."/" . $resource ;



# perform some checks

unless($file) {
	print STDERR "You have to pass a filename:\n";
	print STDERR &help() ;
	exit(1);
}

# read input file and build output
open(FILE , $file) or die "Can't open file " . ($file || "NO FILENAME" ) ."!\n";

if ($md5mappingFile){
	open (MAPPING , ">$md5mappingFile") or die "Can't open file $md5mappingFile!\n";
}
if ($aliasFile){
	open (ALIAS , ">$aliasFile") or die "Can't open file $aliasFile!\n";
}

if($header) {
	print STDERR "DEBUG:(HEADER)\t" , "Skipping header\n" if ($debug) ;
	my $line = <FILE> ;
	print STDERR "DEBUG:(HEADER)\t" , $line  if ($debug) ;
}

while (my $line = <FILE>){
	
	# parse input line and split into fields
    chomp $line;
	my ($cazy_family, $proteinID , $organism, $ec, $genbankID, $uniprotID) = split "\t" , $line ;
	
	# save IDs for alias list
	my @xrefs ;
	push @xrefs , "$genbankID:Genbank" if ($genbankID);
	push @xrefs , "$uniprotID:UniProt" if ($uniprotID);

	# build request and query m5nr
    my $req = HTTP::Request->new(GET => $url . "/" . $genbankID );
    my $res = $ua->request($req);

    if ($res->is_success){

        if (1 or $res->header('Content-Type') eq "application/json") {

            my $data = $json->decode( $res->decoded_content );
			
			# print data structure if debug option is set
			if($debug){
				print STDERR "DEBUG:\t" , Dumper $data ;
			}
			
			
			if ($data->{total_count}){
			
				
				# set output md5, Cazy Protein ID, Cazy family, Organism, src
				my $out   = join "\t" , $data->{data}->[0]->{md5} , $proteinID , $cazy_family , $organism , "CAZy" ;
				my $alias = join "\t" , $proteinID , @xrefs ;
				
				if ($md5mappingFile) {
					print MAPPING  $out , "\n" ;
				}
				else{
					print "MD5MAPPING:\t" , $out , "\n" ;
				}
				
				if ($aliasFile) {
					print ALIAS $alias , "\n" ;
				}
				else{
					print "ALIAS:\t" , $alias , "\n" ;
				}
			}

            
        }
    }
      else{
          print STDERR "No success!\n";
		  print STDERR Dumper $res ;
		  exit(1);
      }
  }


sub help{
	return "$0 --file FILENAME [ --url API_URL | --help ]\n";
} 
