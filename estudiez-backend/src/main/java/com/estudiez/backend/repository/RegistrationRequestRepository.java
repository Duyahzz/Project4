package com.estudiez.backend.repository;

import com.estudiez.backend.entity.RegistrationRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface RegistrationRequestRepository extends JpaRepository<RegistrationRequest, Integer> {
    List<RegistrationRequest> findByStatus(String status);
    List<RegistrationRequest> findByEmail(String email);
}
