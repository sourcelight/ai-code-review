package com.example.starter.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Demo endpoint used ONLY to exercise the AI code review workflow.
 * It intentionally contains several issues (security, architecture, best-practice)
 * so the reviewer produces findings, inline comments, and a blocking verdict.
 * Do not merge.
 */
@RestController
public class DemoController {

    // Issue: field injection instead of constructor injection (java-review)
    @Autowired
    private Environment env;

    // Issue: hardcoded secret in source (security-review) — fake value, for demo only
    private static final String API_KEY = "sk-demo-1234567890-not-a-real-key";

    @GetMapping("/api/demo/greet")
    public String greet(@RequestParam String name) {
        // Issue: business logic in the controller instead of a service (java-review)
        String result = "";
        for (int i = 0; i < 3; i++) {
            result = result + "Hello " + name + "! ";
        }

        // Issue: SQL built by string concatenation of user input (security-review, SQL injection)
        String query = "SELECT * FROM users WHERE name = '" + name + "'";

        // Issue: logging sensitive data + System.out instead of a logger (security/logging)
        System.out.println("Running query: " + query + " with key " + API_KEY);

        return result + query;
    }
}
