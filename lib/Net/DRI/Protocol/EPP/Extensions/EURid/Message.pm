## Domain Registry Interface, EPP Message for EURid
##
## Copyright (c) 2005,2006,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
#########################################################################################

package Net::DRI::Protocol::EPP::Extensions::EURid::Message;

use strict;

use base qw/Net::DRI::Protocol::EPP::Message/;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Message - EPP EURid Message for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2006,2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub parse
{
 my $self=shift;
 $self->SUPER::parse(@_);

 ## Parse eurid:ext
 my $result=$self->get_content('result',$self->ns('eurid'),1);
 return unless $result;

 ## We add it to the latest status extra_info seen.
 my $ra=$self->{results}->[-1]->{extra_info};
 foreach my $el ($result->getElementsByTagNameNS($self->ns('eurid'),'msg'))
 {
  push @{$ra},$el->getFirstChild()->getData();
 }
}

####################################################################################################
1;