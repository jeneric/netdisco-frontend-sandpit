use utf8;
package Netdisco::DB::Result::DevicePortSsid;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("device_port_ssid");
__PACKAGE__->add_columns(
  "ip",
  { data_type => "inet", is_nullable => 1 },
  "port",
  { data_type => "text", is_nullable => 1 },
  "ssid",
  { data_type => "text", is_nullable => 1 },
  "broadcast",
  { data_type => "boolean", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-01-07 14:20:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zvgylKzUQtizJZCe1rEdUg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
