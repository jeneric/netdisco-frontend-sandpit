use utf8;
package Netdisco::DB::Result::Node;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("node");
__PACKAGE__->add_columns(
  "mac",
  { data_type => "macaddr", is_nullable => 0 },
  "switch",
  { data_type => "inet", is_nullable => 0 },
  "port",
  { data_type => "text", is_nullable => 0 },
  "active",
  { data_type => "boolean", is_nullable => 1 },
  "oui",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "time_first",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "time_recent",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "time_last",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("mac", "switch", "port");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-01-07 14:20:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sGGyKEfUkoIFVtmj1wnH7A

=head1 RELATIONSHIPS

=head2 device

Returns the single C<device> to which this Node entry was associated at the
time of discovery.

The JOIN is of type LEFT, in case the C<device> is no longer present in the
database but the relation is being used in C<search()>.

=cut

__PACKAGE__->belongs_to( device => 'Netdisco::DB::Result::Device',
  { 'foreign.ip' => 'self.switch' }, { join_type => 'LEFT' } );

=head2 device_port

Returns the single C<device_port> to which this Node entry was associated at
the time of discovery.

The JOIN is of type LEFT, in case the C<device> is no longer present in the
database but the relation is being used in C<search()>.

=cut

# device port may have been deleted (reconfigured modules?) but node remains
__PACKAGE__->belongs_to( device_port => 'Netdisco::DB::Result::DevicePort',
  { 'foreign.ip' => 'self.switch', 'foreign.port' => 'self.port' },
  { join_type => 'LEFT' }
);

=head2 ips

Returns the set of C<node_ip> entries associated with this Node. That is, the
IP addresses which this MAC address was hosting at the time of discovery.

Note that the Active status of the returned IP entries will all be the same as
the current Node's.

=cut

__PACKAGE__->has_many( ips => 'Netdisco::DB::Result::NodeIp',
  { 'foreign.mac' => 'self.mac', 'foreign.active' => 'self.active' } );

=head2 oui

Returns the C<oui> table entry matching this Node. You can then join on this
relation and retrieve the Company name from the related table.

The JOIN is of type LEFT, in case the OUI table has not been populated.

=cut

__PACKAGE__->belongs_to( oui => 'Netdisco::DB::Result::Oui', 'oui',
  { join_type => 'LEFT' } );

=head1 ADDITIONAL COLUMNS

=head2 time_first_stamp

Formatted version of the C<time_first> field, accurate to the minute.

The format is somewhat like ISO 8601 or RFC3339 but without the middle C<T>
between the date stamp and time stamp. That is:

 2012-02-06 12:49

=cut

sub time_first_stamp { return (shift)->get_column('time_first_stamp') }

=head2 time_last_stamp

Formatted version of the C<time_last> field, accurate to the minute.

The format is somewhat like ISO 8601 or RFC3339 but without the middle C<T>
between the date stamp and time stamp. That is:

 2012-02-06 12:49

=cut

sub time_last_stamp  { return (shift)->get_column('time_last_stamp')  }

1;
