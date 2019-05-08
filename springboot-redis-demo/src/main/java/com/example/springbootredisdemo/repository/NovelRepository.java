package com.example.springbootredisdemo.repository;

import com.example.springbootredisdemo.entity.Novel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface NovelRepository extends JpaRepository<Novel,Long> {

}