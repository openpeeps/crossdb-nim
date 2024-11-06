import unittest
import ../src/crossdb

var imdb: CDBConnection
test "imdb - init":
  imdb = crossdb.initMemory()
  assert imdb.isNil == false

test "imdb - create table":
  let res = imdb.execute("CREATE TABLE IF NOT EXISTS student (id INT PRIMARY KEY, name CHAR(16), age INT, class CHAR(16), score FLOAT, info CHAR(255))")
  assert res[].errcode == 0

test "imdb - insert data":
  let res = imdb.execute("INSERT INTO student (id,name,age,class,score) VALUES (1,'jack',10,'3-1',90),(2,'tom',11,'2-5',91),(3,'jack',11,'1-6',92),(4,'rose',10,'4-2',90),(5,'tim',10,'3-1',95)")
  assert res[].errcode == 0

test "imdb - query data":
  let rows = imdb.execGet("SELECT * FROM student")
  for row in rows:
    for col in row:
      case col.kind
      of XDB_TYPE_CHAR:
        if col.name == "name":
          echo "Name: " & col.strValue
      of XDB_TYPE_FLOAT:
        if col.name == "score":
          echo "Score: " & $col.float32Value
      else: discard
    echo "---"
