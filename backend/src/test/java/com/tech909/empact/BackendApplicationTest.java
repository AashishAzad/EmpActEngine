package com.tech909.empact;

import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.event.ApplicationStartedEvent;
import org.springframework.core.env.Environment;
import org.springframework.test.util.ReflectionTestUtils;

import javax.sql.DataSource;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class BackendApplicationTest {

    @Test
    void dataSourceProperties_createsPrimaryPropertiesBean() {
        BackendApplication application = new BackendApplication();

        DataSourceProperties properties = application.dataSourceProperties();

        assertThat(properties).isNotNull();
    }

    @Test
    void dataSource_buildsDataSourceFromProperties() {
        BackendApplication application = new BackendApplication();
        DataSourceProperties properties = new DataSourceProperties();
        properties.setUrl("jdbc:postgresql://localhost:5432/empact_db");
        properties.setUsername("postgres");
        properties.setPassword("postgres");
        properties.setDriverClassName("org.postgresql.Driver");

        DataSource dataSource = application.dataSource(properties);

        assertThat(dataSource).isNotNull();
    }

    @Test
    void onApplicationStarted_usesEnvironmentWithoutThrowing() {
        BackendApplication application = new BackendApplication();
        Environment environment = mock(Environment.class);
        ApplicationStartedEvent event = mock(ApplicationStartedEvent.class);

        when(environment.getProperty("local.server.port")).thenReturn("8080");
        when(environment.getProperty("server.servlet.context-path")).thenReturn("/api/v1");
        ReflectionTestUtils.setField(application, "environment", environment);

        application.onApplicationStarted(event);

        assertThat(ReflectionTestUtils.getField(application, "environment")).isEqualTo(environment);
    }
}
