package com.estudiez.backend.service;

import com.estudiez.backend.entity.NewsPost;
import com.estudiez.backend.exception.ResourceNotFoundException;
import com.estudiez.backend.repository.NewsPostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class NewsService {

    private final NewsPostRepository newsRepo;

    public List<NewsPost> findAll() { return newsRepo.findAll(); }

    public List<NewsPost> findPublished() {
        return newsRepo.findAll().stream()
                .filter(n -> "PUBLISHED".equals(n.getStatus()))
                .toList();
    }

    public NewsPost findById(Integer id) {
        return newsRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("NewsPost", id));
    }

    public NewsPost create(NewsPost post) {
        if ("PUBLISHED".equals(post.getStatus()) && post.getPublishedAt() == null) {
            post.setPublishedAt(LocalDateTime.now());
        }
        return newsRepo.save(post);
    }

    public NewsPost update(Integer id, NewsPost updated) {
        NewsPost post = findById(id);
        post.setTitle(updated.getTitle());
        post.setContent(updated.getContent());
        post.setCategory(updated.getCategory());
        post.setCoverImageUrl(updated.getCoverImageUrl());
        post.setStatus(updated.getStatus());
        if ("PUBLISHED".equals(updated.getStatus()) && post.getPublishedAt() == null) {
            post.setPublishedAt(LocalDateTime.now());
        }
        return newsRepo.save(post);
    }

    public void delete(Integer id) {
        if (!newsRepo.existsById(id)) throw new ResourceNotFoundException("NewsPost", id);
        newsRepo.deleteById(id);
    }
}
