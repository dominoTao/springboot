package com.example.springbootredisdemo.service;

import com.example.springbootredisdemo.entity.Novel;
import org.springframework.data.domain.Page;

public interface NovelService {

    Page<Novel> findAll(Integer pageNum, Integer pageSize);
}
