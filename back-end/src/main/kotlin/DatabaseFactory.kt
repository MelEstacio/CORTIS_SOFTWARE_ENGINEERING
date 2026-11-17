package com

import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import io.ktor.server.application.*
import org.jetbrains.exposed.v1.jdbc.Database

fun Application.configureDatabase() {
    val config = HikariConfig().apply {
        jdbcUrl = System.getenv("DB_URL") ?: error("Variável DB_URL não definida")
        username = System.getenv("DB_USER") ?: error("Variável DB_USER não definida")
        password = System.getenv("DB_PASSWORD") ?: error("Variável DB_PASSWORD não definida")
        maximumPoolSize = 5
    }
    val dataSource = HikariDataSource(config)

    // Teste: pega uma conexão emprestada do pool e faz uma pergunta simples
    dataSource.connection.use { conn ->
        val rs = conn.createStatement().executeQuery("SELECT version()")
        rs.next()
        log.info("Conectado ao PostgreSQL: ${rs.getString(1)}")
    }

    Database.connect(dataSource)
}