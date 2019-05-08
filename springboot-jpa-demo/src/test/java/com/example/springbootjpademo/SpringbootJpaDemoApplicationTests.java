package com.example.springbootjpademo;

import com.example.springbootjpademo.entity.User;
import com.example.springbootjpademo.repository.UserRepository;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;


@RunWith(SpringRunner.class)
@SpringBootTest
public class SpringbootJpaDemoApplicationTests {

    @Autowired
    private UserRepository userRepository;

    @Test
    public void contextLoads() {
        System.out.println(userRepository.findAll().toString());
    }

    @Before
    public void add() {
        userRepository.save(new User("英雄联盟", "lol"));
    }

    //修改操作
    @After
    public void update() {
//        ifPresent 如果存在值，则使用值调用指定的使用者，否则不执行任何操作。
        userRepository.findById(1L).ifPresent(user -> {
            user.setName("xiugaihou");
            userRepository.save(user);
            System.out.println(user.toString());
        });
    }

    //删除
    @After
    public void del() {
        userRepository.findById(2L).ifPresent(user -> userRepository.delete(user));
    }
}
