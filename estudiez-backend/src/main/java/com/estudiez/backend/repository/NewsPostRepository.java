package com.estudiez.backend.repository;
import com.estudiez.backend.entity.NewsPost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;
@Repository
public interface NewsPostRepository extends JpaRepository<NewsPost, Integer> {
    boolean existsBySlug(String slug);
}
