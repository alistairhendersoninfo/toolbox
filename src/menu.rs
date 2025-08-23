use anyhow::Result;
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyModifiers};
use std::path::PathBuf;
use std::time::{Duration, Instant};

use crate::database::Database;
use crate::models::{MenuCategory, MenuItem, MenuState, Script};
use crate::search::SearchEngine;
use crate::ui::MenuUI;
use crate::display::ScriptExecutor;

pub struct MenuSystem {
    database: Database,
    toolbox_path: PathBuf,
    state: MenuState,
    ui: MenuUI,
    search_engine: SearchEngine,
    executor: ScriptExecutor,
    debug: bool,
}

impl MenuSystem {
    pub fn new(database: Database, toolbox_path: PathBuf, debug: bool) -> Self {
        Self {
            database,
            toolbox_path: toolbox_path.clone(),
            state: MenuState::default(),
            ui: MenuUI::new(),
            search_engine: SearchEngine::new(),
            executor: ScriptExecutor::new(toolbox_path),
            debug,
        }
    }

    pub async fn run(&mut self) -> Result<()> {
        self.ui.initialize()?;

        loop {
            // Update menu items based on current state
            if !self.state.search_mode {
                self.update_menu_items().await?;
            }

            // Render the current menu
            self.ui.render(&self.state)?;

            // Handle user input
            if let Ok(true) = event::poll(Duration::from_millis(100)) {
                if let Ok(Event::Key(key_event)) = event::read() {
                    if self.handle_key_event(key_event).await? {
                        break; // Exit requested
                    }
                }
            }
        }

        self.ui.cleanup()?;
        Ok(())
    }

    async fn handle_key_event(&mut self, key_event: KeyEvent) -> Result<bool> {
        match key_event.code {
            // Navigation shortcuts
            KeyCode::Char('x') | KeyCode::Char('X') => {
                if self.state.search_mode {
                    self.exit_search_mode().await?;
                } else {
                    self.go_back().await?;
                }
            }
            KeyCode::Char('h') | KeyCode::Char('H') => {
                self.go_home().await?;
            }
            KeyCode::Char('s') | KeyCode::Char('S') => {
                if !self.state.search_mode {
                    self.enter_search_mode().await?;
                }
            }
            KeyCode::Char('q') | KeyCode::Char('Q') => {
                if key_event.modifiers.contains(KeyModifiers::CONTROL) {
                    return Ok(true); // Exit
                }
            }
            KeyCode::Esc => {
                if self.state.search_mode {
                    self.exit_search_mode().await?;
                } else {
                    return Ok(true); // Exit
                }
            }

            // Menu navigation
            KeyCode::Up | KeyCode::Char('k') => {
                self.move_selection(-1);
            }
            KeyCode::Down | KeyCode::Char('j') => {
                self.move_selection(1);
            }
            KeyCode::PageUp => {
                self.move_selection(-10);
            }
            KeyCode::PageDown => {
                self.move_selection(10);
            }
            KeyCode::Home => {
                self.state.selected_index = 0;
            }
            KeyCode::End => {
                if self.state.search_mode {
                    if !self.state.filtered_items.is_empty() {
                        self.state.selected_index = self.state.filtered_items.len() - 1;
                    }
                } else {
                    // Will be set by update_menu_items
                }
            }

            // Selection and execution
            KeyCode::Enter => {
                self.execute_selected_item().await?;
            }

            // Number selection (1-9, 0)
            KeyCode::Char(c) if c.is_ascii_digit() => {
                let num = if c == '0' { 10 } else { c.to_digit(10).unwrap() as usize };
                if num > 0 {
                    self.select_by_number(num - 1).await?;
                }
            }

            // Search mode input
            KeyCode::Char(c) if self.state.search_mode => {
                self.state.search_query.push(c);
                self.update_search_results().await?;
            }
            KeyCode::Backspace if self.state.search_mode => {
                self.state.search_query.pop();
                self.update_search_results().await?;
            }

            // Help
            KeyCode::F(1) | KeyCode::Char('?') => {
                self.show_help().await?;
            }

            _ => {}
        }

        Ok(false)
    }

    async fn update_menu_items(&mut self) -> Result<()> {
        if self.state.current_category == "root" {
            // Show main categories
            let categories = self.database.get_all_categories().await?;
            let mut items = Vec::new();

            // Add TopLevel scripts first if they exist
            if categories.contains(&"TopLevel".to_string()) {
                let scripts = self.database.get_scripts_by_category("TopLevel").await?;
                for script in scripts {
                    items.push(MenuItem::Script(script));
                }
                if !items.is_empty() {
                    items.push(MenuItem::Separator("Categories".to_string()));
                }
            }

            // Add other categories
            for category in categories {
                if category != "TopLevel" {
                    let scripts = self.database.get_scripts_by_category(&category).await?;
                    if !scripts.is_empty() {
                        let mut menu_category = MenuCategory::new(category.clone(), PathBuf::from(&category));
                        menu_category.scripts = scripts;
                        items.push(MenuItem::Category(menu_category));
                    }
                }
            }

            // Add navigation items
            items.push(MenuItem::Search);
            items.push(MenuItem::Exit);

            self.state.filtered_items = items;
        } else {
            // Show scripts in current category
            let scripts = self.database.get_scripts_by_category(&self.state.current_category).await?;
            let mut items = Vec::new();

            // Group by separator
            let mut current_separator = None;
            for script in scripts {
                if let Some(ref separator) = script.separator {
                    if current_separator.as_ref() != Some(separator) {
                        items.push(MenuItem::Separator(separator.clone()));
                        current_separator = Some(separator.clone());
                    }
                }
                items.push(MenuItem::Script(script));
            }

            // Add navigation items
            items.push(MenuItem::Back);
            items.push(MenuItem::Home);
            items.push(MenuItem::Search);

            self.state.filtered_items = items;
        }

        // Ensure selected index is valid
        if self.state.selected_index >= self.state.filtered_items.len() && !self.state.filtered_items.is_empty() {
            self.state.selected_index = self.state.filtered_items.len() - 1;
        }

        Ok(())
    }

    async fn enter_search_mode(&mut self) -> Result<()> {
        self.state.search_mode = true;
        self.state.search_query.clear();
        self.state.selected_index = 0;
        self.update_search_results().await?;
        Ok(())
    }

    async fn exit_search_mode(&mut self) -> Result<()> {
        self.state.search_mode = false;
        self.state.search_query.clear();
        self.state.selected_index = 0;
        Ok(())
    }

    async fn update_search_results(&mut self) -> Result<()> {
        if self.state.search_query.is_empty() {
            self.state.filtered_items.clear();
            return Ok(());
        }

        let scripts = self.database.search_scripts(&self.state.search_query).await?;
        let mut items = Vec::new();

        // Use fuzzy matching for better results
        let fuzzy_results = self.search_engine.fuzzy_search(&scripts, &self.state.search_query);

        for script in fuzzy_results {
            items.push(MenuItem::Script(script));
        }

        // Add navigation
        items.push(MenuItem::Back);

        self.state.filtered_items = items;
        self.state.selected_index = 0;

        Ok(())
    }

    async fn execute_selected_item(&mut self) -> Result<()> {
        if self.state.filtered_items.is_empty() {
            return Ok(());
        }

        let selected_item = &self.state.filtered_items[self.state.selected_index].clone();

        match selected_item {
            MenuItem::Script(script) => {
                self.execute_script(script).await?;
            }
            MenuItem::Category(category) => {
                self.enter_category(&category.name).await?;
            }
            MenuItem::Back => {
                self.go_back().await?;
            }
            MenuItem::Home => {
                self.go_home().await?;
            }
            MenuItem::Search => {
                self.enter_search_mode().await?;
            }
            MenuItem::Exit => {
                return Ok(()); // This will be handled by the caller
            }
            MenuItem::Separator(_) => {
                // Do nothing for separators
            }
        }

        Ok(())
    }

    async fn execute_script(&mut self, script: &Script) -> Result<()> {
        self.ui.cleanup()?;

        let start_time = Instant::now();
        let exit_code = self.executor.execute(script).await?;
        let duration = start_time.elapsed();

        // Record execution in database
        if let Some(script_id) = script.id {
            self.database.record_execution(
                script_id,
                exit_code,
                duration.as_millis() as u64,
                None, // TODO: Add parameter support
            ).await?;
        }

        // Wait for user input before returning to menu
        println!("\nPress Enter to return to menu...");
        let mut input = String::new();
        std::io::stdin().read_line(&mut input)?;

        self.ui.initialize()?;
        Ok(())
    }

    async fn select_by_number(&mut self, index: usize) -> Result<()> {
        if index < self.state.filtered_items.len() {
            self.state.selected_index = index;
            self.execute_selected_item().await?;
        }
        Ok(())
    }

    async fn enter_category(&mut self, category: &str) -> Result<()> {
        self.state.breadcrumb.push(category.to_string());
        self.state.current_category = category.to_string();
        self.state.selected_index = 0;
        Ok(())
    }

    async fn go_back(&mut self) -> Result<()> {
        if self.state.breadcrumb.len() > 1 {
            self.state.breadcrumb.pop();
            if let Some(parent) = self.state.breadcrumb.last() {
                self.state.current_category = if parent == "Home" {
                    "root".to_string()
                } else {
                    parent.clone()
                };
            }
        }
        self.state.selected_index = 0;
        Ok(())
    }

    async fn go_home(&mut self) -> Result<()> {
        self.state.breadcrumb = vec!["Home".to_string()];
        self.state.current_category = "root".to_string();
        self.state.selected_index = 0;
        self.state.search_mode = false;
        self.state.search_query.clear();
        Ok(())
    }

    fn move_selection(&mut self, delta: i32) {
        if self.state.filtered_items.is_empty() {
            return;
        }

        let current = self.state.selected_index as i32;
        let max = self.state.filtered_items.len() as i32 - 1;
        
        let new_index = (current + delta).max(0).min(max) as usize;
        
        // Skip separators
        if let Some(MenuItem::Separator(_)) = self.state.filtered_items.get(new_index) {
            if delta > 0 && new_index < self.state.filtered_items.len() - 1 {
                self.state.selected_index = new_index + 1;
            } else if delta < 0 && new_index > 0 {
                self.state.selected_index = new_index - 1;
            }
        } else {
            self.state.selected_index = new_index;
        }
    }

    async fn show_help(&mut self) -> Result<()> {
        self.ui.show_help_dialog()?;
        Ok(())
    }
}