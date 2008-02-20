#!/usr/bin/perl -w

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime::Duration;
use Data::Dumper;

use Test::More tests => 3;

eval { use Test::LongString max => 100; $Test::LongString::Context = 50; };
*{'main::is_string'} = \&main::is if $@;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our $R1;
sub mysend
{
	my ($transport, $count, $msg) = @_;
	$R1 = $msg->as_string();
	return 1;
}

our $R2;
sub myrecv
{
	return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 : $E1 .
		'<response>' . r() . $TRID . '</response>' . $E2);
}

my $dri;
eval {
	$dri = Net::DRI->new(10);
};
print $@->as_string() if $@;
$dri->{trid_factory} = sub { return 'ABC-12345'; };
$dri->add_registry('BIZ');
eval {
	$dri->target('BIZ')->new_current_profile('p1',
		'Net::DRI::Transport::Dummy',
		[{
			f_send=> \&mysend,
			f_recv=> \&myrecv
		}], 'Net::DRI::Protocol::EPP', ['1.0',['Net::DRI::Protocol::EPP::Extensions::NeuLevel::Restore']]);
};
print $@->as_string() if $@;


my $rc;
my $s;
my $d;
my ($dh,@c);

####################################################################################################
## Restore a deleted domain
$R2 = $E1 . '<response>' . r(1001,'Command completed successfully; ' .
	'action pending') . $TRID . '</response>' . $E2;

eval {
	$rc = $dri->domain_renew('deleted-by-accident.biz', {
		current_expiration => new DateTime(year => 2008, month => 12,
			day => 24),
		rgp => { code => 1, comment => 'Deleted by mistake'}});
};
print(STDERR $@->as_string()) if ($@);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully recovered');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>deleted-by-accident.biz</domain:name><domain:curExpDate>2008-12-24</domain:curExpDate></domain:renew></renew><extension><neulevel:extension xmlns:neulevel="urn:ietf:params:xml:ns:neulevel-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:neulevel-1.0 neulevel-1.0.xsd"><neulevel:unspec>RestoreReasonCode=1 RestoreComment=DeletedByMistake TrueData=Y ValidUse=Y</neulevel:unspec></neulevel:extension></extension><clTRID>ABC-12345</clTRID></command></epp>', 'Recover Domain XML correct');

####################################################################################################
exit(0);

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
