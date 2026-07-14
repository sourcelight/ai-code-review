package com.example.starter.controller;

import com.example.starter.dto.MessageResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ApiController {

    @GetMapping("/hello")
    public ResponseEntity<MessageResponse> hello() {
        return ResponseEntity.ok(new MessageResponse("Hello authenticated user"));
    }

    @GetMapping("/public")
    public ResponseEntity<MessageResponse> publicEndpoint() {
        return ResponseEntity.ok(new MessageResponse("Public endpoint"));
    }
}
