package com.example.springbootredisdemo.service.impl;

import com.example.springbootredisdemo.entity.Novel;
import com.example.springbootredisdemo.repository.NovelRepository;
import com.example.springbootredisdemo.service.NovelService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

@Service
public class NovelServiceImpl implements NovelService {

    private final NovelRepository novelRepository;

    @Autowired
    public NovelServiceImpl(NovelRepository fictionRepository) {
        this.novelRepository = fictionRepository;
    }


    @Cacheable(key = "#p0+#p1",value = "fictionAll")
    @Override
    public Page<Novel> findAll(Integer pageNum, Integer pageSize) {
        return novelRepository.findAll(PageRequest.of(pageNum,pageSize));

    }


}
