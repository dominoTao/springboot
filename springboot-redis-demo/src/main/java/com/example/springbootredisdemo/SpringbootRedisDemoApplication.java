package com.example.springbootredisdemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

//开启缓存
@EnableCaching
@SpringBootApplication
public class SpringbootRedisDemoApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringbootRedisDemoApplication.class, args);
	}
}
