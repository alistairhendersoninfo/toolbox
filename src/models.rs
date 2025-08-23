use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Script {
    pub id: Option<i64>,
    pub name: String,
    pub path: PathBuf,
    pub category: String,
    pub menu_name: Option<String>,          // #MN
    pub description: Option<String>,        // #MD
    pub detailed_description: Option<String>, // #MDD
    pub integration: Option<String>,        // #MI
    pub info_url: Option<String>,          // #INFO
    pub icon: Option<String>,              // #MICON
    pub color: Option<String>,             // #MCOLOR
    pub order: Option<i32>,                // #MORDER
    pub is_default: bool,                  // #MDEFAULT
    pub separator: Option<String>,         // #MSEPARATOR
    pub tags: Vec<String>,                 // #MTAGS
    pub author: Option<String>,            // #MAUTHOR
    pub parameters: Option<String>,        // JSON parameters block
    pub dependency_available: bool,        // Whether MI dependency is available
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScriptParameter {
    pub name: String,
    pub param_type: ParameterType,
    pub label: String,
    pub description: Option<String>,
    pub default_value: Option<String>,
    pub required: bool,
    pub options: Option<Vec<ParameterOption>>,
    pub validation: Option<ParameterValidation>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ParameterType {
    Text,
    Number,
    Password,
    Select,
    Radio,
    Checkbox,
    File,
    Directory,
    Boolean,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParameterOption {
    pub value: String,
    pub label: String,
    pub description: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParameterValidation {
    pub min_length: Option<usize>,
    pub max_length: Option<usize>,
    pub pattern: Option<String>,
    pub pattern_description: Option<String>,
    pub min_value: Option<f64>,
    pub max_value: Option<f64>,
}

#[derive(Debug, Clone)]
pub struct MenuCategory {
    pub name: String,
    pub path: PathBuf,
    pub scripts: Vec<Script>,
    pub subcategories: Vec<MenuCategory>,
    pub icon: String,
    pub order: i32,
}

#[derive(Debug, Clone)]
pub struct MenuState {
    pub current_category: String,
    pub breadcrumb: Vec<String>,
    pub selected_index: usize,
    pub search_mode: bool,
    pub search_query: String,
    pub filtered_items: Vec<MenuItem>,
}

#[derive(Debug, Clone)]
pub enum MenuItem {
    Category(MenuCategory),
    Script(Script),
    Separator(String),
    Back,
    Home,
    Search,
    Exit,
}

impl Default for MenuState {
    fn default() -> Self {
        Self {
            current_category: "root".to_string(),
            breadcrumb: vec!["Home".to_string()],
            selected_index: 0,
            search_mode: false,
            search_query: String::new(),
            filtered_items: Vec::new(),
        }
    }
}

impl Script {
    pub fn new(name: String, path: PathBuf, category: String) -> Self {
        let now = chrono::Utc::now();
        Self {
            id: None,
            name,
            path,
            category,
            menu_name: None,
            description: None,
            detailed_description: None,
            integration: None,
            info_url: None,
            icon: None,
            color: None,
            order: None,
            is_default: false,
            separator: None,
            tags: Vec::new(),
            author: None,
            parameters: None,
            dependency_available: true,
            created_at: now,
            updated_at: now,
        }
    }

    pub fn display_name(&self) -> &str {
        self.menu_name.as_ref().unwrap_or(&self.name)
    }

    pub fn display_icon(&self) -> &str {
        self.icon.as_deref().unwrap_or("📝")
    }

    pub fn display_description(&self) -> &str {
        self.description.as_deref().unwrap_or("No description")
    }

    pub fn has_parameters(&self) -> bool {
        self.parameters.is_some() && !self.parameters.as_ref().unwrap().trim().is_empty()
    }

    pub fn parse_parameters(&self) -> Result<Vec<ScriptParameter>, serde_json::Error> {
        if let Some(params_json) = &self.parameters {
            serde_json::from_str(params_json)
        } else {
            Ok(Vec::new())
        }
    }
}

impl MenuCategory {
    pub fn new(name: String, path: PathBuf) -> Self {
        Self {
            name,
            path,
            scripts: Vec::new(),
            subcategories: Vec::new(),
            icon: "📁".to_string(),
            order: 999,
        }
    }

    pub fn total_items(&self) -> usize {
        self.scripts.len() + self.subcategories.len()
    }

    pub fn is_empty(&self) -> bool {
        self.scripts.is_empty() && self.subcategories.is_empty()
    }
}