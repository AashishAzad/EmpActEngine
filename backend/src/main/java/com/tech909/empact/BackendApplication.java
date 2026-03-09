package com.tech909.empact;

import com.google.common.base.Strings;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.event.ApplicationStartedEvent;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.scheduling.annotation.EnableScheduling;

import javax.sql.DataSource;

/**
 * Employee Activity Management System
 * 909 Technologies
 *
 * Architecture: Clean Layered Architecture
 * Controller → Service → Repository → Entity → PostgreSQL
 *
 * Features:
 * - JWT Authentication + RBAC (EMPLOYEE / MANAGER / ADMIN)
 * - Attendance tracking with geo-location
 * - Leave management with balance tracking
 * - Payroll & payslip generation
 * - In-app notifications via WebSocket (STOMP)
 * - Letter/document request management
 * - Automated cron jobs (attendance reminder, leave reset, cleanup)
 *
 * Database: PostgreSQL (viewable in pgAdmin4)
 * Port: 8080 (http://localhost:8080/api/v1)
 */
@SpringBootApplication
@EnableScheduling
public class BackendApplication {

    @Autowired
    private Environment environment;

    public static void main(String[] args) {
        SpringApplication.run(BackendApplication.class, args);
    }

    /**
     * Jmix requires these two DataSource beans to connect to the database.
     * They read from 'main.datasource.*' in application.properties.
     * DO NOT remove these — without them Jmix throws DataSource not found.
     */
    @Bean
    @Primary
    @ConfigurationProperties("main.datasource")
    DataSourceProperties dataSourceProperties() {
        return new DataSourceProperties();
    }

    @Bean
    @Primary
    @ConfigurationProperties("main.datasource.hikari")
    DataSource dataSource(final DataSourceProperties dataSourceProperties) {
        return dataSourceProperties.initializeDataSourceBuilder().build();
    }

    /**
     * Prints startup info to the console once the application is ready.
     */
    @EventListener
    public void onApplicationStarted(final ApplicationStartedEvent event) {
        String port = environment.getProperty("local.server.port");
        String contextPath = Strings.nullToEmpty(
                environment.getProperty("server.servlet.context-path"));

        LoggerFactory.getLogger(BackendApplication.class)
                .info("Application started at http://localhost:{}{}", port, contextPath);

        System.out.println("\n" +
                "╔══════════════════════════════════════════════════════════╗\n" +
                "║                                                          ║\n" +
                "║   🚀 Employee Activity Management System - Backend       ║\n" +
                "║   909 Technologies                                       ║\n" +
                "║                                                          ║\n" +
                "║   🌐 Server:    http://localhost:8080                    ║\n" +
                "║   📚 API Base:  http://localhost:8080/api/v1             ║\n" +
                "║   🔌 WebSocket: ws://localhost:8080/api/v1/ws            ║\n" +
                "║   🗄  Database: PostgreSQL (check pgAdmin4)              ║\n" +
                "║                                                          ║\n" +
                "║   Default Credentials:                                   ║\n" +
                "║   Admin:    ADM001 / password123                         ║\n" +
                "║   Manager:  MGR001 / password123                         ║\n" +
                "║   Employee: EMP001 / password123                         ║\n" +
                "║                                                          ║\n" +
                "╚══════════════════════════════════════════════════════════╝\n");
    }
}