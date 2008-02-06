#!/usr/bin/perl -w

use Net::DRI;
use Net::DRI::Data::Raw;
use Net::DRI::DRD::ICANN;

use Test::More tests => 26;

eval { use Test::LongString max => 100; $Test::LongString::Context=50; };
*{'main::is_string'} = \&main::is if $@;

our $E1 = '<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2 = '</epp>';
our $TRID = '<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

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
 return Net::DRI::Data::Raw->new_from_string($R2 ? $R2 : $E1 . '<response>' .
	r() . $TRID . '</response>' . $E2);
}

my $dri = Net::DRI->new(10);
$dri->{trid_factory} = sub { return 'ABC-12345'; };
eval {
	$dri->add_registry('AT');
	$dri->target('AT')->new_current_profile('p1',
		'Net::DRI::Transport::Dummy',
		[{f_send => \&mysend, f_recv => \&myrecv}],
			'Net::DRI::Protocol::EPP::Extensions::AT', []);
};
if ($@)
{
	if (ref($@) eq 'Net::DRI::Exception')
	{
		die($@->as_string());
	}
	else
	{
		die($@);
	}
}

my $rc;
my $s;
my $d;
my ($dh, @c);

####################################################################################################
## Registry Messages


$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="2265" id="374185914"><qDate>2008-02-04T09:23:04.63Z</qDate><msg>EPP response to a transaction executed on your behalf: objecttype [domain] command [transfer-execute] objectname [mydomain.at]</msg></msgQ><resData><message xmlns="http://www.nic.at/xsd/at-ext-message-1.0" type="response-copy" xsi:schemaLocation="http://www.nic.at/xsd/at-ext-message-1.0 at-ext-message-1.0.xsd"><desc>EPP response to a transaction executed on your behalf: objecttype [domain] command [transfer-execute] objectname [mydomain.at]</desc><data><entry name="objecttype">domain</entry><entry name="command">transfer-execute</entry><entry name="objectname">mydomain.at</entry><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><response><result code="2304"><msg>Object status prohibits operation</msg></result><msgQ count="734" id="374047143"/><extension><conditions xmlns="http://www.nic.at/xsd/at-ext-result-1.0" xsi:schemaLocation="http://www.nic.at/xsd/at-ext-result-1.0 at-ext-result-1.0.xsd"><condition code="NC20077" severity="error"><msg>Registry::NICAT::Exception::Policy::Domain::Locked</msg><details>Domain mydomain.at: domain is locked.</details></condition></conditions></extension><trID><clTRID>NICAT-1234-4341234246535343</clTRID><svTRID>2008020412454356454273-9-nicat</svTRID></trID></response></epp></data></message></resData>' . $TRID . '</response>' . $E2;

eval {
	$rc = $dri->message_retrieve();
};
if ($@)
{
	if (ref($@) eq 'Net::DRI::Exception')
	{
		die($@->as_string());
	}
	else
	{
		die($@);
	}
}
is($rc->is_success(), 1, 'message polled successfully');

unless ($rc->is_success())
{
	die('Error ' . $rc->code() . ': ' . $rc->message());
}

is($dri->get_info('last_id'), 374185914, 'message get_info last_id 1');
is($dri->get_info('last_id', 'message', 'session'), 374185914,
	'message get_info last_id 2');
is($dri->get_info('id', 'message', 374185914), 374185914,
	'message get_info id');
is('' . $dri->get_info('qdate', 'message', 374185914), '2008-02-04T09:23:04',
	'message get_info qdate');
is($dri->get_info('lang', 'message', 374185914), 'en', 'message get_info lang');
is($dri->get_info('roid', 'message', 374185914), undef,
	'message get_info roid');
is($dri->get_info('content', 'message', 374185914), 'EPP response to a ' .
	'transaction executed on your behalf: objecttype [domain] ' .
	'command [transfer-execute] objectname [mydomain.at]',
	'message get_info content');
is($dri->get_info('action', 'message', 374185914), 'transfer-execute',
	'message get_info action');
is($dri->get_info('object_type', 'message', 374185914), 'domain',
	'message get_info object_type');
is($dri->get_info('object_id', 'message', 374185914), 'mydomain.at',
	'message get_info object_id');

my $conds = $dri->get_info('conditions', 'message', 374185914);
is($conds->[0]->{msg}, 'Registry::NICAT::Exception::Policy::Domain::Locked',
	'message condition message');
is($conds->[0]->{code}, 'NC20077', 'message condition code');
is($conds->[0]->{severity}, 'error', 'message condition severity');
is($conds->[0]->{details}, 'Domain mydomain.at: domain is locked.',
	'message condition details');

$R2 = $E1 . '<response><result code="1301"><msg>Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="375338309"><qDate>2008-02-06T10:18:19.70Z</qDate><msg>Reg losing: blafasel.at</msg></msgQ><resData><message xmlns="http://www.nic.at/xsd/at-ext-message-1.0" type="domain-transferred-away" xsi:schemaLocation="http://www.nic.at/xsd/at-ext-message-1.0 at-ext-message-1.0.xsd"><desc>Reg losing: blafasel.at</desc><data><entry name="domain">blafasel.at</entry></data></message></resData>' . $TRID . '</response>' . $E2;

eval {
	$rc = $dri->message_retrieve();
};
if ($@)
{
	if (ref($@) eq 'Net::DRI::Exception')
	{
		die($@->as_string());
	}
	else
	{
		die($@);
	}
}
is($rc->is_success(), 1, 'message polled successfully');

unless ($rc->is_success())
{
	die('Error ' . $rc->code() . ': ' . $rc->message());
}

is($dri->get_info('last_id'), 375338309, 'message get_info last_id 1');
is($dri->get_info('object_type', 'message', 375338309), 'domain',
	'message get_info object_type');
is($dri->get_info('object_id', 'message', 375338309), 'blafasel.at',
	'message get_info object_id');

eval {
	$dri->add_registry('LU');
	$dri->target('LU')->new_current_profile('p2',
		'Net::DRI::Transport::Dummy',
		[{f_send => \&mysend, f_recv => \&myrecv}],
			'Net::DRI::Protocol::EPP::Extensions::LU', []);
};
if ($@)
{
	if (ref($@) eq 'Net::DRI::Exception')
	{
		die($@->as_string());
	}
	else
	{
		die($@);
	}
}

$R2 = $E1 . '<response><result code="1301"><msg>[1301] Command completed successfully; ack to dequeue</msg></result><msgQ count="1" id="104574"><qDate>2008-01-24T12:41:03.000Z</qDate><msg><dnslu:pollmsg type="13" xmlns:dnslu="http://www.dns.lu/xml/epp/dnslu-1.0" xsi:schemaLocation="http://www.dns.lu/xml/epp/dnslu-1.0 dnslu-1.0.xsd"><dnslu:roid>D41231-DNSLU</dnslu:roid><dnslu:object>blafasel.lu</dnslu:object><dnslu:clTRID>DNSLU-4123-1342324575404832</dnslu:clTRID><dnslu:svTRID>CAFEBABE:002A-DNSLU</dnslu:svTRID><dnslu:exDate>2009-01-24T12:41:03.000Z</dnslu:exDate><dnslu:ns name="any">Nameserver test succeeded</dnslu:ns></dnslu:pollmsg></msg></msgQ>' . $TRID . '</response>' . $E2;

eval {
	$rc = $dri->message_retrieve();
};
is($rc->is_success(), 1, 'message polled successfully');

unless ($rc->is_success())
{
	die('Error ' . $rc->code() . ': ' . $rc->message());
}

is($dri->get_info('last_id'), 104574, 'message get_info last_id');
is($dri->get_info('type', 'message', 104574), 13, 'message get_info type');
is($dri->get_info('roid', 'message', 104574), 'D41231-DNSLU',
	'message get_info roid');

is(Net::DRI::DRD::ICANN::is_reserved_name('test.com.cn', 'info'), 0,
	'.com.cn registrability');
is(Net::DRI::DRD::ICANN::is_reserved_name('xn--vcsq68l.com.cn', 'info'), 0,
	'.com.cn IDN registrability');
is(Net::DRI::DRD::ICANN::is_reserved_name('test.com.tw', 'info'), 0,
	'.com.tw registrability');

exit 0;

sub r
{
 my ($c, $m) = @_;
 return '<result code="' . ($c || 1000) . '"><msg>' .
	($m || 'Command completed successfully') . '</msg></result>';
}
