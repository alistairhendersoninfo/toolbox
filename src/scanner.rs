use anyhow::{Context, Result};
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

use crate::models::Script;

pub struct ScriptScanner {
    toolbox_path: PathBuf,
    metadata_patterns: HashMap<String, Regex>,
}

impl ScriptScanner {
    pub fn new(toolbox_path: PathBuf) -> Self {
        let mut metadata_patterns = HashMap::new();
        
        // Compile regex patterns for metadata extraction
        metadata_patterns.insert("MN".to_string(), Regex::new(r"^#MN\s+(.+)$").unwrap());
        metadata_patterns.insert("MD".to_string(), Regex::new(r"^#MD\s+(.+)$").unwrap());
        metadata_patterns.insert("MDD".to_string(), Regex::new(r"^#MDD\s+(.+)$").unwrap());
        metadata_patterns.insert("MI".to_string(), Regex::new(r"^#MI\s+(.+)$").unwrap());
        metadata_patterns.insert("INFO".to_string(), Regex::new(r"^#INFO\s+(.+)$").unwrap());
        metadata_patterns.insert("MICON".to_string(), Regex::new(r"^#MICON\s+(.+)$").unwrap());
        metadata_patterns.insert("MCOLOR".to_string(), Regex::new(r"^#MCOLOR\s+(.+)$").unwrap());
        metadata_patterns.insert("MORDER".to_string(), Regex::new(r"^#MORDER\s+(\d+)$").unwrap());
        metadata_patterns.insert("MDEFAULT".to_string(), Regex::new(r"^#MDEFAULT\s+(true|false)$").unwrap());
        metadata_patterns.insert("MSEPARATOR".to_string(), Regex::new(r"^#MSEPARATOR\s+(.+)$").unwrap());
        metadata_patterns.insert("MTAGS".to_string(), Regex::new(r"^#MTAGS\s+(.+)$").unwrap());
        metadata_patterns.insert("MAUTHOR".to_string(), Regex::new(r"^#MAUTHOR\s+(.+)$").unwrap());

        Self {
            toolbox_path,
            metadata_patterns,
        }
    }

    pub async fn scan(&self) -> Result<Vec<Script>> {
        let mut scripts = Vec::new();

        if !self.toolbox_path.exists() {
            return Err(anyhow::anyhow!(
                "Toolbox directory does not exist: {}",
                self.toolbox_path.display()
            ));
        }

        for entry in WalkDir::new(&self.toolbox_path)
            .follow_links(true)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();
            
            // Only process .sh files
            if path.extension().and_then(|s| s.to_str()) != Some("sh") {
                continue;
            }

            // Skip if not a file
            if !path.is_file() {
                continue;
            }

            match self.parse_script(path).await {
                Ok(script) => scripts.push(script),
                Err(e) => {
                    eprintln!("Warning: Failed to parse {}: {}", path.display(), e);
                }
            }
        }

        // Sort scripts by category and order
        scripts.sort_by(|a, b| {
            a.category.cmp(&b.category)
                .then_with(|| a.order.unwrap_or(999).cmp(&b.order.unwrap_or(999)))
                .then_with(|| a.name.cmp(&b.name))
        });

        Ok(scripts)
    }

    async fn parse_script(&self, path: &Path) -> Result<Script> {
        let content = fs::read_to_string(path)
            .with_context(|| format!("Failed to read script: {}", path.display()))?;

        let relative_path = path.strip_prefix(&self.toolbox_path)
            .unwrap_or(path);

        let category = self.determine_category(relative_path);
        let name = path.file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("unknown")
            .to_string();

        let mut script = Script::new(name, path.to_path_buf(), category);

        // Parse metadata from the script content
        self.extract_metadata(&content, &mut script)?;

        // Extract JSON parameters if present
        if let Some(params) = self.extract_json_parameters(&content)? {
            script.parameters = Some(params);
        }

        // Check dependency availability
        script.dependency_available = self.check_dependency_available(&script);

        Ok(script)
    }

    fn determine_category(&self, relative_path: &Path) -> String {
        if let Some(parent) = relative_path.parent() {
            if parent == Path::new("") {
                "TopLevel".to_string()
            } else {
                parent.to_string_lossy().replace('/', "::")
            }
        } else {
            "TopLevel".to_string()
        }
    }

    fn extract_metadata(&self, content: &str, script: &mut Script) -> Result<()> {
        let lines: Vec<&str> = content.lines().take(50).collect(); // Only check first 50 lines

        for line in lines {
            let line = line.trim();

            // Extract each metadata field
            if let Some(captures) = self.metadata_patterns.get("MN").unwrap().captures(line) {
                script.menu_name = Some(captures[1].trim().to_string());
            } else if let Some(captures) = self.metadata_patterns.get("MD").unwrap().captures(line) {
                script.description = Some(captures[1].trim().to_string());
            } else if let Some(captures) = self.metadata_patterns.get("MDD").unwrap().captures(line) {
                script.detailed_description = Some(captures[1].trim().to_string());
            } else if let Some(captures) = self.metadata_patterns.get("MI").unwrap().captures(line) {
                script.integration = Some(captures[1].trim().to_string());
            } else if let Some(captures) = self.metadata_patterns.get("INFO").unwrap().captures(line) {
                script.info_url = Some(captures[1].trim().to_string());
            } else if let Some(captures) = self.metadata_patterns.get("MICON").unwrap().captures(line) {
                script.icon = Some(captures[1].trim().to_string());
            } else if let Some(captures) = self.metadata_patterns.get("MCOLOR").unwrap().captures(line) {
                script.color = Some(captures[1].trim().to_string());
            } else if let Some(captures) = self.metadata_patterns.get("MORDER").unwrap().captures(line) {
                if let Ok(order) = captures[1].parse::<i32>() {
                    script.order = Some(order);
                }
            } else if let Some(captures) = self.metadata_patterns.get("MDEFAULT").unwrap().captures(line) {
                script.is_default = &captures[1] == "true";
            } else if let Some(captures) = self.metadata_patterns.get("MSEPARATOR").unwrap().captures(line) {
                script.separator = Some(captures[1].trim().to_string());
            } else if let Some(captures) = self.metadata_patterns.get("MTAGS").unwrap().captures(line) {
                script.tags = captures[1]
                    .split(',')
                    .map(|s| s.trim().to_string())
                    .filter(|s| !s.is_empty())
                    .collect();
            } else if let Some(captures) = self.metadata_patterns.get("MAUTHOR").unwrap().captures(line) {
                script.author = Some(captures[1].trim().to_string());
            }
        }

        Ok(())
    }

    fn extract_json_parameters(&self, content: &str) -> Result<Option<String>> {
        let start_marker = "#JSON_PARAMS_START";
        let end_marker = "#JSON_PARAMS_END";

        if let Some(start_pos) = content.find(start_marker) {
            if let Some(end_pos) = content.find(end_marker) {
                if end_pos > start_pos {
                    let json_section = &content[start_pos + start_marker.len()..end_pos];
                    
                    // Remove comment markers and extract JSON
                    let json_lines: Vec<String> = json_section
                        .lines()
                        .map(|line| {
                            line.trim()
                                .strip_prefix('#')
                                .unwrap_or(line.trim())
                                .to_string()
                        })
                        .filter(|line| !line.is_empty())
                        .collect();

                    if !json_lines.is_empty() {
                        let json_content = json_lines.join("\n");
                        
                        // Validate JSON
                        if let Err(e) = serde_json::from_str::<serde_json::Value>(&json_content) {
                            eprintln!("Warning: Invalid JSON parameters in {}: {}", 
                                content.lines().next().unwrap_or("unknown"), e);
                            return Ok(None);
                        }

                        return Ok(Some(json_content));
                    }
                }
            }
        }

        Ok(None)
    }

    pub fn detect_script_features(&self, content: &str) -> ScriptFeatures {
        let mut features = ScriptFeatures::default();

        // Detect if script uses apt/yum/dnf (for progress bars)
        if content.contains("apt ") || content.contains("apt-get ") {
            features.has_package_manager = true;
            features.package_manager = Some("apt".to_string());
        } else if content.contains("yum ") || content.contains("dnf ") {
            features.has_package_manager = true;
            features.package_manager = Some(if content.contains("dnf ") { "dnf" } else { "yum" }.to_string());
        }

        // Detect if script has interactive prompts
        if content.contains("read ") || content.contains("dialog ") {
            features.is_interactive = true;
        }

        // Detect if script outputs files for viewing
        if content.contains("cat ") || content.contains("tail ") || content.contains("less ") {
            features.has_file_output = true;
        }

        // Detect if script has conditional flows (for page navigation)
        if content.contains("if ") && content.contains("then") {
            features.has_conditional_flow = true;
        }

        // Detect dangerous operations
        if content.contains("rm -rf") || content.contains("sudo rm") || 
           content.contains("format") || content.contains("mkfs") {
            features.is_dangerous = true;
        }

        features
    }

    fn check_dependency_available(&self, script: &Script) -> bool {
        if let Some(integration) = &script.integration {
            // Skip certain categories that don't represent commands
            let skip_categories = ["ToolboxCore", "SystemUtilities", "LinuxTools", 
                                 "NetworkUtils", "BackupUtilities", "Examples"];
            
            if skip_categories.contains(&integration.as_str()) {
                return true;
            }
            
            // Check if it's a file path
            if integration.starts_with('/') {
                return std::path::Path::new(integration).exists();
            }
            
            // Check if it's a command
            if let Ok(output) = std::process::Command::new("which")
                .arg(integration)
                .output() {
                return output.status.success();
            }
            
            // Check common package managers
            if let Ok(output) = std::process::Command::new("dpkg")
                .args(["-l", integration])
                .output() {
                if output.status.success() {
                    return true;
                }
            }
            
            if let Ok(output) = std::process::Command::new("rpm")
                .args(["-q", integration])
                .output() {
                if output.status.success() {
                    return true;
                }
            }
            
            // If we can't determine, assume it's available
            return false;
        }
        
        true // No dependency specified
    }
}

#[derive(Debug, Default)]
pub struct ScriptFeatures {
    pub has_package_manager: bool,
    pub package_manager: Option<String>,
    pub is_interactive: bool,
    pub has_file_output: bool,
    pub has_conditional_flow: bool,
    pub is_dangerous: bool,
}