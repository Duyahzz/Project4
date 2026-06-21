package com.estudiez.backend.repository;
import com.estudiez.backend.entity.SchoolContact;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;
@Repository
public interface SchoolContactRepository extends JpaRepository<SchoolContact, Integer> {}
