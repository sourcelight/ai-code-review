package com.example.starter.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Business logic for the demo greeting endpoint.
 */
@Service
public class DemoService {

    private static final Logger log = LoggerFactory.getLogger(DemoService.class);
    private static final int GREETING_REPEAT = 3;

    /**
     * Builds a greeting message for the given name.
     *
     * @param name the caller-supplied name; blank/null falls back to a default
     * @return the greeting message
     */
    public String buildGreeting(String name) {
        log.debug("Building greeting message");

        String safeName = (name == null || name.isBlank()) ? "guest" : name.strip();

        StringBuilder greeting = new StringBuilder();
        for (int i = 0; i < GREETING_REPEAT; i++) {
            greeting.append("Hello ").append(safeName).append("! ");
        }
        return greeting.toString().strip();
    }
}
