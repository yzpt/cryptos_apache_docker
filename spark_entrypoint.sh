# echo "pwd ----------------"
# pwd

# echo "ls -----------------"
# ls

# echo "cd .. -----------------"
# cd ..

# echo "ls -----------------"
# ls

# echo "cd pyspark_script -----------------"
# cd pyspark_scripts

# echo "ls -----------------"
# ls

# echo "chmod --------------"
# chmod -R 777 checkpoint 


chmod -R 777 ../pyspark_scripts/checkpoint
echo "checkpoint folder permission changed"

bin/spark-class org.apache.spark.deploy.master.Master