#!/bin/bash

# Read environment variables from docker-compose.yml
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
DB_DATABASE=${DB_DATABASE}

# Generate the init.sql file
cat <<EOF > /docker-entrypoint-initdb.d/init.sql
DROP DATABASE IF EXISTS \`${DB_DATABASE}\`;
CREATE DATABASE \`${DB_DATABASE}\` DEFAULT CHARACTER SET = \`utf8mb4\` COLLATE = \`utf8mb4_unicode_ci\`;

CREATE USER '${DB_USERNAME}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON \`${DB_DATABASE}\`.* TO '${DB_USERNAME}'@'localhost';
FLUSH PRIVILEGES;

CREATE USER '${DB_USERNAME}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON \`${DB_DATABASE}\`.* TO '${DB_USERNAME}'@'%';
FLUSH PRIVILEGES;
EOF

echo "SQL initialization file generated at /docker-entrypoint-initdb.d/init.sql"