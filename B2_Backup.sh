
# b2 configuration variables
B2_ACCOUNT_ID=''
B2_APPLICATION_KEY=''
BUCKET=''

# Database credentials
DB_USER=''

# Backup these databases
DATABASES=(DB1 DB2 DB3) 

# Working directory
WORKING_DIR=/tmp/bak

########################################################################

# Make the working directory
mkdir $WORKING_DIR

#
# Dump the databases
#
for database in ${DATABASES[@]}; do
  mysqldump -u $DB_USER $database > $WORKING_DIR/$database.sql
done

#Take a list of installed applications 
dpkg --get-selections > $WORKING_DIR/Package.list
cp -R /etc/apt/sources.list* $WORKING_DIR/
apt-key exportall > $WORKING_DIR/Repo.keys

#Backup Python Packages 
pip3 freeze > $WORKING_DIR/Python-pkg.txt

#Backup only selected config files and directoreis.
duplicity 
	--include /home/User \
	--include /etc/vsftpd.conf \
	--include /etc/vsftpd.userlist \
	--include /etc/postfix \
	--include /etc/apache2 \
	--include /etc/php/7.0 \
	--include /var/www \
	--include /etc/mysql/my.cnf \
	--include $WORKING_DIR/Package.list \
	--include /tmp/backup \
	--exclude '**' b2://$B2_ACCOUNT_ID:$B2_APPLICATION_KEY@$BUCKET $WORKING_DIR/

# Send them to b2, make a full backup if it's been over 30 days
duplicity --full-if-older-than 30D $WORKING_DIR b2://$B2_ACCOUNT_ID:$B2_APPLICATION_KEY@$BUCKET

# Verify
duplicity verify b2://$B2_ACCOUNT_ID:$B2_APPLICATION_KEY@$BUCKET $WORKING_DIR

# Cleanup backups older than 90 days
duplicity remove-older-than 90D --force b2://$B2_ACCOUNT_ID:$B2_APPLICATION_KEY@$BUCKET

# Remove the working directory - Cleaning-up
rm -rf $WORKING_DIR

