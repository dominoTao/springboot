#行列转换
USE csdn;
DROP TABLE IF EXISTS flow_table;
CREATE TABLE `flow_table` (
	`ID` INT(11) NOT NULL AUTO_INCREMENT,
	`Number` BIGINT (11) NOT NULL,
	`City` VARCHAR(10) NOT NULL,
	`wm201403` DECIMAL(7,2) DEFAULT NULL,
	`wm201404` DECIMAL(7,2) DEFAULT NULL,
	`wm201405` DECIMAL(7,2) DEFAULT NULL,
	`wm201406` DECIMAL(7,2) DEFAULT NULL,
	`wm201407` DECIMAL(7,2) DEFAULT NULL,
	`wm201408` DECIMAL(7,2) DEFAULT NULL,
	PRIMARY KEY (`ID`,`Number`)
) ENGINE=INNODB DEFAULT CHARSET=UTF8;


INSERT INTO flow_table(Number,City,wm201403,wm201404,wm201405,wm201406,wm201407,wm201408)SELECT 1,'shanghai',100.2,180.4,141,164,124,127;
INSERT INTO flow_table(Number,City,wm201403,wm201404,wm201405,wm201406,wm201407,wm201408)SELECT 2,'shanghai',110.23,180.34,141.23,104.78,124.67,127.45;
INSERT INTO flow_table(Number,City,wm201403,wm201404,wm201405,wm201406,wm201407,wm201408)SELECT 3,'beijing',123.23,110.34,131.33,154.58,154.67,167.45;
INSERT INTO flow_table(Number,City,wm201403,wm201404,wm201405,wm201406,wm201407,wm201408)SELECT 4,'hangzhou',0,110.34,131.33,154.58,154.67,0;
INSERT INTO flow_table(Number,City,wm201403,wm201404,wm201405,wm201406,wm201407,wm201408)SELECT 5,'hangzhou',131.33,154.58,154.67,0;


#2，存储过程遍历：
#这个存储过程建立了2张临时表，查询测试表数据形成游标，遍历游标根据主键Number来调用pro_flow_modify存储过程进行行列变化。代码如下：
CREATE DEFINER = CURRENT_USER PROCEDURE `NewProc`()
DROP PROCEDURE IF EXISTS csdn.`proc_all_changes`
CREATE PROCEDURE csdn.proc_all_changes()
BEGIN
    DECLARE v_number BIGINT;
    DECLARE v_city VARCHAR(10);
    DECLARE _done INT DEFAULT 0;

    /*定义游标*/
    DECLARE cur_all CURSOR FOR SELECT Number,City FROM csdn.`flow_table`;
    /**这里如果需要定义下当NOT FOUND的时候，EXIT退出游标遍历，不然如果设置成CONTINUE会一直执行下去。*/
    DECLARE EXIT HANDLER FOR NOT FOUND BEGIN SET _done=1;END;

       /*建立临时表，存放所有字段的临时表*/
	DROP TABLE IF EXISTS flow_n_columns;
	CREATE TABLE `flow_n_columns` (
	  `column_name` VARCHAR(10) NOT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;

	/*存放最终变成行的数据表*/
	DROP TABLE IF EXISTS flow_tmp;
	CREATE TABLE `flow_tmp` (
	  `Number` INT(11) DEFAULT NULL,
	  `City` VARCHAR(10) DEFAULT NULL,
	  `wm_str` VARCHAR(10) DEFAULT NULL,
	  `Wm` DECIMAL(7,2) DEFAULT NULL
	) ENGINE=INNODB DEFAULT CHARSET=utf8;

    OPEN cur_all;
    REPEAT
        FETCH cur_all INTO v_number, v_city;
        IF NOT _done THEN
		CALL csdn.pro_flow_modify(v_number,v_city);
        END IF;
        UNTIL _done=1 END REPEAT;
    CLOSE cur_all;
    	/*展示下所有的行转列的数据**/
	SELECT * FROM csdn.flow_tmp;
END;
#3，行里变化存储过程
#通过查询系统表information_schema.`COLUMNS`来获取测试表flow_table的所有列，然后写动态SQL，来把列的值录入到临时表###flow_tmp中。
DROP PROCEDURE IF EXISTS csdn.`pro_flow_modify`$$
CREATE PROCEDURE csdn.`pro_flow_modify`(p_Number INT,p_city VARCHAR(10))
BEGIN
	DECLARE v_column_name VARCHAR(10) DEFAULT '';
	DECLARE v_exe_sql VARCHAR(1000) DEFAULT '';
	DECLARE v_start_wm VARCHAR(10) DEFAULT '';
	DECLARE v_end_wm VARCHAR(10) DEFAULT '';
	DECLARE v_num  DECIMAL(10,2) DEFAULT 0;

	DECLARE i INT DEFAULT 1;
	DECLARE v_Number INT DEFAULT 0;
	SET v_Number=p_Number;

	DELETE FROM csdn.flow_n_columns;
	DELETE FROM csdn.flow_tmp WHERE Number=v_Number;


	/*把测试表flow_table的所有字段都录入字段临时表中，这样就达到了从列变成行的目的*/
	INSERT INTO flow_n_columns
	SELECT t.`COLUMN_NAME` FROM information_schema.`COLUMNS` t WHERE t.`TABLE_NAME`='flow_table' AND t.`TABLE_SCHEMA`='csdn' AND t.`COLUMN_NAME` NOT IN('ID','Number','City');
	SELECT column_name INTO v_column_name FROM csdn.flow_n_columns LIMIT 1;

	/*开始循环遍历字段临时表的字段数据，并且把字段值放入临时表flow_tmp里面*/
	WHILE i>0 DO
		SET v_exe_sql=CONCAT('INSERT INTO csdn.flow_tmp(Number,City,wm_str,Wm) select ',v_Number,',\'',p_city, '\',\'',v_column_name,'\',',v_column_name,' from csdn.flow_table WHERE flow_table.Number=',v_Number,';');
		SET @sql=v_exe_sql;
		PREPARE s1 FROM @sql;
		EXECUTE s1;
		DEALLOCATE PREPARE s1;
		DELETE FROM csdn.flow_n_columns WHERE column_name=v_column_name;
		SELECT column_name INTO v_column_name FROM csdn.flow_n_columns LIMIT 1;
		SELECT COUNT(1) INTO i FROM csdn.flow_n_columns ;
		DELETE FROM csdn.flow_tmp WHERE Wm=0;
	END WHILE;

	/*由于触发器是不支持动态sql，所以不能使用while循环，动态遍历所有统计列的，只能写死列了，如下所示：
	现在一个个insert只能写死了, flow_table表有多少个统计列就写多少个insert sql，以后新添加一个列，就在这里新添加一条insertsql语句
	INSERT INTO flow_tmp(Number,City,wm_str,Wm) SELECT v_Number,p_city,'wm201403',wm201403 FROM flow_table WHERE Number=v_Number ;
	INSERT INTO flow_tmp(Number,City,wm_str,Wm) SELECT v_Number,p_city,'wm201404',wm201404 FROM flow_table WHERE Number=v_Number ;
	INSERT INTO flow_tmp(Number,City,wm_str,Wm) SELECT v_Number,p_city,'wm201405',wm201405 FROM flow_table WHERE Number=v_Number ;
	INSERT INTO flow_tmp(Number,City,wm_str,Wm) SELECT v_Number,p_city,'wm201406',wm201406 FROM flow_table WHERE Number=v_Number ;
	INSERT INTO flow_tmp(Number,City,wm_str,Wm) SELECT v_Number,p_city,'wm201407',wm201407 FROM flow_table WHERE Number=v_Number ;
	INSERT INTO flow_tmp(Number,City,wm_str,Wm) SELECT v_Number,p_city,'wm201408',wm201408 FROM flow_table WHERE Number=v_Number ;
	*/

	/*清除掉不数据=0的列*/
	DELETE FROM csdn.flow_tmp WHERE Wm=0 OR Wm IS NULL;

	SELECT wm_str INTO v_start_wm FROM csdn.flow_tmp WHERE Number=v_Number ORDER BY wm_str ASC LIMIT 1;
	SELECT wm_str INTO v_end_wm FROM csdn.flow_tmp WHERE Number=v_Number ORDER BY wm_str DESC LIMIT 1;
	SELECT SUM(Wm) INTO v_num FROM csdn.flow_tmp WHERE Number=v_Number;
END
#统计每个用户的使用总量为：
SELECT * FROM csdn.flow_tmp;
SELECT Number,SUM(Wm) 'total_num' FROM flow_tmp GROUP BY Number ORDER BY Number;









#行变列
USE csdn;
DROP TABLE IF EXISTS csdn.tb;
CREATE TABLE tb(`cname` VARCHAR(10),cource VARCHAR(10),score INT) ENGINE=INNODB;

INSERT INTO tb VALUES('张三','语文',74);
INSERT INTO tb VALUES('张三','数学',83);
INSERT INTO tb VALUES('张三','物理',93);
INSERT INTO tb VALUES('李四','语文',74);
INSERT INTO tb VALUES('李四','数学',84);
INSERT INTO tb VALUES('李四','物理',94);

SELECT * FROM tb;


SELECT cname AS "姓名",
	SUM(IF(cource="语文",score,0)) AS "语文",
	SUM(IF(cource="数学",score,0)) AS "数学",
	SUM(IF(cource="物理",score,0)) AS "物理",
	SUM(score) AS "总成绩",
	ROUND(AVG(score),2) AS "平均成绩"
FROM tb
GROUP BY cname
UNION ALL
SELECT
	"总成绩平均数",
	ROUND(AVG(`语文`),2) , ROUND(AVG(`数学`),2), ROUND(AVG(`物理`),2), ROUND(AVG(`总成绩`),2), ROUND(AVG(`平均成绩`),2)
FROM(
	SELECT "all",cname AS "姓名",
		SUM(IF(cource="语文",score,0)) AS "语文",
		SUM(IF(cource="数学",score,0)) AS "数学",
		SUM(IF(cource="物理",score,0)) AS "物理",
		SUM(score) AS "总成绩",
		AVG(score) AS "平均成绩"
	FROM tb
	GROUP BY cname
)tb2
GROUP BY tb2.all;


SELECT
	cname AS "姓名",
	MAX(CASE cource WHEN "语文" THEN score ELSE 0 END) AS "语文",
	MAX(CASE cource WHEN "数学" THEN score ELSE 0 END) AS "数学",
	MAX(CASE cource WHEN "物理" THEN score ELSE 0 END) AS "物理",
	SUM(score) AS "总成绩",
	ROUND(AVG(score) ,2) AS "平均成绩"
FROM tb
GROUP BY `cname`
UNION ALL
SELECT
	"总成绩平均数",
	ROUND(AVG(`语文`),2) , ROUND(AVG(`数学`),2), ROUND(AVG(`物理`),2), ROUND(AVG(`总成绩`),2), ROUND(AVG(`平均成绩`),2)
FROM(	SELECT 'all' ,
		cname AS "姓名",
		MAX(CASE cource WHEN "语文" THEN score ELSE 0 END) AS "语文",
		MAX(CASE cource WHEN "数学" THEN score ELSE 0 END) AS "数学",
		MAX(CASE cource WHEN "物理" THEN score ELSE 0 END) AS "物理",
		SUM(score) AS "总成绩",
		ROUND(AVG(score) ,2) AS "平均成绩"
	FROM tb
	GROUP BY `cname`
)tb2 GROUP BY tb2.all


SELECT IFNULL(cname,'总平均数') AS "姓名",
	MAX(CASE cource WHEN "语文" THEN score ELSE 0 END) AS "语文",
	MAX(CASE cource WHEN "数学" THEN score ELSE 0 END) AS "数学",
	MAX(CASE cource WHEN "物理" THEN score ELSE 0 END) AS "物理",
	ROUND(AVG(score),2) AS "总成绩",
	ROUND(AVG(avg_score),2) AS "平均成绩"
    FROM(
	SELECT
		cname ,
		IFNULL(cource,'total') cource,
		SUM(score) AS score,
		ROUND(AVG(score) ,2) AS avg_score
	FROM tb
	GROUP BY `cname`,cource WITH ROLLUP HAVING cname IS NOT NULL
	)tb2
	GROUP BY  tb2.cname WITH ROLLUP;


	mysql>     SELECT IFNULL(cname,'总平均数') AS "姓名",
    -> MAX(CASE cource WHEN "语文" THEN score ELSE 0 END) AS "语文",
    -> MAX(CASE cource WHEN "数学" THEN score ELSE 0 END) AS "数学",
    -> MAX(CASE cource WHEN "物理" THEN score ELSE 0 END) AS "物理",
    -> ROUND(AVG(score),2) AS "总成绩",
    -> ROUND(AVG(avg_score),2) AS "平均成绩"
    ->     FROM(
    -> SELECT
    ->
Display ALL 793 possibilities? (Y OR n)
    -> cname ,
    ->
Display ALL 793 possibilities? (Y OR n)
    -> IFNULL(cource,'total') cource,
    ->
Display ALL 793 possibilities? (Y OR n)
    -> SUM(score) AS score,
    ->
Display ALL 793 possibilities? (Y OR n)
    -> ROUND(AVG(score) ,2) AS avg_score
    -> FROM tb
    -> GROUP BY `cname`,cource WITH ROLLUP HAVING cname IS NOT NULL
    -> )tb2
    -> GROUP BY  tb2.cname WITH ROLLUP;
+--------------+--------+--------+--------+-----------+--------------+
| 姓名         | 语文   | 数学   | 物理   | 总成绩    | 平均成绩     |
+--------------+--------+--------+--------+-----------+--------------+
| 张三         |     74 |     83 |     93 |    125.00 |        83.33 |
| 李四         |     74 |     84 |     94 |    126.00 |        84.00 |
| 总平均数     |     74 |     84 |     94 |    125.50 |        83.67 |
+--------------+--------+--------+--------+-----------+--------------+
3 ROWS IN SET, 1 warning (0.00 sec)

mysql>





/*仅仅班级成员部分*/
SET @a='';
SELECT @a:=CONCAT(@a,'SUM(IF(cource=\'',cource,'\'',',score,0)) AS ',cource,',') FROM (SELECT DISTINCT cource FROM tb) A;
SET @a=CONCAT(@a,"ROUND(AVG(score) ,2) AS \"平均成绩\"");
SET @b=CONCAT('SELECT IFNULL(cname,\'总成绩\'),',LEFT(@a,LENGTH(@a)-1),' ,SUM(score) AS \"总成绩\" FROM tb GROUP BY cname ');

/*班级成员总计部分**/
SET @a2="";
SET @b2=CONCAT('SELECT "all",IFNULL(cname,\'总成绩\'),',LEFT(@a,LENGTH(@a)-1),' ,SUM(score) AS \"总成绩\" FROM tb GROUP BY cname ');
SELECT @a2:=CONCAT(@a2,'ROUND(AVG(`',cource,'`),2),') FROM (SELECT DISTINCT cource FROM tb) A;
SET @a2=CONCAT(@a2," ROUND(AVG(`平均成绩`),2),ROUND(AVG(`总成绩`),2) ");
SET @c=CONCAT("SELECT \"班级平均数\",",LEFT(@a2,LENGTH(@a)-1)," FROM(",@b2,")tb2 GROUP BY tb2.all;");
SET @d=CONCAT(@b," UNION ALL ",@c);

PREPARE stmt1 FROM @d;
EXECUTE stmt1;



mysql> /*仅仅班级成员部分*/
mysql> SET @a='';
QUERY OK, 0 ROWS affected (0.00 sec)

mysql> SELECT @a:=CONCAT(@a,'SUM(IF(cource=\'',cource,'\'',',score,0)) AS ',cource,',') FROM (SELECT DISTINCT cource FROM tb) A;
+-----------------------------------------------------------------------------------------------------------------------------------+
| @a:=CONCAT(@a,'SUM(IF(cource=\'',cource,'\'',',score,0)) AS ',cource,',')                                                         |
+-----------------------------------------------------------------------------------------------------------------------------------+
| SUM(IF(cource='语文',score,0)) AS 语文,                                                                                           |
| SUM(IF(cource='语文',score,0)) AS 语文,SUM(IF(cource='数学',score,0)) AS 数学,                                                    |
| SUM(IF(cource='语文',score,0)) AS 语文,SUM(IF(cource='数学',score,0)) AS 数学,SUM(IF(cource='物理',score,0)) AS 物理,             |
+-----------------------------------------------------------------------------------------------------------------------------------+
3 ROWS IN SET (0.00 sec)

mysql> SET @a=CONCAT(@a,"ROUND(AVG(score) ,2) AS \"平均成绩\"");
QUERY OK, 0 ROWS affected (0.00 sec)

mysql> SET @b=CONCAT('SELECT IFNULL(cname,\'总成绩\'),',LEFT(@a,LENGTH(@a)-1),' ,SUM(score) AS \"总成绩\" FROM tb GROUP BY cname ');
QUERY OK, 0 ROWS affected (0.00 sec)

mysql>
mysql> /*班级成员总计部分**/
mysql> SET @a2="";
QUERY OK, 0 ROWS affected (0.00 sec)

mysql> SET @b2=CONCAT('SELECT "all",IFNULL(cname,\'总成绩\'),',LEFT(@a,LENGTH(@a)-1),' ,SUM(score) AS \"总成绩\" FROM tb GROUP BY cname ');
QUERY OK, 0 ROWS affected (0.00 sec)

mysql> SELECT @a2:=CONCAT(@a2,'ROUND(AVG(`',cource,'`),2),') FROM (SELECT DISTINCT cource FROM tb) A;
+-----------------------------------------------------------------------+
| @a2:=CONCAT(@a2,'ROUND(AVG(`',cource,'`),2),')                        |
+-----------------------------------------------------------------------+
| ROUND(AVG(`语文`),2),                                                 |
| ROUND(AVG(`语文`),2),ROUND(AVG(`数学`),2),                            |
| ROUND(AVG(`语文`),2),ROUND(AVG(`数学`),2),ROUND(AVG(`物理`),2),       |
+-----------------------------------------------------------------------+
3 ROWS IN SET (0.00 sec)

mysql> SET @a2=CONCAT(@a2," ROUND(AVG(`平均成绩`),2),ROUND(AVG(`总成绩`),2) ");
QUERY OK, 0 ROWS affected (0.00 sec)

mysql> SET @c=CONCAT("SELECT \"班级平均数\",",LEFT(@a2,LENGTH(@a)-1)," FROM(",@b2,")tb2 GROUP BY tb2.all;");
QUERY OK, 0 ROWS affected (0.00 sec)

mysql> SET @d=CONCAT(@b," UNION ALL ",@c);
QUERY OK, 0 ROWS affected (0.00 sec)

mysql>
mysql> PREPARE stmt1 FROM @d;
QUERY OK, 0 ROWS affected (0.00 sec)
Statement prepared

mysql> EXECUTE stmt1;
+---------------------------+--------+--------+--------+--------------+-----------+
| IFNULL(cname,'总成绩')    | 语文   | 数学   | 物理   | 平均成绩     | 总成绩    |
+---------------------------+--------+--------+--------+--------------+-----------+
| 张三                      |  74.00 |  83.00 |  93.00 |        83.33 |    250.00 |
| 李四                      |  74.00 |  84.00 |  94.00 |        84.00 |    252.00 |
| 班级平均数                |  74.00 |  83.50 |  93.50 |        83.67 |    251.00 |
+---------------------------+--------+--------+--------+--------------+-----------+
3 ROWS IN SET (0.00 sec)

mysql>




 **********************************************************************************************************


 SELECT t.`地区`,
COUNT(DISTINCT (case WHEN t.班级 =1 THEN t.学号 end)) AS'班级1',
COUNT(DISTINCT (case WHEN t.班级 =2 THEN t.学号 end)) AS'班级2',
COUNT(DISTINCT (case WHEN t.班级 =3 THEN t.学号 end)) AS'班级3',
COUNT(DISTINCT (case WHEN t.班级 =4 THEN t.学号 end)) AS'班级4'
FROM cm1_0625 t
where t.`地区`<>'' GROUP BY 1;


SELECT t.`地区`,
COUNT(DISTINCT IF (t.班级 =1 , t.学号 ,0)) AS'班级1',
COUNT(DISTINCT IF (t.班级 =2 , t.学号 ,0)) AS'班级2',
COUNT(DISTINCT IF (t.班级 =3 , t.学号 ,0)) AS'班级3',
COUNT(DISTINCT IF (t.班级 =4 , t.学号 ,0)) AS'班级4'
FROM cm1_0625 t
where t.`地区`<>'' GROUP BY 1;


*********************************************************************************************************************

                *****SQL优化******


1、join连接时的优化：当三个或多个以上的表进行join操作时，如果每个on使用相同的字段连接时只会产生一个mapreduce。
2、join连接时的优化：当多个表进行查询时，从左到右表的大小顺序应该是从小到大。原因：hive在对每行记录操作时会把其他表先缓存起来，直到扫描最后的表进行计算
3、在where字句中增加分区过滤器。
4、当可以使用left semi join 语法时不要使用inner join，前者效率更高。原因：对于左表中指定的一条记录，一旦在右表中找到立即停止扫描。
5、如果所有表中有一张表足够小，则可置于内存中，这样在和其他表进行连接的时候就能完成匹配，省略掉reduce过程。设置属性即可实现，set hive.auto.covert.join=true; 用户可以配置希望被优化的小表的大小 set hive.mapjoin.smalltable.size=2500000; 如果需要使用这两个配置可置入$HOME/.hiverc文件中。
6、同一种数据的多种处理：从一个数据源产生的多个数据聚合，无需每次聚合都需要重新扫描一次。
例如：insert overwrite table student select *　from employee; insert overwrite table person select * from employee;
可以优化成：from employee insert overwrite table student select * insert overwrite table person select *
7、limit调优：limit语句通常是执行整个语句后返回部分结果。set hive.limit.optimize.enable=true;
8、开启并发执行。某个job任务中可能包含众多的阶段，其中某些阶段没有依赖关系可以并发执行，开启并发执行后job任务可以更快的完成。设置属性：set hive.exec.parallel=true;
9、hive提供的严格模式，禁止3种情况下的查询模式。
a：当表为分区表时，where字句后没有分区字段和限制时，不允许执行。
b：当使用order by语句时，必须使用limit字段，因为order by 只会产生一个reduce任务。
c：限制笛卡尔积的查询。
10、合理的设置map和reduce数量。
11、jvm重用。可在hadoop的mapred-site.xml中设置jvm被重用的次数。 [2]