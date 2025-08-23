use anyhow::Result;
use indicatif::{ProgressBar, ProgressStyle};
use std::path::PathBuf;
use std::process::{Command, Stdio};
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::Command as TokioCommand;

use crate::models::Script;

pub struct ScriptExecutor {
    toolbox_path: PathBuf,
}

impl ScriptExecutor {
    pub fn new(toolbox_path: PathBuf) -> Self {
        Self { toolbox_path }
    }

    pub async fn execute(&self, script: &Script) -> Result<i32> {
        println!("🚀 Executing: {}", script.display_name());
        println!("📝 Description: {}", script.display_description());
        
        if let Some(info_url) = &script.info_url {
            println!("ℹ️  Info: {}", info_url);
        }

        println!("📁 Path: {}", script.path.display());
        println!("{}", "=".repeat(60));

        // Check if script has parameters
        if script.has_parameters() {
            println!("⚙️  This script has parameters. Parameter collection not yet implemented.");
            println!("   Proceeding with default execution...");
        }

        // Detect script features for enhanced display
        let script_content = tokio::fs::read_to_string(&script.path).await?;
        let features = self.detect_script_features(&script_content);

        let exit_code = if features.has_package_manager {
            self.execute_with_progress_tracking(script, &features).await?
        } else if features.has_file_output {
            self.execute_with_output_capture(script).await?
        } else {
            self.execute_simple(script).await?
        };

        println!("{}", "=".repeat(60));
        if exit_code == 0 {
            println!("✅ Script completed successfully");
        } else {
            println!("❌ Script failed with exit code: {}", exit_code);
        }

        Ok(exit_code)
    }

    async fn execute_simple(&self, script: &Script) -> Result<i32> {
        let mut cmd = TokioCommand::new("bash");
        cmd.arg(&script.path);
        cmd.current_dir(&self.toolbox_path);

        let mut child = cmd.spawn()?;
        let status = child.wait().await?;

        Ok(status.code().unwrap_or(-1))
    }

    async fn execute_with_progress_tracking(&self, script: &Script, _features: &ScriptFeatures) -> Result<i32> {
        println!("📦 Detected package manager operations - showing progress");
        
        println!("📦 Package manager operations detected - monitoring progress");
        
        let mut cmd = TokioCommand::new("bash");
        cmd.arg(&script.path);
        cmd.current_dir(&self.toolbox_path);
        cmd.stdout(Stdio::piped());
        cmd.stderr(Stdio::piped());

        let mut child = cmd.spawn()?;
        
        // Monitor output for progress indicators
        if let Some(stdout) = child.stdout.take() {
            let reader = BufReader::new(stdout);
            let mut lines = reader.lines();

            while let Ok(Some(line)) = lines.next_line().await {
                println!("{}", line);
                
                // Show progress messages based on common package manager outputs
                if line.contains("Reading package lists") {
                    println!("📋 Reading package lists...");
                } else if line.contains("Building dependency tree") {
                    println!("🔗 Building dependency tree...");
                } else if line.contains("Downloading") || line.contains("Get:") {
                    println!("⬇️  Downloading packages...");
                } else if line.contains("Unpacking") {
                    println!("📦 Unpacking packages...");
                } else if line.contains("Setting up") {
                    println!("⚙️  Setting up packages...");
                } else if line.contains("Processing triggers") {
                    println!("🔧 Processing triggers...");
                }
            }
        }

        let status = child.wait().await?;
        println!("✅ Package operations completed");

        Ok(status.code().unwrap_or(-1))
    }

    async fn execute_with_output_capture(&self, script: &Script) -> Result<i32> {
        println!("📄 Script may produce file output - enhanced display enabled");

        let mut cmd = TokioCommand::new("bash");
        cmd.arg(&script.path);
        cmd.current_dir(&self.toolbox_path);
        cmd.stdout(Stdio::piped());
        cmd.stderr(Stdio::piped());

        let mut child = cmd.spawn()?;
        
        // Capture and display output with potential file viewing
        if let Some(stdout) = child.stdout.take() {
            let reader = BufReader::new(stdout);
            let mut lines = reader.lines();

            while let Ok(Some(line)) = lines.next_line().await {
                println!("{}", line);
                
                // Check for file output patterns
                if line.contains("cat ") || line.contains("tail ") || line.contains("less ") {
                    println!("🔍 File viewing detected - enhanced display available");
                    // Future: Implement enhanced file viewing with search
                }
            }
        }

        let status = child.wait().await?;
        Ok(status.code().unwrap_or(-1))
    }

    fn detect_script_features(&self, content: &str) -> ScriptFeatures {
        let mut features = ScriptFeatures::default();

        // Detect package managers
        if content.contains("apt ") || content.contains("apt-get ") {
            features.has_package_manager = true;
            features.package_manager = Some("apt".to_string());
        } else if content.contains("yum ") || content.contains("dnf ") {
            features.has_package_manager = true;
            features.package_manager = Some(if content.contains("dnf ") { "dnf" } else { "yum" }.to_string());
        }

        // Detect file output commands
        if content.contains("cat ") || content.contains("tail ") || content.contains("less ") || content.contains("more ") {
            features.has_file_output = true;
        }

        // Detect interactive elements
        if content.contains("read ") || content.contains("dialog ") || content.contains("whiptail ") {
            features.is_interactive = true;
        }

        // Detect conditional flows
        if content.contains("if ") && content.contains("then") {
            features.has_conditional_flow = true;
        }

        // Detect dangerous operations
        if content.contains("rm -rf") || content.contains("sudo rm") || 
           content.contains("format") || content.contains("mkfs") ||
           content.contains("dd if=") || content.contains("fdisk") {
            features.is_dangerous = true;
        }

        // Detect network operations
        if content.contains("curl ") || content.contains("wget ") || 
           content.contains("ssh ") || content.contains("scp ") {
            features.has_network_ops = true;
        }

        features
    }

    pub async fn show_file_with_search(&self, file_path: &str, search_term: Option<&str>) -> Result<()> {
        println!("📄 Displaying file: {}", file_path);
        
        if let Some(term) = search_term {
            println!("🔍 Searching for: {}", term);
            
            // Use grep to highlight matches
            let output = Command::new("grep")
                .arg("--color=always")
                .arg("-n")
                .arg("-i")
                .arg(term)
                .arg(file_path)
                .output()?;

            if output.status.success() {
                println!("{}", String::from_utf8_lossy(&output.stdout));
            } else {
                println!("No matches found for '{}'", term);
            }
        } else {
            // Show file with less for pagination
            let mut cmd = Command::new("less");
            cmd.arg("-R") // Raw control chars for colors
                .arg("-S") // Chop long lines
                .arg(file_path);

            let status = cmd.status()?;
            if !status.success() {
                // Fallback to cat
                let output = Command::new("cat").arg(file_path).output()?;
                println!("{}", String::from_utf8_lossy(&output.stdout));
            }
        }

        Ok(())
    }

    pub async fn tail_with_search(&self, file_path: &str, search_term: Option<&str>) -> Result<()> {
        println!("📄 Tailing file: {}", file_path);
        
        if let Some(term) = search_term {
            println!("🔍 Filtering for: {}", term);
            
            // Use tail with grep
            let mut tail_cmd = Command::new("tail");
            tail_cmd.arg("-f").arg(file_path);
            
            let mut grep_cmd = Command::new("grep");
            grep_cmd.arg("--color=always")
                .arg("-i")
                .arg(term)
                .stdin(Stdio::piped());

            let tail_child = tail_cmd.stdout(Stdio::piped()).spawn()?;
            let mut tail_child = tail_cmd.stdout(Stdio::piped()).spawn()?;
            let mut grep_child = grep_cmd.stdin(tail_child.stdout.take().unwrap()).spawn()?;

            grep_child.wait()?;
        } else {
            // Simple tail
            let _status = Command::new("tail")
                .arg("-f")
                .arg(file_path)
                .status()?;
        }

        Ok(())
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
    pub has_network_ops: bool,
}

pub struct FileViewer {
    current_file: Option<PathBuf>,
    search_term: Option<String>,
    line_number: usize,
}

impl FileViewer {
    pub fn new() -> Self {
        Self {
            current_file: None,
            search_term: None,
            line_number: 0,
        }
    }

    pub async fn view_file(&mut self, path: &PathBuf) -> Result<()> {
        self.current_file = Some(path.clone());
        self.display_file().await
    }

    pub async fn search_in_file(&mut self, term: &str) -> Result<()> {
        self.search_term = Some(term.to_string());
        self.display_file().await
    }

    pub async fn next_match(&mut self) -> Result<()> {
        if let (Some(file), Some(term)) = (&self.current_file, &self.search_term) {
            // Find next occurrence after current line
            let content = tokio::fs::read_to_string(file).await?;
            let lines: Vec<&str> = content.lines().collect();
            
            for (i, line) in lines.iter().enumerate().skip(self.line_number + 1) {
                if line.to_lowercase().contains(&term.to_lowercase()) {
                    self.line_number = i;
                    self.display_context(i, &lines).await?;
                    return Ok(());
                }
            }
            
            println!("No more matches found");
        }
        Ok(())
    }

    pub async fn previous_match(&mut self) -> Result<()> {
        if let (Some(file), Some(term)) = (&self.current_file, &self.search_term) {
            let content = tokio::fs::read_to_string(file).await?;
            let lines: Vec<&str> = content.lines().collect();
            
            for i in (0..self.line_number).rev() {
                if lines[i].to_lowercase().contains(&term.to_lowercase()) {
                    self.line_number = i;
                    self.display_context(i, &lines).await?;
                    return Ok(());
                }
            }
            
            println!("No previous matches found");
        }
        Ok(())
    }

    async fn display_file(&self) -> Result<()> {
        if let Some(file) = &self.current_file {
            let content = tokio::fs::read_to_string(file).await?;
            
            if let Some(term) = &self.search_term {
                // Highlight search term
                let highlighted = content.replace(
                    term,
                    &format!("\x1b[43m\x1b[30m{}\x1b[0m", term)
                );
                println!("{}", highlighted);
            } else {
                println!("{}", content);
            }
        }
        Ok(())
    }

    async fn display_context(&self, line_num: usize, lines: &[&str]) -> Result<()> {
        let start = line_num.saturating_sub(3);
        let end = (line_num + 4).min(lines.len());
        
        for (i, line) in lines.iter().enumerate().take(end).skip(start) {
            let marker = if i == line_num { ">>>" } else { "   " };
            println!("{} {:4}: {}", marker, i + 1, line);
        }
        
        Ok(())
    }
}