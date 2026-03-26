package com.example.demo.controller;

import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;

@RestController
@RequestMapping("/api")
public class HelloController {

    private final List<Map<String, String>> messages = new ArrayList<>();

    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of(
            "status", "UP",
            "timestamp", LocalDateTime.now().toString(),
            "javaVersion", System.getProperty("java.version"),
            "osName", System.getProperty("os.name"),
            "freeMemory", Runtime.getRuntime().freeMemory() / 1024 / 1024 + "MB",
            "totalMemory", Runtime.getRuntime().totalMemory() / 1024 / 1024 + "MB"
        );
    }

    @GetMapping("/hello")
    public Map<String, String> hello(@RequestParam(defaultValue = "World") String name) {
        return Map.of(
            "message", "Hello, " + name + "!",
            "timestamp", LocalDateTime.now().toString()
        );
    }

    @PostMapping("/messages")
    public Map<String, String> addMessage(@RequestBody Map<String, String> body) {
        String content = body.getOrDefault("content", "");
        Map<String, String> msg = Map.of(
            "content", content,
            "createdAt", LocalDateTime.now().toString()
        );
        messages.add(msg);
        return msg;
    }

    @GetMapping("/messages")
    public List<Map<String, String>> getMessages() {
        return messages;
    }
}
