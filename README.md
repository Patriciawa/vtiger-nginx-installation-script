Vtiger installation script for nginx
Tested on debian 9. but should also work on debian 10, ubuntu 16/18.

It makes a server block and creates a mysql database. Then it puts the DB credentials inside the setup.


Installation steps:

1. Download the latest vtiger tar. Current is vtigercrm7.2.0.tar.gz
2. Extract it. You now have a vtigercrm directory, you can possibly move it to you web directory (ex /var/www/vtiger) 
Do not change the name of the file!!
3. sudo chmod +x script.sh. To make it executable.
4. Edit the variables in script.sh according to you needs.

run ./script.sh subdomain

Wait a bit and you have your vtiger installation ready on subdomain.example.com
