#!/usr/bin/perl
#
# Name:
#	hash2table.pl.
#
# Purpose:
#	Test DBIx::Hash2Table.
#
# Note:
#	Lines 71 .. 72 allow you to control the output.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html

use strict;
use warnings;

use DBI;
use DBIx::Hash2Table;
use Error qw/ :try /;

# -----------------------------------------------

sub save
{
	my($dbh)		= @_;
	my($table_name)	= 'hobbit';
	my($sql)		= "drop table $table_name";

	eval{$dbh -> do($sql) };

	$sql = "create table $table_name (id int, parent_id int, name varchar(255), code varchar(255) )";

	$dbh -> do($sql);

	print "SQL: $sql. \n";

	my(%hobbit) =
	(
		'Great grand gnome'	=>
		{
			code			=> 'G-g-g', # Code of 'Great grand gnome'.
			'Great gnome'	=>
			{
				code					=> 'G-g-one',
				'Eldest great gnome'	=> {code => 'E-g-g-one'},
				'Youngest great gnome'	=> {code => 'Y-g-g'},
			},
			'Grand gnome' =>
			{
				code					=> 'G-g-two',
				'Smartest grand gnome'	=> {code => undef},
				'Prettiest grand gnome'	=> {code => ''},
				'Long lost grand gnome'	=> {code => 'L-l-g-g'},
			},
		},
		'Evil gnome' =>
		{
			code				=> undef,
			'Evil gray gnome'	=> {code => ''},
			'Evil grey gnome'	=> {code => 'E-g-g-two'},
		},
	);

	DBIx::Hash2Table -> new
	(
		hash_ref   => \%hobbit,
		dbh        => $dbh,
		table_name => $table_name,
		columns    => ['id', 'parent_id', 'name']			# Ignore codes.
#		columns    => ['id', 'parent_id', 'name', 'code']	# Write codes to table.
	) -> insert();

	print "OK. \n";

}	# End of save.

# -----------------------------------------------

try
{
	my($dbh) = DBI -> connect
	(
		'DBI:mysql:test:127.0.0.1',
		'root',
		'toor',
		{
			AutoCommit			=> 1,
			HandleError			=> sub {Error::Simple -> record($_[0]); 0},
			PrintError			=> 0,
			RaiseError			=> 1,
			ShowErrorStatement	=> 1,
		}
	);

	save($dbh);
}
catch Error::Simple with
{
	my($error) = 'Error::Simple: ' . $_[0] -> text();
	chomp($error);
	print "Error: $error. \n";
};
