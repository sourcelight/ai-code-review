package com.example.starter.controller;

import com.example.starter.dto.MessageResponse;
import com.example.starter.service.DemoService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Demo endpoint used to exercise the AI code review workflow.
 * Thin controller: delegates all logic to {@link DemoService} and returns a DTO.
 */
@RestController
@RequestMapping("/api/demo")
public class DemoController {

    private final DemoService demoService;

    public DemoController(DemoService demoService) {
        this.demoService = demoService;
    }

    @GetMapping("/greet")
    public ResponseEntity<MessageResponse> greet(@RequestParam String name) {
        return ResponseEntity.ok(new MessageResponse(demoService.buildGreeting(name)));
    }
}
