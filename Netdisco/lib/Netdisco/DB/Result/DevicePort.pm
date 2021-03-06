use utf8;
package Netdisco::DB::Result::DevicePort;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("device_port");
__PACKAGE__->add_columns(
  "ip",
  { data_type => "inet", is_nullable => 0 },
  "port",
  { data_type => "text", is_nullable => 0 },
  "creation",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "descr",
  { data_type => "text", is_nullable => 1 },
  "up",
  { data_type => "text", is_nullable => 1 },
  "up_admin",
  { data_type => "text", is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 1 },
  "duplex",
  { data_type => "text", is_nullable => 1 },
  "duplex_admin",
  { data_type => "text", is_nullable => 1 },
  "speed",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "mac",
  { data_type => "macaddr", is_nullable => 1 },
  "mtu",
  { data_type => "integer", is_nullable => 1 },
  "stp",
  { data_type => "text", is_nullable => 1 },
  "remote_ip",
  { data_type => "inet", is_nullable => 1 },
  "remote_port",
  { data_type => "text", is_nullable => 1 },
  "remote_type",
  { data_type => "text", is_nullable => 1 },
  "remote_id",
  { data_type => "text", is_nullable => 1 },
  "vlan",
  { data_type => "text", is_nullable => 1 },
  "pvid",
  { data_type => "integer", is_nullable => 1 },
  "lastchange",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("port", "ip");


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-01-07 14:20:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lcbweb0loNwHoWUuxTN/hA

=head1 RELATIONSHIPS

=head2 device

Returns the Device table entry to which the given Port is related.

=cut

__PACKAGE__->belongs_to( device => 'Netdisco::DB::Result::Device', 'ip');

=head2 nodes / active_nodes / nodes_with_age / active_nodes_with_age

Returns the set of Nodes whose MAC addresses are associated with this Device
Port.

The C<active> variants return only the subset of nodes currently in the switch
MAC address table, that is the active ones.

The C<with_age> variants add an additional column C<time_last_age>, a
preformatted value for the Node's C<time_last> field, which reads as "X
days/weeks/months/years".

=cut

__PACKAGE__->has_many( nodes => 'Netdisco::DB::Result::Node',
  {
    'foreign.switch' => 'self.ip',
    'foreign.port' => 'self.port',
  },
  { join_type => 'LEFT' },
);

__PACKAGE__->has_many( nodes_with_age => 'Netdisco::DB::Result::NodeWithAge',
  {
    'foreign.switch' => 'self.ip',
    'foreign.port' => 'self.port',
  },
  { join_type => 'LEFT' },
);

__PACKAGE__->has_many( active_nodes => 'Netdisco::DB::Result::ActiveNode',
  {
    'foreign.switch' => 'self.ip',
    'foreign.port' => 'self.port',
  },
  { join_type => 'LEFT' },
);

__PACKAGE__->has_many( active_nodes_with_age => 'Netdisco::DB::Result::ActiveNodeWithAge',
  {
    'foreign.switch' => 'self.ip',
    'foreign.port' => 'self.port',
  },
  { join_type => 'LEFT' },
);

=head2 neighbor_alias

When a device port has an attached neighbor device, this relationship will
return the IP address of the neighbor. See the C<neighbor> helper method if
what you really want is to retrieve the Device entry for that neighbor.

The JOIN is of type "LEFT" in case the neighbor device is known but has not
been fully discovered by Netdisco and so does not exist itself in the
database.

=cut

__PACKAGE__->belongs_to( neighbor_alias => 'Netdisco::DB::Result::DeviceIp',
  { 'foreign.alias' => 'self.remote_ip' },
  { join_type => 'LEFT' },
);

=head2 port_vlans_tagged

Returns a set of rows from the C<device_port_vlan> table relating to this
port, where the VLANs are all tagged.

=cut

__PACKAGE__->has_many( port_vlans_tagged => 'Netdisco::DB::Result::DevicePortVlanTagged',
  {
    'foreign.ip' => 'self.ip',
    'foreign.port' => 'self.port',
  },
  { join_type => 'LEFT' },
);

=head2 tagged_vlans

As compared to C<port_vlans_tagged>, this relationship returns a set of VLAN
row objects for the VLANs on the given port, which might be more useful if you
want to find out details such as the VLAN name.

See also C<tagged_vlans_count>.

=cut

__PACKAGE__->many_to_many( tagged_vlans => 'port_vlans_tagged', 'vlan' );


=head2 oui

Returns the C<oui> table entry matching this Port. You can then join on this
relation and retrieve the Company name from the related table.

The JOIN is of type LEFT, in case the OUI table has not been populated.

=cut

__PACKAGE__->belongs_to( oui => 'Netdisco::DB::Result::Oui',
  sub {
      my $args = shift;
      return {
          "$args->{foreign_alias}.oui" =>
            { '=' => \"substring(cast($args->{self_alias}.mac as varchar) for 8)" }
      };
  },
  { join_type => 'LEFT' }
);

=head1 ADDITIONAL METHODS

=head2

Returns the Device entry for the neighbour Device on the given port.

Might return an undefined value if there is no neighbor on the port, or if the
neighbor has not been fully discovered by Netdisco and so does not exist in
the database.

=cut

sub neighbor {
    my $row = shift;
    return eval { $row->neighbor_alias->device || undef };
}

=head1 ADDITIONAL COLUMNS

=head2 tagged_vlans_count

Returns the number of tagged VLANs active on this device port. Enable this
column by applying the C<with_vlan_count()> modifier to C<search()>.

=cut

sub tagged_vlans_count { return (shift)->get_column('tagged_vlans_count') }

=head2 lastchange_stamp

Formatted version of the C<lastchange> field, accurate to the minute. Enable
this column by applying the C<with_vlan_count()> modifier to C<search()>.

The format is somewhat like ISO 8601 or RFC3339 but without the middle C<T>
between the date stamp and time stamp. That is:

 2012-02-06 12:49

=cut

sub lastchange_stamp { return (shift)->get_column('lastchange_stamp') }

=head2 is_free

This method can be used to evaluate whether a device port could be considered
unused, based on the last time it changed from the "up" state to a "down"
state.

See the C<with_is_free> and C<only_free_ports> modifiers to C<search()>.

=cut

sub is_free { return (shift)->get_column('is_free') }

1;
