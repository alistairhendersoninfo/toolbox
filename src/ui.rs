use anyhow::Result;
use crossterm::{
    event::{DisableMouseCapture, EnableMouseCapture},
    execute,
    terminal::{self, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Alignment, Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear as ClearWidget, Gauge, List, ListItem, ListState, Paragraph, Wrap},
    Frame, Terminal,
};
use std::io::{self, Stdout};

use crate::models::{MenuItem, MenuState, Script};

pub struct MenuUI {
    terminal: Option<Terminal<CrosstermBackend<Stdout>>>,
}

impl MenuUI {
    pub fn new() -> Self {
        Self { terminal: None }
    }

    pub fn initialize(&mut self) -> Result<()> {
        terminal::enable_raw_mode()?;
        let mut stdout = io::stdout();
        execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
        
        let backend = CrosstermBackend::new(stdout);
        let terminal = Terminal::new(backend)?;
        self.terminal = Some(terminal);
        
        Ok(())
    }

    pub fn cleanup(&mut self) -> Result<()> {
        if let Some(mut terminal) = self.terminal.take() {
            terminal::disable_raw_mode()?;
            execute!(
                terminal.backend_mut(),
                LeaveAlternateScreen,
                DisableMouseCapture
            )?;
            terminal.show_cursor()?;
        }
        Ok(())
    }

    pub fn render(&mut self, state: &MenuState) -> Result<()> {
        if let Some(terminal) = &mut self.terminal {
            let search_mode = state.search_mode;
            terminal.draw(|f| {
                if search_mode {
                    Self::render_search_mode(f, state);
                } else {
                    Self::render_menu_mode(f, state);
                }
            })?;
        }
        Ok(())
    }

    fn render_menu_mode(f: &mut Frame, state: &MenuState) {
        let chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(3), // Header
                Constraint::Min(0),    // Menu
                Constraint::Length(3), // Footer
            ])
            .split(f.size());

        // Header
        Self::render_header(f, chunks[0], state);

        // Menu
        Self::render_menu_list(f, chunks[1], state);

        // Footer
        Self::render_footer(f, chunks[2], state);
    }

    fn render_search_mode(f: &mut Frame, state: &MenuState) {
        let chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(3), // Header
                Constraint::Length(3), // Search input
                Constraint::Min(0),    // Results
                Constraint::Length(3), // Footer
            ])
            .split(f.size());

        // Header
        Self::render_search_header(f, chunks[0]);

        // Search input
        Self::render_search_input(f, chunks[1], state);

        // Results
        Self::render_search_results(f, chunks[2], state);

        // Footer
        Self::render_search_footer(f, chunks[3]);
    }

    fn render_header(f: &mut Frame, area: ratatui::layout::Rect, state: &MenuState) {
        let breadcrumb = state.breadcrumb.join(" > ");
        let title = format!("🛡️ Toolbox Suite - {}", breadcrumb);
        
        let header = Paragraph::new(title)
            .style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
            .alignment(Alignment::Center)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .style(Style::default().fg(Color::White)),
            );
        
        f.render_widget(header, area);
    }

    fn render_search_header(f: &mut Frame, area: ratatui::layout::Rect) {
        let header = Paragraph::new("🔍 Search Mode")
            .style(Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD))
            .alignment(Alignment::Center)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .style(Style::default().fg(Color::White)),
            );
        
        f.render_widget(header, area);
    }

    fn render_menu_list(f: &mut Frame, area: ratatui::layout::Rect, state: &MenuState) {
        let items: Vec<ListItem> = state
            .filtered_items
            .iter()
            .enumerate()
            .map(|(i, item)| {
                let (number, content, style) = match item {
                    MenuItem::Script(script) => {
                        let icon = script.display_icon();
                        let name = script.display_name();
                        let desc = script.display_description();
                        
                        let color = Self::get_script_color(script);
                        let style = Style::default().fg(color);
                        
                        let display_text = if !script.dependency_available {
                            format!("🚫 {} {} - {} (Needs Installing)", icon, name, desc)
                        } else {
                            format!("{} {} - {}", icon, name, desc)
                        };
                        
                        (
                            format!("{:2}", i + 1),
                            display_text,
                            style,
                        )
                    }
                    MenuItem::Category(category) => (
                        format!("{:2}", i + 1),
                        format!("{} {} ({} items)", category.icon, category.name, category.total_items()),
                        Style::default().fg(Color::Blue),
                    ),
                    MenuItem::Separator(text) => (
                        "  ".to_string(),
                        format!("──── {} ────", text),
                        Style::default().fg(Color::DarkGray),
                    ),
                    MenuItem::Back => (
                        "X ".to_string(),
                        "⬅️  Back".to_string(),
                        Style::default().fg(Color::Yellow),
                    ),
                    MenuItem::Home => (
                        "H ".to_string(),
                        "🏠 Home".to_string(),
                        Style::default().fg(Color::Green),
                    ),
                    MenuItem::Search => (
                        "S ".to_string(),
                        "🔍 Search".to_string(),
                        Style::default().fg(Color::Cyan),
                    ),
                    MenuItem::Exit => (
                        "Q ".to_string(),
                        "❌ Exit".to_string(),
                        Style::default().fg(Color::Red),
                    ),
                };

                let line = Line::from(vec![
                    Span::styled(number, Style::default().fg(Color::DarkGray)),
                    Span::raw(" "),
                    Span::styled(content, style),
                ]);

                ListItem::new(line)
            })
            .collect();

        let mut list_state = ListState::default();
        list_state.select(Some(state.selected_index));

        let list = List::new(items)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title("Menu")
                    .style(Style::default().fg(Color::White)),
            )
            .highlight_style(
                Style::default()
                    .bg(Color::DarkGray)
                    .add_modifier(Modifier::BOLD),
            )
            .highlight_symbol("► ");

        f.render_stateful_widget(list, area, &mut list_state);
    }

    fn render_search_input(f: &mut Frame, area: ratatui::layout::Rect, state: &MenuState) {
        let input = Paragraph::new(format!("Query: {}_", state.search_query))
            .style(Style::default().fg(Color::White))
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title("Search")
                    .style(Style::default().fg(Color::Yellow)),
            );
        
        f.render_widget(input, area);
    }

    fn render_search_results(f: &mut Frame, area: ratatui::layout::Rect, state: &MenuState) {
        let items: Vec<ListItem> = state
            .filtered_items
            .iter()
            .enumerate()
            .map(|(i, item)| {
                let (content, style) = match item {
                    MenuItem::Script(script) => {
                        let icon = script.display_icon();
                        let name = script.display_name();
                        let desc = script.display_description();
                        let category = &script.category;
                        
                        let color = Self::get_script_color(script);
                        
                        let display_text = if !script.dependency_available {
                            format!("🚫 {} {} - {} [{}] (Needs Installing)", icon, name, desc, category)
                        } else {
                            format!("{} {} - {} [{}]", icon, name, desc, category)
                        };
                        
                        (
                            display_text,
                            Style::default().fg(color),
                        )
                    }
                    MenuItem::Back => (
                        "⬅️  Back to Menu".to_string(),
                        Style::default().fg(Color::Yellow),
                    ),
                    _ => ("".to_string(), Style::default()),
                };

                let line = Line::from(vec![
                    Span::styled(format!("{:2} ", i + 1), Style::default().fg(Color::DarkGray)),
                    Span::styled(content, style),
                ]);

                ListItem::new(line)
            })
            .collect();

        let mut list_state = ListState::default();
        list_state.select(Some(state.selected_index));

        let title = if state.search_query.is_empty() {
            "Search Results (type to search)".to_string()
        } else {
            format!("Search Results ({} found)", items.len().saturating_sub(1))
        };

        let list = List::new(items)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title(title)
                    .style(Style::default().fg(Color::Yellow)),
            )
            .highlight_style(
                Style::default()
                    .bg(Color::DarkGray)
                    .add_modifier(Modifier::BOLD),
            )
            .highlight_symbol("► ");

        f.render_stateful_widget(list, area, &mut list_state);
    }

    fn render_footer(f: &mut Frame, area: ratatui::layout::Rect, _state: &MenuState) {
        let help_text = "Navigation: ↑↓/jk=Move | Enter=Select | 1-9=Quick | X=Back | H=Home | S=Search | Q=Quit | F1=Help";
        
        let footer = Paragraph::new(help_text)
            .style(Style::default().fg(Color::DarkGray))
            .alignment(Alignment::Center)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .style(Style::default().fg(Color::White)),
            )
            .wrap(Wrap { trim: true });
        
        f.render_widget(footer, area);
    }

    fn render_search_footer(f: &mut Frame, area: ratatui::layout::Rect) {
        let help_text = "Type to search | Enter=Select | X/Esc=Exit Search | ↑↓=Navigate";
        
        let footer = Paragraph::new(help_text)
            .style(Style::default().fg(Color::DarkGray))
            .alignment(Alignment::Center)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .style(Style::default().fg(Color::Yellow)),
            );
        
        f.render_widget(footer, area);
    }

    fn get_script_color(script: &Script) -> Color {
        if let Some(color_code) = &script.color {
            match color_code.as_str() {
                "Z1" => Color::Red,     // Dangerous
                "Z2" => Color::Green,   // Safe
                "Z3" => Color::Yellow,  // Warning
                "Z4" => Color::Blue,    // Info
                _ => Color::White,
            }
        } else {
            Color::White
        }
    }

    pub fn show_help_dialog(&mut self) -> Result<()> {
        if let Some(terminal) = &mut self.terminal {
            terminal.draw(|f| {
                let area = f.size();
                
                // Create a centered popup
                let popup_area = Layout::default()
                    .direction(Direction::Vertical)
                    .constraints([
                        Constraint::Percentage(20),
                        Constraint::Percentage(60),
                        Constraint::Percentage(20),
                    ])
                    .split(area)[1];
                
                let popup_area = Layout::default()
                    .direction(Direction::Horizontal)
                    .constraints([
                        Constraint::Percentage(10),
                        Constraint::Percentage(80),
                        Constraint::Percentage(10),
                    ])
                    .split(popup_area)[1];

                f.render_widget(ClearWidget, popup_area);

                let help_text = vec![
                    "🛡️ Toolbox Menu Help",
                    "",
                    "Navigation:",
                    "  ↑↓ or j/k    - Move selection up/down",
                    "  Enter        - Execute selected item",
                    "  1-9, 0       - Quick select by number",
                    "  Page Up/Down - Move 10 items at once",
                    "  Home/End     - Go to first/last item",
                    "",
                    "Shortcuts:",
                    "  X            - Go back to previous menu",
                    "  H            - Go to home menu",
                    "  S            - Enter search mode",
                    "  Q or Ctrl+Q  - Quit application",
                    "  Esc          - Exit current mode/quit",
                    "",
                    "Search Mode:",
                    "  Type to search scripts by name/description",
                    "  X or Esc     - Exit search mode",
                    "",
                    "Script Features:",
                    "  🔴 Red       - Dangerous operations",
                    "  🟡 Yellow    - Caution required",
                    "  🟢 Green     - Safe operations",
                    "  🔵 Blue      - Information/utilities",
                    "",
                    "Press any key to close this help..."
                ];

                let help_paragraph = Paragraph::new(help_text.join("\n"))
                    .style(Style::default().fg(Color::White))
                    .block(
                        Block::default()
                            .borders(Borders::ALL)
                            .title("Help")
                            .style(Style::default().fg(Color::Cyan)),
                    )
                    .wrap(Wrap { trim: true });

                f.render_widget(help_paragraph, popup_area);
            })?;

            // Wait for any key press
            loop {
                if let Ok(crossterm::event::Event::Key(_)) = crossterm::event::read() {
                    break;
                }
            }
        }
        
        Ok(())
    }

    pub fn show_progress_bar(&mut self, title: &str, progress: f64) -> Result<()> {
        if let Some(terminal) = &mut self.terminal {
            terminal.draw(|f| {
                let area = f.size();
                
                let popup_area = Layout::default()
                    .direction(Direction::Vertical)
                    .constraints([
                        Constraint::Percentage(40),
                        Constraint::Length(5),
                        Constraint::Percentage(55),
                    ])
                    .split(area)[1];

                f.render_widget(ClearWidget, popup_area);

                let gauge = Gauge::default()
                    .block(Block::default().borders(Borders::ALL).title(title))
                    .gauge_style(Style::default().fg(Color::Cyan))
                    .percent((progress * 100.0) as u16);

                f.render_widget(gauge, popup_area);
            })?;
        }
        
        Ok(())
    }
}