# How to Migrate a Database from MySQL to Heroku Postgres

Heroku does a great job at making PostgreSQL databases easy to manage. For small projects it is quite cheap too, making it an attractive option. This is the process I used to migrate a project from an existing Amazon RDS database running MySQL to a new PostgreSQL database running on Heroku.

First step is pulling down the production database to work on the migration locally and avoid touching production as much as possible. The tool [`mysqldump`](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html) is a good choice for that and comes with MySQL in most package managers.

Since I was moving from an Amazon RDS DB with SSL enabled, my command looked like the following. You may not need to specify a certificate if your database doesn't have that enabled.

```bash
mysqldump -p --ssl-ca ./amazon-rds-ca-cert.pem \
          -u myusername \
          -h myhostname.12345abc.us-east-1.rds.amazonaws.com mydatabase > backup.sql
```

The `-p` flag will cause you to be prompted for a password.

Now the backup of the database can be loaded into a local instance of MySQL. I used a Docker container for this:

```bash
docker run -d --name mysql-migration \
           -e MYSQL_ROOT_PASSWORD=password \
           -p 3306:3306 \
           mysql --default-authentication-plugin=mysql_native_password
```

Since this is running locally, the password is intentionally weak. Also, the authentication plugin is changed to make connecting with `pgloader` easier later on.

Once the MySQL Docker container starts up, the backup we made can be loaded locally:

```bash
mysql -u root -ppassword -h 0.0.0.0 -e "create database mydatabase"
mysql -u root -ppassword -h 0.0.0.0 mydatabase < backup.sql
```

At this point you can connect to `mysql://root:password@localhost:3306/mydatabase` and verify that everything has been loaded with [mycli](https://github.com/dbcli/mycli) or your MySQL client of choice.

Next we need to setup a Postgres database to migrate into. Ultimately we will be moving to Heroku, but working locally is quicker and easier. Again I used Docker to create one:

```bash
docker run -d --name psql-migration \
           -p 5432:5432 \
           postgres
```

The default username is `postgres` and a password is not required.

Once the Postgres Docker container starts up, we can create the database that we are going to migrate into:

```bash
psql -U postgres -h 0.0.0.0 -c "create database mydatabase"
```

Finally comes the actual conversion from PostgreSQL to MySQL. I decided to use [pgloader](https://github.com/dimitri/pgloader) to accomplish this:

```bash
pgloader --with "preserve index names" \
         mysql://root:password@localhost/mydatabase \
         postgres://postgres:postgres@localhost:5432/mydatabase
```

The argument `--with "preserve index names"` prevents indexes from being renamed to avoid conflicts. See [this issue](https://github.com/dimitri/pgloader/issues/187) for a more complete explanation. If you have multiple tables in MySQL that have the same index names then you may need to remove that arg and rename the indexes manually using SQL commands like `ALTER INDEX idx_1234_my_index RENAME TO my_index_mytable` or some better naming scheme.

Now there's a little cleanup to do before we can copy our PostgreSQL database into Heroku. First, `pgloader` created a new schema with the name of our database `mydatabase` and each of our tables is inside that schema. You probably don't want that, so we move each table into the public schema. For example:

```bash
psql -U postgres -h 0.0.0.0 -d mydatabase -c "ALTER TABLE mydatabase.accounts SET SCHEMA public"
psql -U postgres -h 0.0.0.0 -d mydatabase -c "ALTER TABLE mydatabase.posts SET SCHEMA public"
```

Also, you're probably using `AUTO_INCREMENT` in MySQL and that's going to be a problem. MySQL's `AUTO_INCREMENT` is not part of the SQL standard. In Postgres the same behavior is achieved using sequences. For each of the places where `AUTO_INCREMENT` is used, a sequence should be created. For example:

```bash
psql -U postgres -h 0.0.0.0 -d mydatabase -c "CREATE SEQUENCE accounts_id_seq"
psql -U postgres -h 0.0.0.0 -d mydatabase -c "SELECT setval('accounts_id_seq', max(id)) FROM accounts"
psql -U postgres -h 0.0.0.0 -d mydatabase -c "ALTER TABLE accounts ALTER id SET DEFAULT NEXTVAL('accounts_id_seq')"
```

At this point you should have a fully functional Postgres version of your MySQL database running locally. You should update your code to connect to Postgres, which is hopefully easy if you're using an ORM. Once you have tested out your application locally, create an instance of the [Postgres add-on](https://elements.heroku.com/addons/heroku-postgresql) in Heroku. Copy the database URL from the settings page of your application. It will be in the "Config Vars" section under `DATABASE_URL`. Next we will dump the local database and copy it to Heroku:

```bash
DATABASE_URL="..."
pg_dump -U postgres -h 0.0.0.0 -n public -d mydatabase > postgres-dump.sql
psql -d "$DATABASE_URL" < postgres-dump.sql
```

Of course, if you're migrating a MySQL database that's running in production, then you don't want to be running all of these commands manually when it comes time to do the migration. It's best to create a script so the process can be completed as quickly as possible. Putting it all together looks like:

```bash
#!/bin/bash

# exit if any command fails
set -o errexit

# edit these vars to match your database
DATABASE_NAME=mydatabase
HEROKU_DATABASE_URL="..."
PRODUCTION_DATABASE_USER="..."
PRODUCTION_DATABASE_HOST="..."

# start up a Docker container to load the export of production into
docker run -d --name mysql-migration \
           -e MYSQL_ROOT_PASSWORD=password \
           -p 3306:3306 \
           mysql --default-authentication-plugin=mysql_native_password

# start up a Docker container to migrate into Postgres with
docker run -d --name psql-migration \
           -p 5432:5432 \
           postgres

# wait for the docker containers to start up
sleep 20

# create the database in MySQL
mysql -u root -ppassword -h 0.0.0.0 -e "create database $DATABASE_NAME"

# create the database in Postgres
psql -U postgres -h 0.0.0.0 -c "create database $DATABASE_NAME"

# make a dump of production
# at this point you will be prompted for a password
mysqldump -p --ssl-ca ./amazon-rds-ca-cert.pem \
          -u $PRODUCTION_DATABASE_USER \
          -h $PRODUCTION_DATABASE_HOST $DATABASE_NAME > backup.sql

# load the dump into the Docker instance of MySQL
mysql -u root -ppassword -h 0.0.0.0 $DATABASE_NAME < backup.sql

# migrate from MySQL to Postgres locally
pgloader --with "preserve index names" \
         mysql://root:password@localhost/$DATABASE_NAME \
         postgres://postgres:postgres@localhost:5432/$DATABASE_NAME

# move each table into the public schema
# edit this to list each table
for TABLE in accounts posts myothertable
do
  psql -U postgres -h 0.0.0.0 -d $DATABASE_NAME -c "ALTER TABLE $DATABASE_NAME.$TABLE SET SCHEMA public"
done

# function to handle replacing AUTO_INCREMENT with Postgres sequences
add_sequence_to_column () {
  # $1 is table name and $2 is column name
  psql -U postgres -h 0.0.0.0 -d $DATABASE_NAME -c "CREATE SEQUENCE $1_$2_seq"
  psql -U postgres -h 0.0.0.0 -d $DATABASE_NAME -c "SELECT setval('$1_$2_seq', max($2)) FROM $1"
  psql -U postgres -h 0.0.0.0 -d $DATABASE_NAME -c "ALTER TABLE $1 ALTER $2 SET DEFAULT NEXTVAL('$1_$2_seq')"
}

# edit these to match the actual tables and columns that need automatically incrementing IDs
add_sequence_to_column "accounts" "id"
add_sequence_to_column "posts" "id"

# dump the cleaned up local database to a file
pg_dump -U postgres -h 0.0.0.0 -n public -d $DATABASE_NAME > postgres-dump.sql

# reset the database before loading the dump
# edit this with your Heroku app name
heroku pg:reset DATABASE_URL --confirm my_heroku_app_name -a my_heroku_app_name

# load the dump into Heroku
psql -d "$HEROKU_DATABASE_URL" < postgres-dump.sql

# remove the temp files we created
rm backup.sql postgres-dump.sql

# remove the Docker containers
docker stop mysql-migration psql-migration
docker rm mysql-migration psql-migration
```
