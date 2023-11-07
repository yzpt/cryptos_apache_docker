docker compose exec postgresql psql -U spark



#  list database
\l

# select database
\c spark

#  list tables
\dt

CREATE TABLE spark_table (
    id SERIAL PRIMARY KEY,
    message VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

SELECT * FROM spark_table;