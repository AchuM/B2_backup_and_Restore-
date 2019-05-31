#/bin/bash

B2_ACCOUNT_ID=''
B2_APPLICATION_KEY=''
BUCKET=''
#Please put the GPG passphrase you created.   
#GPG_PASSPHRASE=''
#Please put your MySQL password here. This will be to install MySql silently and restore database backups. 
MYSQL_PASS='' 

# Working directory
WORKING_DIR=/tmp/bak
#Restore installed packages list first
duplicity restore --file-to-restore tmp/duplicity_b2_backup/package.list	b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET $WORKING_DIR
duplicity restore --file-to-restore tmp/duplicity_b2_backup/sources.list	b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET $WORKING_DIR
duplicity restore --file-to-restore tmp/duplicity_b2_backup/sources.list.d/	b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET $WORKING_DIR
duplicity restore --file-to-restore tmp/duplicity_b2_backup/repo.keys		b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET $WORKING_DIR
duplicity restore --file-to-restore tmp/duplicity_b2_backup/py2-pkg.lst 	b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET $WORKING_DIR
duplicity restore --file-to-restore tmp/duplicity_b2_backup/py3-pkg.lst 	b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET $WORKING_DIR

#Bring Databases First  
duplicity restore --file-to-restore		tmp/duplicity_b2_backup/DB1.sql 			b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET $WORKING_DIR
duplicity restore --file-to-restoretmp	tmp//duplicity_b2_backup/DB2.sql 		b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET $WORKING_DIR
duplicity restore --file-to-restoretmp	tmp//duplicity_b2_backup/DB3.sql 	b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET $WORKING_DIR
duplicity restore --file-to-restore 	tmp/duplicity_b2_backup/DB4.sql 			b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET $WORKING_DIR

#Install mysql first 
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password $MYSQL_PASS'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $MYSQL_PASS'
sudo apt-get -y install mysql-server

#And now restore database's
mysql -u root -p$MYSQL_PASS foojitsu < $WORKING_DIR/DB1.sql
mysql -u root -p$MYSQL_PASS ricardajunker < $WORKING_DIR/DB2.sql
mysql -u root -p$MYSQL_PASS unity_analytics < $WORKING_DIR/DB3.sq
mysql -u root -p$MYSQL_PASS work_hours < $WORKING_DIR/DB4.sql

#Recover other installed packages
sudo apt-key add $WORKING_DIR/repo.keys
sudo cp -R $WORKING_DIR/sources.list /etc/apt/
sudo cp -R $WORKING_DIR/sources.list.d/ /etc/apt/
sudo apt-get update -y
sudo apt-get install dselect -y
sudo dpkg --set-selections < $WORKING_DIR/package.list
sudo dselect

#Restore python packages which had been installed with pip2 and pip3 
pip install --target=$WORKING_DIR/py2-pkg.lst
pip install --target=$WORKING_DIR/py3-pkg.lst

#Test 
pip install -r py2-pkg.lst
pip install -r py3-pkg.lst

#Restore directories and config files 
duplicity restore --file-to-restore home/joba b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET /home/
duplicity restore --file-to-restore var/www b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET /var/

duplicity restore --file-to-restore etc/vsftpd.conf b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET /etc/
duplicity restore --file-to-restore etc/vsftpd.userlist b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET /etc/

duplicity restore --file-to-restore etc/postfix/ b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET /etc/
duplicity restore --file-to-restore etc/apache2/ b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET /etc/

duplicity restore --file-to-restore etc/php/7.0/ b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET /etc/php/
duplicity restore --file-to-restore etc/mysql/my.cnf b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET /etc/mysql/
duplicity restore --file-to-restore /etc/systemd/system b2://$B2_ACCOUNT_ID:$B2_APPLICATION_ID@$BUCKET /etc/systemd/ 

#Enabling/Starting Services 
systemctl enable b2_backup 
service mysql restart
systemctl start apache2.service

#Cleaning up
rm -rf $WORKING_DIR
