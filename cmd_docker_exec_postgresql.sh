docker compose exec postgresql psql -U spark
CREATE TABLE spark_table (
    id SERIAL PRIMARY KEY,
    message VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

#  list tables
\dt

#  list database
\l

SELECT * FROM spark_table;