package com.example.springbootredisdemo;

import com.example.springbootredisdemo.service.NovelService;
import lombok.extern.slf4j.Slf4j;
import org.junit.FixMethodOrder;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.MethodSorters;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.test.context.junit4.SpringRunner;

import java.util.ArrayList;
import java.util.List;

//根据测试方法名字搞定执行顺序
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
@RunWith(SpringRunner.class)
@SpringBootTest
@Slf4j
public class SpringbootRedisDemoApplicationTests {

    @Autowired
    private NovelService novelService;

    @Autowired
    private RedisTemplate<String,Object> redisTemplate;

    private final static String KEY = "username";
    private final static String VALUE = "test";


    @Test
    public void AstringRedis(){
        redisTemplate.opsForValue().set(KEY,VALUE);
        log.info("string set存储:{}->{}",KEY,VALUE);
        redisTemplate.opsForValue().get(KEY);
        log.info("string 根据{}取出{}",KEY,VALUE);
    }

    @Test
    public void BlistRedis(){
        List<String> trap = new ArrayList<>();
        trap.add("张三");
        trap.add("张三");
        trap.add("张无忌");
        trap.add("新垣结衣");
        //循环向userlist左添加值
        trap.forEach(value->redisTemplate.opsForList().leftPush("userlist",value));
//        redisTemplate.opsForList().leftPushAll("userlist",trap);
        //向userlist右添加值
        redisTemplate.opsForList().rightPush("userlist","rightValue");
        //取出userlist的值
        log.info("userlist->{}",redisTemplate.opsForList().range("userlist",0,10));
    }

    @Test
    public void CsetRedis(){
        List<String> trap = new ArrayList<>();
        trap.add("张三");
        trap.add("里斯");
        trap.add("里斯");
        trap.add("张无忌");
        trap.add("新垣结衣");
        System.out.print(trap.toString());
        //循环向userlist左添加值
        trap.forEach(value->redisTemplate.opsForSet().add("userSet",value));
        log.info("取出userSet->{}",redisTemplate.opsForSet().members("userSet"));
    }

    @Test
    public void DlistRedisRemove(){
        redisTemplate.opsForList().remove("userlist",0,"张无忌");
    }


    @Test
    public void EsetRedisRemove(){
        redisTemplate.opsForSet().remove("userSet","张无忌");
    }

    //opsForHash()操作
    @Test
    public void FhashRedisAdd(){
        //添加
        redisTemplate.opsForHash().put("user","phone",10086);
        redisTemplate.opsForHash().put("user","address","Shanghai");
        redisTemplate.opsForHash().put("user","del","mubaba");
        redisTemplate.opsForHash().put("user","dada","达达");
        //修改
        redisTemplate.opsForHash().put("user","address","Beijing");
        //删除
        redisTemplate.opsForHash().delete("user","del","dada");
    }


}
