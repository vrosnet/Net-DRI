#!/usr/bin/perl -w

use Test::More tests => 191;

BEGIN { 
use_ok('Net::DRI');
use_ok('Net::DRI::Transport');
use_ok('Net::DRI::Exception');
use_ok('Net::DRI::Cache');
use_ok('Net::DRI::Protocol');
use_ok('Net::DRI::Util');
use_ok('Net::DRI::Registry');
use_ok('Net::DRI::DRD');
use_ok('Net::DRI::DRD::ICANN');
use_ok('Net::DRI::DRD::VNDS');
use_ok('Net::DRI::DRD::AFNIC');
use_ok('Net::DRI::DRD::Gandi');
use_ok('Net::DRI::DRD::WS');
use_ok('Net::DRI::DRD::EURid');
use_ok('Net::DRI::DRD::SE');
use_ok('Net::DRI::DRD::PL');
use_ok('Net::DRI::DRD::IENUMAT');
use_ok('Net::DRI::DRD::CAT');
use_ok('Net::DRI::DRD::CH');
use_ok('Net::DRI::DRD::AERO');
use_ok('Net::DRI::DRD::MOBI');
use_ok('Net::DRI::DRD::BE');
use_ok('Net::DRI::DRD::AT');
use_ok('Net::DRI::DRD::COOP');
use_ok('Net::DRI::DRD::INFO');
use_ok('Net::DRI::DRD::ORG');
use_ok('Net::DRI::DRD::LU');
use_ok('Net::DRI::DRD::BIZ');
use_ok('Net::DRI::DRD::ASIA');
use_ok('Net::DRI::DRD::NAME');
use_ok('Net::DRI::DRD::NU');
use_ok('Net::DRI::DRD::AU');
use_ok('Net::DRI::DRD::US');
use_ok('Net::DRI::DRD::OVH');
use_ok('Net::DRI::DRD::BookMyName');
use_ok('Net::DRI::DRD::Nominet');
use_ok('Net::DRI::Data::Raw');
use_ok('Net::DRI::Data::Hosts');
use_ok('Net::DRI::Data::Changes');
use_ok('Net::DRI::Data::StatusList');
use_ok('Net::DRI::Data::RegistryObject');
use_ok('Net::DRI::Data::Contact');
use_ok('Net::DRI::Data::ContactSet');
use_ok('Net::DRI::Data::Contact::EURid');
use_ok('Net::DRI::Data::Contact::SE');
use_ok('Net::DRI::Data::Contact::PL');
use_ok('Net::DRI::Data::Contact::AFNIC');
use_ok('Net::DRI::Data::Contact::US');
use_ok('Net::DRI::Data::Contact::CAT');
use_ok('Net::DRI::Data::Contact::AERO');
use_ok('Net::DRI::Data::Contact::BE');
use_ok('Net::DRI::Data::Contact::AT');
use_ok('Net::DRI::Data::Contact::CH');
use_ok('Net::DRI::Data::Contact::COOP');
use_ok('Net::DRI::Data::Contact::LU');
use_ok('Net::DRI::Data::Contact::ASIA');
use_ok('Net::DRI::Data::Contact::Nominet');
use_ok('Net::DRI::Transport::Socket');
use_ok('Net::DRI::Transport::Dummy');
use_ok('Net::DRI::Protocol::ResultStatus');
use_ok('Net::DRI::Protocol::Message');
use_ok('Net::DRI::Protocol::RRP::Message');
use_ok('Net::DRI::Protocol::RRP::Core::Domain');
use_ok('Net::DRI::Protocol::RRP::Core::Host');
use_ok('Net::DRI::Protocol::RRP::Core::Status');
use_ok('Net::DRI::Protocol::RRP::Core::Session');
use_ok('Net::DRI::Protocol::RRP::Connection');
use_ok('Net::DRI::Protocol::RRP');
use_ok('Net::DRI::Protocol::AFNIC::WS::Domain');
use_ok('Net::DRI::Protocol::AFNIC::WS::Message');
use_ok('Net::DRI::Protocol::AFNIC::WS');
use_ok('Net::DRI::Protocol::AFNIC::Email::Domain');
use_ok('Net::DRI::Protocol::AFNIC::Email::Message');
use_ok('Net::DRI::Protocol::AFNIC::Email');
use_ok('Net::DRI::Protocol::EPP');
use_ok('Net::DRI::Protocol::EPP::Message');
use_ok('Net::DRI::Protocol::EPP::Connection');
use_ok('Net::DRI::Protocol::EPP::Core::Status');
use_ok('Net::DRI::Protocol::EPP::Core::Contact');
use_ok('Net::DRI::Protocol::EPP::Core::Domain');
use_ok('Net::DRI::Protocol::EPP::Core::Host');
use_ok('Net::DRI::Protocol::EPP::Core::Session');
use_ok('Net::DRI::Protocol::EPP::Core::RegistryMessage');
use_ok('Net::DRI::Protocol::EPP::Extensions::GracePeriod');
use_ok('Net::DRI::Protocol::EPP::Extensions::E164');
use_ok('Net::DRI::Protocol::EPP::Extensions::SecDNS');
use_ok('Net::DRI::Protocol::EPP::Extensions::NSgroup');
use_ok('Net::DRI::Protocol::EPP::Extensions::EURid');
use_ok('Net::DRI::Protocol::EPP::Extensions::EURid::Sunrise');
use_ok('Net::DRI::Protocol::EPP::Extensions::EURid::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::EURid::Contact');
use_ok('Net::DRI::Protocol::EPP::Extensions::EURid::Message');
use_ok('Net::DRI::Protocol::EPP::Extensions::SE');
use_ok('Net::DRI::Protocol::EPP::Extensions::SE::Extensions');
use_ok('Net::DRI::Protocol::EPP::Extensions::PL');
use_ok('Net::DRI::Protocol::EPP::Extensions::PL::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::PL::Contact');
use_ok('Net::DRI::Protocol::EPP::Extensions::US');
use_ok('Net::DRI::Protocol::EPP::Extensions::US::Contact');
use_ok('Net::DRI::Protocol::EPP::Extensions::VeriSign');
use_ok('Net::DRI::Protocol::EPP::Extensions::VeriSign::Sync');
use_ok('Net::DRI::Protocol::EPP::Extensions::VeriSign::IDNLanguage');
use_ok('Net::DRI::Protocol::EPP::Extensions::VeriSign::WhoisInfo');
use_ok('Net::DRI::Protocol::EPP::Extensions::VeriSign::NameStore');
use_ok('Net::DRI::Protocol::EPP::Extensions::VeriSign::PollLowBalance');
use_ok('Net::DRI::Protocol::EPP::Extensions::VeriSign::PollRGP');
use_ok('Net::DRI::Protocol::EPP::Extensions::AT::Result');
use_ok('Net::DRI::Protocol::EPP::Extensions::AT::IOptions');
use_ok('Net::DRI::Protocol::EPP::Extensions::AT::Message');
use_ok('Net::DRI::Protocol::EPP::Extensions::IENUMAT');
use_ok('Net::DRI::Protocol::EPP::Extensions::CAT');
use_ok('Net::DRI::Protocol::EPP::Extensions::CAT::Contact');
use_ok('Net::DRI::Protocol::EPP::Extensions::CAT::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::CAT::DefensiveRegistration');
use_ok('Net::DRI::Protocol::EPP::Extensions::AERO');
use_ok('Net::DRI::Protocol::EPP::Extensions::AERO::Contact');
use_ok('Net::DRI::Protocol::EPP::Extensions::AERO::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::MOBI');
use_ok('Net::DRI::Protocol::EPP::Extensions::MOBI::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::DNSBE');
use_ok('Net::DRI::Protocol::EPP::Extensions::DNSBE::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::DNSBE::Contact');
use_ok('Net::DRI::Protocol::EPP::Extensions::DNSBE::Message');
use_ok('Net::DRI::Protocol::EPP::Extensions::AT');
use_ok('Net::DRI::Protocol::EPP::Extensions::AT::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::AT::Contact');
use_ok('Net::DRI::Protocol::EPP::Extensions::AT::ATResult');
use_ok('Net::DRI::Protocol::EPP::Extensions::COOP');
use_ok('Net::DRI::Protocol::EPP::Extensions::COOP::Contact');
use_ok('Net::DRI::Protocol::EPP::Extensions::LU');
use_ok('Net::DRI::Protocol::EPP::Extensions::LU::Contact');
use_ok('Net::DRI::Protocol::EPP::Extensions::LU::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::LU::Poll');
use_ok('Net::DRI::Protocol::EPP::Extensions::LU::Status');
use_ok('Net::DRI::Protocol::EPP::Extensions::CentralNic');
use_ok('Net::DRI::Protocol::EPP::Extensions::CentralNic::TTL');
use_ok('Net::DRI::Protocol::EPP::Extensions::CentralNic::WebForwarding');
use_ok('Net::DRI::Protocol::EPP::Extensions::CentralNic::Release');
use_ok('Net::DRI::Protocol::EPP::Extensions::ASIA');
use_ok('Net::DRI::Protocol::EPP::Extensions::ASIA::CED');
use_ok('Net::DRI::Protocol::EPP::Extensions::ASIA::IPR');
use_ok('Net::DRI::Protocol::EPP::Extensions::AU');
use_ok('Net::DRI::Protocol::EPP::Extensions::AU::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::CH');
use_ok('Net::DRI::Protocol::EPP::Extensions::E164Validation');
use_ok('Net::DRI::Protocol::EPP::Extensions::E164Validation::RFC5076');
use_ok('Net::DRI::Protocol::EPP::Extensions::Afilias');
use_ok('Net::DRI::Protocol::EPP::Extensions::Afilias::IDNLanguage');
use_ok('Net::DRI::Protocol::EPP::Extensions::Afilias::Restore');
use_ok('Net::DRI::Protocol::EPP::Extensions::NAME');
use_ok('Net::DRI::Protocol::EPP::Extensions::NAME::EmailFwd');
use_ok('Net::DRI::Protocol::EPP::Extensions::Nominet');
use_ok('Net::DRI::Protocol::EPP::Extensions::Nominet::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::Nominet::Contact');
use_ok('Net::DRI::Protocol::EPP::Extensions::Nominet::Host');
use_ok('Net::DRI::Protocol::EPP::Extensions::Nominet::Account');
use_ok('Net::DRI::Protocol::DAS');
use_ok('Net::DRI::Protocol::DAS::Message');
use_ok('Net::DRI::Protocol::DAS::Connection');
use_ok('Net::DRI::Protocol::DAS::Domain');
use_ok('Net::DRI::Protocol::Whois');
use_ok('Net::DRI::Protocol::Whois::Message');
use_ok('Net::DRI::Protocol::Whois::Connection');
use_ok('Net::DRI::Protocol::Whois::Domain');
use_ok('Net::DRI::Protocol::Whois::Domain::common');
use_ok('Net::DRI::Protocol::Whois::Domain::COM');
use_ok('Net::DRI::Protocol::Whois::Domain::ORG');
use_ok('Net::DRI::Protocol::Whois::Domain::AERO');
use_ok('Net::DRI::Protocol::Whois::Domain::INFO');
use_ok('Net::DRI::Protocol::Whois::Domain::EU');
use_ok('Net::DRI::Protocol::Whois::Domain::BIZ');
use_ok('Net::DRI::Protocol::Whois::Domain::MOBI');
use_ok('Net::DRI::Protocol::Whois::Domain::NAME');
use_ok('Net::DRI::Protocol::Whois::Domain::LU');
use_ok('Net::DRI::Protocol::Whois::Domain::WS');
use_ok('Net::DRI::Protocol::Whois::Domain::SE');
use_ok('Net::DRI::Protocol::Whois::Domain::CAT');
use_ok('Net::DRI::Protocol::Whois::Domain::AT');
use_ok('Net::DRI::Protocol::OVH::WS');
use_ok('Net::DRI::Protocol::OVH::WS::Connection');
use_ok('Net::DRI::Protocol::OVH::WS::Message');
use_ok('Net::DRI::Protocol::OVH::WS::Account');
use_ok('Net::DRI::Protocol::OVH::WS::Domain');
use_ok('Net::DRI::Protocol::BookMyName::WS');
use_ok('Net::DRI::Protocol::BookMyName::WS::Message');
use_ok('Net::DRI::Protocol::BookMyName::WS::Account');
use_ok('Net::DRI::Protocol::BookMyName::WS::Domain');
use_ok('Net::DRI::Protocol::Gandi::WS');
##use_ok('Net::DRI::Protocol::Gandi::WS::Connection'); ## test in 004 because of extra dependency
use_ok('Net::DRI::Protocol::Gandi::WS::Message');
use_ok('Net::DRI::Protocol::Gandi::WS::Account');
use_ok('Net::DRI::Protocol::Gandi::WS::Domain');
}

exit 0;
