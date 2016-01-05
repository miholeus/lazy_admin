#!/usr/bin/env bash
################################################################################
#
# The simple and quick MySQL database backup shell script.
# It dumps all databases into a directory specified. It exports .sql file
# for each database with the file name format of <db_name>_<YYYYMMDD>.sql
#
# Licensed under The MIT License
# For full copyright and license information, please see LICENSE
#
# @author     Sithu Kyaw <hello@sithukyaw.com>
# @license    http://www.opensource.org/licenses/mit-license.php MIT License
#
################################################################################

# Set variables
# Store mysql login information in a file e.g., $HOME\.my.cnf with your mysql information
#
#    [client]
#    host=your_host
#    user=your_username
#    password=your_password
#
# To keep the password safe, the file should not be accessible to anyone but yourself.
# To ensure this, set the file access mode to 400 or 600, e.g., chmod 600 [the-file]
# @see http://dev.mysql.com/doc/refman/5.5/en/password-security-user.html
# Set the fully qualified path name to the file here
mysqlLogin=$HOME/.my.cnf
# path to where your mysql was installed
mysqlDir="/usr/bin/"
# The directory where you want to save your sql files
# It will be created if it does not exist
backupDir=$HOME/.mysqlbackup
# The system databases which don't need to be dumped
dbsIgnored="information_schema cdcol mysql performance_schema phpmyadmin test webauth"
# Temp file
tmpFile=$HOME/tmp/mysqldbs.tmp
# Current date
today=$(date '+%Y%m%d');

# Argument capturing
paramName=""
dbs=""

# Error handling
# Check configuration for mysql login information
if [ ! -f $mysqlLogin ]; then
	echo -e "[client]\nhost=localhost\nuser=root\npassword=" > $mysqlLogin
	echo -e "\n"
	echo "NOTICE^^! at line 28 in mysqldump"
	echo "Configuration file $mysqlLogin has been created."
	echo "Update your mysql login information in the file as below:"
	echo -e "\n"
	echo "   [client]"
	echo "   host=your_host"
	echo "   user=your_username"
	echo "   password=your_password"
	echo -e "\n"
	echo "To keep the password safe, the file should not be accessible to anyone but yourself."
	echo "To ensure this, set the file access mode to 400 or 600, e.g., chmod 600 [the-file]"
	echo "@see http://dev.mysql.com/doc/refman/5.5/en/password-security-user.html"
	echo -e "\n"
	exit 1
fi

# All arguments processing
for arg in "$@"; do
	# long parameter name such as --argument
	if [ ${arg:0:2} == "--" ]; then
		paramName=$arg
		continue
	elif [ "$paramName" = "--dbs" ]; then
		dbs="$dbs $arg"
	fi
	# short parameter name such as -a
	if [ ${arg:0:1} == "-" ]; then
		paramName=$arg
		continue
	elif [ "$paramName" == "-d" ]; then
		dbs="$dbs $arg"
	fi
done

# Function to find an item in list
listContains() {
	[[ $1 =~ $2 ]] && return 0
	return 1
}

# Create the backup directory if not exists
if [ ! -d $backupDir ]; then
	mkdir $backupDir
	echo "$backupDir is created."
fi

if [ "$dbs" == "" ]; then
	# Dump all databases
	# Get all databases name into a temp file
	# If the server was started with the --skip-show-database option,
	# you cannot use this statement at all unless you have the SHOW DATABASES privilege.
	mysql --defaults-extra-file=$mysqlLogin -e "SHOW DATABASES" > $tmpFile
	# Process all database names in the file and filter into an array
	databases=()
	while read dbname; do
		if [ "$dbname" == "Database" ]; then continue; fi
		if listContains "$dbsIgnored" $dbname; then continue; fi
		databases+=($dbname)
	done < $tmpFile
	# Delete the temporary file by force
	rm -f $tmpFile
else
	# Dump the databases given
	databases=($dbs)
fi

# Export the databases in separate files
count=1
for dbname in ${databases[*]}; do
	echo "Dumping $dbname ..."
	mysqldump --defaults-extra-file=$mysqlLogin --quick --opt --add-drop-database --databases $dbname > "$backupDir/${dbname}_$today.sql"
	echo "Exported $backupDir/${dbname}_$today.sql"
	echo "##### $count of ${#databases[*]} completed."
	count=$(( $count + 1 ))
done

echo -e "Done!\n"
exit 0
