use anyhow::{Context, Result};
use rusqlite::{params, Connection, Row};
use std::path::Path;
use tokio::task;

use crate::models::Script;

pub struct Database {
    db_path: std::path::PathBuf,
}

impl Database {
    pub fn new(db_path: &Path) -> Result<Self> {
        // Ensure parent directory exists
        if let Some(parent) = db_path.parent() {
            std::fs::create_dir_all(parent)
                .with_context(|| format!("Failed to create database directory: {}", parent.display()))?;
        }

        Ok(Self {
            db_path: db_path.to_path_buf(),
        })
    }

    pub async fn initialize(&self) -> Result<()> {
        let db_path = self.db_path.clone();
        
        task::spawn_blocking(move || -> Result<()> {
            let conn = Connection::open(&db_path)
                .with_context(|| format!("Failed to open database: {}", db_path.display()))?;

            conn.execute(
                r#"
                CREATE TABLE IF NOT EXISTS scripts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    path TEXT NOT NULL UNIQUE,
                    category TEXT NOT NULL,
                    menu_name TEXT,
                    description TEXT,
                    detailed_description TEXT,
                    integration TEXT,
                    info_url TEXT,
                    icon TEXT,
                    color TEXT,
                    order_num INTEGER,
                    is_default BOOLEAN DEFAULT FALSE,
                    separator TEXT,
                    tags TEXT, -- JSON array
                    author TEXT,
                    parameters TEXT, -- JSON object
                    dependency_available BOOLEAN DEFAULT TRUE,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
                "#,
                [],
            )?;

            // Create indexes for better performance
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_scripts_category ON scripts(category)",
                [],
            )?;

            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_scripts_order ON scripts(order_num)",
                [],
            )?;

            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_scripts_name ON scripts(name)",
                [],
            )?;

            // Create table for script execution history
            conn.execute(
                r#"
                CREATE TABLE IF NOT EXISTS execution_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    script_id INTEGER NOT NULL,
                    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    exit_code INTEGER,
                    duration_ms INTEGER,
                    parameters TEXT, -- JSON object
                    FOREIGN KEY (script_id) REFERENCES scripts (id)
                )
                "#,
                [],
            )?;

            // Create table for user preferences
            conn.execute(
                r#"
                CREATE TABLE IF NOT EXISTS user_preferences (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
                "#,
                [],
            )?;

            Ok(())
        }).await??;

        Ok(())
    }

    pub async fn is_empty(&self) -> Result<bool> {
        let db_path = self.db_path.clone();
        
        let count = task::spawn_blocking(move || -> Result<i64> {
            let conn = Connection::open(&db_path)?;
            let count: i64 = conn.query_row(
                "SELECT COUNT(*) FROM scripts",
                [],
                |row| row.get(0),
            )?;
            Ok(count)
        }).await??;

        Ok(count == 0)
    }

    pub async fn update_scripts(&mut self, scripts: Vec<Script>) -> Result<()> {
        let db_path = self.db_path.clone();
        
        task::spawn_blocking(move || -> Result<()> {
            let mut conn = Connection::open(&db_path)?;
            let tx = conn.transaction()?;

            // Clear existing scripts
            tx.execute("DELETE FROM scripts", [])?;

            // Insert new scripts
            for script in scripts {
                let tags_json = serde_json::to_string(&script.tags)?;
                
                tx.execute(
                    r#"
                    INSERT INTO scripts (
                        name, path, category, menu_name, description, detailed_description,
                        integration, info_url, icon, color, order_num, is_default,
                        separator, tags, author, parameters, dependency_available, created_at, updated_at
                    ) VALUES (
                        ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16, ?17, ?18, ?19
                    )
                    "#,
                    params![
                        script.name,
                        script.path.to_string_lossy(),
                        script.category,
                        script.menu_name,
                        script.description,
                        script.detailed_description,
                        script.integration,
                        script.info_url,
                        script.icon,
                        script.color,
                        script.order,
                        script.is_default,
                        script.separator,
                        tags_json,
                        script.author,
                        script.parameters,
                        script.dependency_available,
                        script.created_at.to_rfc3339(),
                        script.updated_at.to_rfc3339(),
                    ],
                )?;
            }

            tx.commit()?;
            Ok(())
        }).await??;

        Ok(())
    }

    pub async fn get_scripts_by_category(&self, category: &str) -> Result<Vec<Script>> {
        let db_path = self.db_path.clone();
        let category = category.to_string();
        
        let scripts = task::spawn_blocking(move || -> Result<Vec<Script>> {
            let conn = Connection::open(&db_path)?;
            let mut stmt = conn.prepare(
                r#"
                SELECT id, name, path, category, menu_name, description, detailed_description,
                       integration, info_url, icon, color, order_num, is_default,
                       separator, tags, author, parameters, created_at, updated_at
                FROM scripts 
                WHERE category = ?1 
                ORDER BY order_num ASC, name ASC
                "#,
            )?;

            let script_iter = stmt.query_map([&category], |row| {
                Ok(row_to_script(row)?)
            })?;

            let mut scripts = Vec::new();
            for script in script_iter {
                scripts.push(script?);
            }

            Ok(scripts)
        }).await??;

        Ok(scripts)
    }

    pub async fn get_all_categories(&self) -> Result<Vec<String>> {
        let db_path = self.db_path.clone();
        
        let categories = task::spawn_blocking(move || -> Result<Vec<String>> {
            let conn = Connection::open(&db_path)?;
            let mut stmt = conn.prepare(
                "SELECT DISTINCT category FROM scripts ORDER BY category"
            )?;

            let category_iter = stmt.query_map([], |row| {
                Ok(row.get::<_, String>(0)?)
            })?;

            let mut categories = Vec::new();
            for category in category_iter {
                categories.push(category?);
            }

            Ok(categories)
        }).await??;

        Ok(categories)
    }

    pub async fn search_scripts(&self, query: &str) -> Result<Vec<Script>> {
        let db_path = self.db_path.clone();
        let query = format!("%{}%", query.to_lowercase());
        
        let scripts = task::spawn_blocking(move || -> Result<Vec<Script>> {
            let conn = Connection::open(&db_path)?;
            let mut stmt = conn.prepare(
                r#"
                SELECT id, name, path, category, menu_name, description, detailed_description,
                       integration, info_url, icon, color, order_num, is_default,
                       separator, tags, author, parameters, dependency_available, created_at, updated_at
                FROM scripts 
                WHERE LOWER(name) LIKE ?1 
                   OR LOWER(menu_name) LIKE ?1 
                   OR LOWER(description) LIKE ?1 
                   OR LOWER(detailed_description) LIKE ?1
                   OR LOWER(tags) LIKE ?1
                ORDER BY 
                    CASE 
                        WHEN LOWER(name) LIKE ?1 THEN 1
                        WHEN LOWER(menu_name) LIKE ?1 THEN 2
                        WHEN LOWER(description) LIKE ?1 THEN 3
                        ELSE 4
                    END,
                    name ASC
                "#,
            )?;

            let script_iter = stmt.query_map([&query], |row| {
                Ok(row_to_script(row)?)
            })?;

            let mut scripts = Vec::new();
            for script in script_iter {
                scripts.push(script?);
            }

            Ok(scripts)
        }).await??;

        Ok(scripts)
    }

    pub async fn get_script_by_path(&self, path: &str) -> Result<Option<Script>> {
        let db_path = self.db_path.clone();
        let path = path.to_string();
        
        let script = task::spawn_blocking(move || -> Result<Option<Script>> {
            let conn = Connection::open(&db_path)?;
            let mut stmt = conn.prepare(
                r#"
                SELECT id, name, path, category, menu_name, description, detailed_description,
                       integration, info_url, icon, color, order_num, is_default,
                       separator, tags, author, parameters, dependency_available, created_at, updated_at
                FROM scripts 
                WHERE path = ?1
                "#,
            )?;

            let mut script_iter = stmt.query_map([&path], |row| {
                Ok(row_to_script(row)?)
            })?;

            if let Some(script) = script_iter.next() {
                Ok(Some(script?))
            } else {
                Ok(None)
            }
        }).await??;

        Ok(script)
    }

    pub async fn record_execution(&self, script_id: i64, exit_code: i32, duration_ms: u64, parameters: Option<&str>) -> Result<()> {
        let db_path = self.db_path.clone();
        let parameters = parameters.map(|s| s.to_string());
        
        task::spawn_blocking(move || -> Result<()> {
            let conn = Connection::open(&db_path)?;
            conn.execute(
                "INSERT INTO execution_history (script_id, exit_code, duration_ms, parameters) VALUES (?1, ?2, ?3, ?4)",
                params![script_id, exit_code, duration_ms as i64, parameters],
            )?;
            Ok(())
        }).await??;

        Ok(())
    }
}

fn row_to_script(row: &Row) -> rusqlite::Result<Script> {
    let tags_json: String = row.get("tags")?;
    let tags: Vec<String> = serde_json::from_str(&tags_json).unwrap_or_default();
    
    let created_at_str: String = row.get("created_at")?;
    let updated_at_str: String = row.get("updated_at")?;
    
    let created_at = chrono::DateTime::parse_from_rfc3339(&created_at_str)
        .map(|dt| dt.with_timezone(&chrono::Utc))
        .unwrap_or_else(|_| chrono::Utc::now());
    
    let updated_at = chrono::DateTime::parse_from_rfc3339(&updated_at_str)
        .map(|dt| dt.with_timezone(&chrono::Utc))
        .unwrap_or_else(|_| chrono::Utc::now());

    Ok(Script {
        id: Some(row.get("id")?),
        name: row.get("name")?,
        path: std::path::PathBuf::from(row.get::<_, String>("path")?),
        category: row.get("category")?,
        menu_name: row.get("menu_name")?,
        description: row.get("description")?,
        detailed_description: row.get("detailed_description")?,
        integration: row.get("integration")?,
        info_url: row.get("info_url")?,
        icon: row.get("icon")?,
        color: row.get("color")?,
        order: row.get("order_num")?,
        is_default: row.get("is_default")?,
        separator: row.get("separator")?,
        tags,
        author: row.get("author")?,
        parameters: row.get("parameters")?,
        dependency_available: row.get("dependency_available")?,
        created_at,
        updated_at,
    })
}