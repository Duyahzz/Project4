package com.estudiez.backend.controller;

import com.estudiez.backend.entity.NewsPost;
import com.estudiez.backend.service.NewsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/news")
@RequiredArgsConstructor
public class NewsController {

    private final NewsService newsService;

    @GetMapping
    public List<NewsPost> getAll(@RequestParam(required = false) String status) {
        if ("PUBLISHED".equalsIgnoreCase(status)) return newsService.findPublished();
        return newsService.findAll();
    }

    @GetMapping("/{id}")
    public NewsPost getById(@PathVariable Integer id) { return newsService.findById(id); }

    @PostMapping
    public ResponseEntity<NewsPost> create(@RequestBody NewsPost post) {
        return ResponseEntity.status(HttpStatus.CREATED).body(newsService.create(post));
    }

    @PutMapping("/{id}")
    public NewsPost update(@PathVariable Integer id, @RequestBody NewsPost post) {
        return newsService.update(id, post);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        newsService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
