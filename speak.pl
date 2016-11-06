#!/usr/bin/perl

#--------------------------------------------------
#
# Copyright 2012 Michal Fapso (https://github.com/michalfapso)
# 
# Modified by Glutanimate (https://github.com/glutanimate)
#
# Usage:
# ./speak.pl en input.txt output.mp3
#
# Prerequisites:
# sudo apt-get install libwww-perl libwww-mechanize-perl libhtml-tree-perl sox libsox-fmt-mp3
#
# Compiling sox:
# Older versions of sox package might not have the support for mp3 codec,
# so just download sox from http://sox.sourceforge.net/
# install packages libmp3lame-dev libmad0-dev
# and compile sox
#
# List of language code names for Google TTS:
#	af	Afrikaans
#	sq	Albanian
#	am	Amharic
#	ar	Arabic
#	hy	Armenian
#	az	Azerbaijani
#	eu	Basque
#	be	Belarusian
#	bn	Bengali
#	bh	Bihari
#	bs	Bosnian
#	br	Breton
#	bg	Bulgarian
#	km	Cambodian
#	ca	Catalan
#	zh-CN	Chinese (Simplified)
#	zh-TW	Chinese (Traditional)
#	co	Corsican
#	hr	Croatian
#	cs	Czech
#	da	Danish
#	nl	Dutch
#	en	English
#	eo	Esperanto
#	et	Estonian
#	fo	Faroese
#	tl	Filipino
#	fi	Finnish
#	fr	French
#	fy	Frisian
#	gl	Galician
#	ka	Georgian
#	de	German
#	el	Greek
#	gn	Guarani
#	gu	Gujarati
#	ha	Hausa
#	iw	Hebrew
#	hi	Hindi
#	hu	Hungarian
#	is	Icelandic
#	id	Indonesian
#	ia	Interlingua
#	ga	Irish
#	it	Italian
#	ja	Japanese
#	jw	Javanese
#	kn	Kannada
#	kk	Kazakh
#	rw	Kinyarwanda
#	rn	Kirundi
#	ko	Korean
#	ku	Kurdish
#	ky	Kyrgyz
#	lo	Laothian
#	la	Latin
#	lv	Latvian
#	ln	Lingala
#	lt	Lithuanian
#	mk	Macedonian
#	mg	Malagasy
#	ms	Malay
#	ml	Malayalam
#	mt	Maltese
#	mi	Maori
#	mr	Marathi
#	mo	Moldavian
#	mn	Mongolian
#	sr-ME	Montenegrin
#	ne	Nepali
#	no	Norwegian
#	nn	Norwegian (Nynorsk)
#	oc	Occitan
#	or	Oriya
#	om	Oromo
#	ps	Pashto
#	fa	Persian
#	pl	Polish
#	pt-BR	Portuguese (Brazil)
#	pt-PT	Portuguese (Portugal)
#	pa	Punjabi
#	qu	Quechua
#	ro	Romanian
#	rm	Romansh
#	ru	Russian
#	gd	Scots Gaelic
#	sr	Serbian
#	sh	Serbo-Croatian
#	st	Sesotho
#	sn	Shona
#	sd	Sindhi
#	si	Sinhalese
#	sk	Slovak
#	sl	Slovenian
#	so	Somali
#	es	Spanish
#	su	Sundanese
#	sw	Swahili
#	sv	Swedish
#	tg	Tajik
#	ta	Tamil
#	tt	Tatar
#	te	Telugu
#	th	Thai
#	ti	Tigrinya
#	to	Tonga
#	tr	Turkish
#	tk	Turkmen
#	tw	Twi
#	ug	Uighur
#	uk	Ukrainian
#	ur	Urdu
#	uz	Uzbek
#	vi	Vietnamese
#	cy	Welsh
#	xh	Xhosa
#	yi	Yiddish
#	yo	Yoruba
#	zu	Zulu 
#--------------------------------------------------

use strict;

use File::Path qw( rmtree );
use HTTP::Cookies;
use WWW::Mechanize;
use LWP;
use HTML::TreeBuilder;
use Data::Dumper;
$Data::Dumper::Maxdepth = 2;

if (scalar(@ARGV) != 3) {
	print STDERR "Usage: $0 LANGUAGE IN.txt OUT.mp3\n";
	print STDERR "\n";
	print STDERR "Examples: \n";
	print STDERR "    echo \"Hello world\" | ./speak.pl en speech.mp3\n";
	print STDERR "    cat file.txt       | ./speak.pl en speech.mp3\n";
	exit;
}

my $language = $ARGV[0]; # sk | en | cs | ...
my $textfile_in = $ARGV[1];
my $all_mp3_out = $ARGV[2];

my $SENTENCE_MAX_CHARACTERS = 100; # limit for google tts
my $TMP_DIR = "$all_mp3_out.tmp";
my $RECAPTCHA_URL = "http://www.google.com/sorry/?continue=http%3A%2F%2Ftranslate.google.com%2Ftranslate_tts%3Ftl=en%26q=Your+identity+was+successfuly+confirmed.";
my $RECAPTCHA_SLEEP_SECONDS = 60;
my $SYSTEM_WEBBROWSER = "firefox";
my $MAX_OPENED_FILES = 1000;
mkdir $TMP_DIR;

my $silence_duration_paragraphs = 0.8;
my $silence_duration_sentences  = 0.2;
my $silence_duration_comma      = 0.1;
my $silence_duration_brace      = 0.1;
my $silence_duration_semicolon  = 0.2;
my $silence_duration_words      = 0.05;

my @headers = (
'Host' => 'translate.google.com',
'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.71 Safari/537.36',
'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
'Accept-Language' => 'en-us,en;q=0.5',
'Accept-Encoding' => 'gzip,deflate',
'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
'Keep-Alive' => '300',
'Connection' => 'keep-alive',
);

my $cookie_jar = HTTP::Cookies->new(hide_cookie2 => 1);

my $mech = WWW::Mechanize->new(autocheck => 0, cookie_jar => $cookie_jar);
$mech->agent_alias( 'Windows IE 6' );
$mech->add_header( "Connection" => "keep-alive" );
$mech->add_header( "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
$mech->add_header( "Accept-Language" => "en-us;q=0.5,en;q=0.3");

my $browser = LWP::UserAgent->new;

my $referer = "";

my @all_mp3s = ();
my $sentence_idx = 0;
my $tts_requests_counter = 0;
my $sample_rate = 0;
# For each input line
open(IN, $textfile_in) or die("ERROR: Can not open file '$textfile_in'");
while (my $line = <IN>)
{
	chomp($line);
	print "line: $line\n";
	# Check for empty lines - paragraphs separator
	if ($line =~ /^\s*$/) {
		if ($sample_rate != 0) {
			push @all_mp3s, SilenceToMp3($sentence_idx++, $silence_duration_paragraphs, $sample_rate);
		}
	} else {
		my @words = split(/\s+/, $line);
		my $sentence = "";
		# For each word
		for (my $i=0; $i<scalar(@words); $i++) 
		{
			my $word = $words[$i];
			$sentence .= " $word"; # add another word to the sentence
			my $say = 0;
			my $silence_duration = 0.0;
			if (length($sentence) >= $SENTENCE_MAX_CHARACTERS) {
				# Remove the last word;
				$sentence = substr($sentence, 0, length($sentence)-length($word)-1); 
				$say = 1;
				$silence_duration = $silence_duration_words;
				$i --; # one word back
			}
			# If a separator was found
			elsif (substr($word, length($word)-1, 1) =~ /[.!?]/ ) {
				$say = 1;
				$silence_duration = $silence_duration_sentences;
			}
			elsif (substr($word, length($word)-1, 1) eq ",") {
				$say = 1;
				$silence_duration = $silence_duration_comma;
			}
			elsif (substr($word, length($word)-1, 1) eq ";") {
				$say = 1;
				$silence_duration = $silence_duration_semicolon;
			}
			elsif (substr($word, length($word)-1, 1) eq ")") {
				$say = 1;
				$silence_duration = $silence_duration_brace;
			}
			# If there are no more words
			elsif ($i == scalar(@words)-1) {
				$say = 1;
				$silence_duration = $silence_duration_words;
			}

			if ($say) {
				print "sentence[$tts_requests_counter]: $sentence\n";
				my $trimmed_mp3 = TrimSilence( SentenceToMp3($sentence, $sentence_idx++) );
				my $trimmed_mp3_sample_rate = `soxi -r $trimmed_mp3`;
				chomp($trimmed_mp3_sample_rate);
				if ($sample_rate == 0) {
					$sample_rate = $trimmed_mp3_sample_rate;
				}
				if ($sample_rate != $trimmed_mp3_sample_rate) {
					die("Error: sample rate of '$trimmed_mp3' differs from the sample rate of previous files.");
				}
				#print "trimmed_mp3_sample_rate: $trimmed_mp3_sample_rate\n";
				push @all_mp3s, $trimmed_mp3;
				push @all_mp3s, SilenceToMp3($sentence_idx++, $silence_duration, $sample_rate);
				$tts_requests_counter ++;
				$sentence = ""; # start a new sentence
			}
		}
	}
}

print "Concatenate: @all_mp3s\n";
print "Writing output to $all_mp3_out...";
JoinMp3s(\@all_mp3s, $all_mp3_out);
print "done\n";
rmtree( $TMP_DIR );

sub JoinMp3s() {
	my $mp3s_ref = shift;
	my $mp3_out = shift;
	my $depth = shift || 0;

#	print "JoinMp3s(".join(" ",@{$mp3s_ref}).", $mp3_out, $depth)\n";

	#--------------------------------------------------
	# Problem if the number of mp3s exceeds the max number of opened files per process
	# The audio files should be concatenated by smaller chunks 
	#--------------------------------------------------
	if (scalar(@{$mp3s_ref}) < $MAX_OPENED_FILES) {
		Exec("sox @{$mp3s_ref} $mp3_out");
	} else {
		my @subset_mp3s_out = ();
		my @subset_mp3s = ();
		my $sub_idx = 0;
		for (my $i = 0; $i < scalar(@{$mp3s_ref}); $i++) {
			push (@subset_mp3s, $mp3s_ref->[$i]);
			if (scalar(@subset_mp3s) >= $MAX_OPENED_FILES-1 || $i == scalar(@{$mp3s_ref})-1) {
				my $sub_mp3_out = "$TMP_DIR/subjoin_".$depth."_$sub_idx.mp3"; $sub_idx++;
				JoinMp3s(\@subset_mp3s, $sub_mp3_out, $depth+1);
				push (@subset_mp3s_out, $sub_mp3_out);
				@subset_mp3s = ();
			}
		}
		JoinMp3s(\@subset_mp3s_out, $mp3_out, $depth+1);
	}
}

sub SilenceToMp3() {
	my $idx = shift;
	my $duration = shift;
	my $sample_rate = shift;

	my $mp3_out = sprintf("$TMP_DIR/%04d_sil.mp3", $sentence_idx);
	Exec("sox -n -r $sample_rate $mp3_out trim 0.0 $duration");
	return $mp3_out;
}

sub SentenceToMp3() {
	my $sentence     = shift;
	my $sentence_idx = shift;

	$sentence =~ s/ /+/g;
	if (length($sentence) > $SENTENCE_MAX_CHARACTERS) {
		die ("ERROR: sentence has more than $SENTENCE_MAX_CHARACTERS characters: '$sentence'");
	}
	
	my $mp3_out = sprintf("$TMP_DIR/%04d.mp3", $sentence_idx);

	my $resp = GetSentenceResponse_CaptchaAware($sentence); # NOT WORKING YET

	if (length($resp) == 0) {
		print "EMPTY SENTENCE: '$sentence'\n";
		return "";
	}
	open(FILE,">$mp3_out");
	print FILE $resp;
	close(FILE);
	return $mp3_out;
}

sub GetSentenceResponse() {
	my $sentence = shift;
	my $amptk = int(rand(1000000)) . '|' . int(rand(1000000));
	my $resp = $browser->get("https://translate.google.com/translate_tts?ie=UTF-8&tl=$language&q=$sentence&total=1&idx=0&client=tw-ob&tk=$amptk");

	if ($resp->content =~ "^<!DOCTYPE" ||
		$resp->content =~ "^<html>") 
	{
		die("ERROR: expecting MP3 data, but got a HTML page!");
	}
	return $resp->content;
}

sub GetSentenceResponse_CaptchaAware() {
	my $sentence = shift;

	my $recaptcha_waiting = 0;
	print "URL: https://translate.google.com/translate_tts?ie=UTF-8&tl=$language&q=$sentence&total=1&idx=0&client=tw-ob\n";
	while (1) {
		my $amptk = int(rand(1000000)) . '|' . int(rand(1000000));
		my $url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=$language&q=$sentence&total=1&idx=0&client=tw-ob&tk=$amptk";
		$mech->get($url); $mech->add_header( Referer => "$referer" ); $referer = $url;
		if ($mech->response()->content() =~ /^<!DOCTYPE/ || 
			$mech->response()->content() =~ /^<html>/) 
		{
			my $tree = HTML::TreeBuilder->new();
			$tree->parse_content($mech->response()->content());
			print "HTML response: ".$tree->as_text()."\n";

			if (!$recaptcha_waiting) {
				$recaptcha_waiting = 1; 
				print "We have to wait\n";
			}
			print ".";
			sleep($RECAPTCHA_SLEEP_SECONDS);
			next;

			my $captcha_img_url = "http://translate.google.com".$tree->look_down("_tag", "img")->attr("src");
			print "img: ".$captcha_img_url;
			my $mech2 = $mech->clone();
			$referer = "http://www.google.com/sorry/?continue=$url";
			$mech2->add_header( Referer => "$referer" );
			$mech2->get($captcha_img_url, ':content_file' => 'captcha.jpg'); 
			
#			print "\n\n".$mech->response()->content()."\n\n";
	
			print "enter captcha here: ";
			my $val = <STDIN>;
			print "val: $val\n";

			# TODO: THIS DOES NOT WORK! MAYBE WAITING FOR HALF AN HOUR WOULD BE BETTER
			$mech->add_header( Referer => "$referer" );
			my $res = $mech->submit_form(with_fields => {captcha => "$val"});
			print "response: ".$res->content."\n";
		} else {
#			print "MP3 response\n";
			last;
		}
		sleep($RECAPTCHA_SLEEP_SECONDS);
		PrintWaitingDot();
	}
	if ($recaptcha_waiting) { print "\n"; }
	return $mech->response()->content();
}

sub PrintWaitingDot() {
	select STDOUT;
	print ".";
	$|=1;
}

sub TrimSilence() {
	my $mp3 = shift;

	if ($mp3 eq "") {
		return "";
	}

	my $mp3_out = $mp3;
	$mp3_out =~ s/\.mp3$/_trim.mp3/;
	Exec("
	sox $mp3 -p silence 1 0.1 -60d \\
	| sox -p -p reverse \\
	| sox -p -p silence 1 0.1 -60d \\
	| sox -p $mp3_out reverse
	");
	return $mp3_out;
}

sub Exec() {
	my $cmd = shift;
#	print "exec $cmd\n";
	system $cmd;
	return;
}
