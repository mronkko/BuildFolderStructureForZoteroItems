#!/usr/bin/perl

use DBI;

my $zoterostorage="/Users/mronkko/Documents/Research/Zotero Data";
my $target="/Users/mronkko/Documents/Research/Articles";

my $dbh = DBI->connect("dbi:SQLite:dbname=$zoterostorage/zotero.sqlite","","");

# Query all PDF attachments

my $sth = $dbh->prepare('	SELECT
							/* Any fields that we use to buld the path name from */
							idv1.value, idv2.value, 
							/* fields that are needed to locate the file inside zotero data directory */
							i2.key, ia.path
							/* Tables needed for the fields that we use for path name */
							FROM itemDataValues idv1, itemDataValues idv2, itemData id1, itemData id2,
							/* Tables for parent item, child item and attachment data for the child item */
							items i, items i2, itemAttachments ia 
							WHERE  
							/* Link the first field that we need for path name */
							idv1.valueID=id1.valueID AND id1.fieldID=14 AND i.itemID=id1.itemID
							/* Link the second field that we need for path name */
							AND idv2.valueID=id2.valueID AND id2.fieldID=12 AND i.itemID=id2.itemID 
							/*Links the attachment to the parent item*/
							AND ia.sourceItemID=i.itemID AND i2.itemID=ia.itemID
							/* Only items stored within Zotero */
							AND ia.linkMode=1 
							/* Only PDFs */
							AND ia.mimeType="application/pdf";' ) or die "Couldn't prepare statement: " . $dbh->errstr;

$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;

print "Building links\n";  

while (@data = $sth->fetchrow_array()) {
	# date, journal, key, path
	my $year=substr($data[0],0,4);
	my $file=substr($data[3],8);
	my $itempath="$zoterostorage/storage/$data[2]/$file";
	my $linkpath="$target/$data[1]/$year/$file";
	print "\nLinking item\n$itempath\n--> $linkpath\n\n";
	
	#Create the link, but only if the file exists
	if(-e $itempath){
	
		#And if the same file is not already linked
		if(-e $linkpath){
			print "Skipping because link already exists";
		}
		else{
			#Ensure that the path exists

			unless(-d "$target/$data[1]"){
    			mkdir "$target/$data[1]" or die "Unable to create path $target/$data[1]";
			}
			unless(-d "$target/$data[1]/$year"){
    			mkdir "$target/$data[1]/$year" or die "Unable to create path $target/$data[1]/$year";
			}

			symlink($itempath,$linkpath) or die "Unable to create link";
		}
	}
	else{
		print "Skipping non-existingfile";
	}
}

#
#'SELECT
#/* Any fields that we use to buld the path name from */
#idv1.value, cd.*, 
#/* fields that are needed to locate the file inside zotero data directory */
#i2.key, ia.path
#/* Tables needed for the fields that we use for path name */
#FROM itemDataValues idv1, itemData id1, creators c, creatorData cd, itemCreators ic,
#/* Tables for parent item, child item and attachment data for the child item */
#items i, items i2, itemAttachments ia 
#WHERE  
#/* Link the first field that we need for path name */
#idv1.valueID=id1.valueID AND id1.fieldID=14 AND i.itemID=id1.itemID
#/* First author */
#AND i.itemID=ic.itemID AND ic.creatorID=c.creatorID AND cd.creatorDataID=c.creatorDataID AND ic.orderIndex=0
#/*Links the attachment to the parent item*/
#AND ia.sourceItemID=i.itemID AND i2.itemID=ia.itemID
#/* Only items stored within Zotero */
#AND ia.linkMode=1 
#/* Only PDFs */
#AND ia.mimeType="application/pdf";'
#