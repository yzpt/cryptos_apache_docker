# docker compose extract:
#   postgresql:
#     image: bitnami/postgresql:latest
#     environment:
#       - POSTGRES_USER=spark
#       - POSTGRES_PASSWORD=spark
#       - POSTGRES_DB=spark
#     ports:
#       - "5432:5432"
#     volumes:
#       - ./data_postgresql:/var/lib/postgresql/data
#     networks:
#       - confluent

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