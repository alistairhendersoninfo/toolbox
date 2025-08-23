use anyhow::Result;
use clap::{Arg, Command};
use std::path::PathBuf;

mod database;
mod menu;
mod scanner;
mod ui;
mod models;
mod search;
mod display;

use database::Database;
use menu::MenuSystem;
use scanner::ScriptScanner;

const TOOLBOX_DIR: &str = "/opt/toolbox";
const DEFAULT_DB_PATH: &str = "~/.config/toolbox/menu.db";

#[tokio::main]
async fn main() -> Result<()> {
    let matches = Command::new("toolbox")
        .version("1.0.0")
        .author("Toolbox Team")
        .about("Advanced CLI menu system for toolbox scripts")
        .arg(
            Arg::new("scan")
                .long("scan")
                .short('s')
                .help("Scan and rebuild the database")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("path")
                .long("path")
                .short('p')
                .value_name("PATH")
                .help("Toolbox directory path")
                .default_value(TOOLBOX_DIR),
        )
        .arg(
            Arg::new("database")
                .long("database")
                .short('d')
                .value_name("DB_PATH")
                .help("Database file path")
                .default_value(DEFAULT_DB_PATH),
        )
        .arg(
            Arg::new("debug")
                .long("debug")
                .help("Enable debug mode")
                .action(clap::ArgAction::SetTrue),
        )
        .get_matches();

    let toolbox_path = PathBuf::from(matches.get_one::<String>("path").unwrap());
    let db_path = expand_tilde(matches.get_one::<String>("database").unwrap());
    let debug = matches.get_flag("debug");

    // Initialize database
    let mut database = Database::new(&db_path)?;
    database.initialize().await?;

    // Scan if requested or if database is empty
    if matches.get_flag("scan") || database.is_empty().await? {
        println!("🔍 Scanning toolbox directory...");
        let scanner = ScriptScanner::new(toolbox_path.clone());
        let scripts = scanner.scan().await?;
        
        println!("📝 Updating database with {} scripts...", scripts.len());
        database.update_scripts(scripts).await?;
        println!("✅ Database updated successfully!");
    }

    // Start the menu system
    let mut menu_system = MenuSystem::new(database, toolbox_path, debug);
    menu_system.run().await?;

    Ok(())
}

fn expand_tilde(path: &str) -> PathBuf {
    if path.starts_with("~/") {
        if let Some(home) = dirs::home_dir() {
            return home.join(&path[2..]);
        }
    }
    PathBuf::from(path)
}