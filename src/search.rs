use fuzzy_matcher::{skim::SkimMatcherV2, FuzzyMatcher};
use std::collections::HashMap;

use crate::models::Script;

pub struct SearchEngine {
    matcher: SkimMatcherV2,
}

impl SearchEngine {
    pub fn new() -> Self {
        Self {
            matcher: SkimMatcherV2::default(),
        }
    }

    pub fn fuzzy_search(&self, scripts: &[Script], query: &str) -> Vec<Script> {
        let mut scored_scripts: Vec<(Script, i64)> = scripts
            .iter()
            .filter_map(|script| {
                let score = self.calculate_script_score(script, query)?;
                Some((script.clone(), score))
            })
            .collect();

        // Sort by score (higher is better)
        scored_scripts.sort_by(|a, b| b.1.cmp(&a.1));

        scored_scripts.into_iter().map(|(script, _)| script).collect()
    }

    fn calculate_script_score(&self, script: &Script, query: &str) -> Option<i64> {
        let mut max_score = 0i64;

        // Check name (highest priority)
        if let Some(score) = self.matcher.fuzzy_match(&script.name, query) {
            max_score = max_score.max(score * 3);
        }

        // Check menu name
        if let Some(menu_name) = &script.menu_name {
            if let Some(score) = self.matcher.fuzzy_match(menu_name, query) {
                max_score = max_score.max(score * 3);
            }
        }

        // Check description
        if let Some(description) = &script.description {
            if let Some(score) = self.matcher.fuzzy_match(description, query) {
                max_score = max_score.max(score * 2);
            }
        }

        // Check detailed description
        if let Some(detailed_description) = &script.detailed_description {
            if let Some(score) = self.matcher.fuzzy_match(detailed_description, query) {
                max_score = max_score.max(score);
            }
        }

        // Check tags
        for tag in &script.tags {
            if let Some(score) = self.matcher.fuzzy_match(tag, query) {
                max_score = max_score.max(score * 2);
            }
        }

        // Check category
        if let Some(score) = self.matcher.fuzzy_match(&script.category, query) {
            max_score = max_score.max(score);
        }

        // Check author
        if let Some(author) = &script.author {
            if let Some(score) = self.matcher.fuzzy_match(author, query) {
                max_score = max_score.max(score);
            }
        }

        if max_score > 0 {
            Some(max_score)
        } else {
            None
        }
    }

    pub fn search_by_category(&self, scripts: &[Script], category: &str) -> Vec<Script> {
        scripts
            .iter()
            .filter(|script| {
                script.category.to_lowercase().contains(&category.to_lowercase())
            })
            .cloned()
            .collect()
    }

    pub fn search_by_tags(&self, scripts: &[Script], tags: &[String]) -> Vec<Script> {
        scripts
            .iter()
            .filter(|script| {
                tags.iter().any(|tag| {
                    script.tags.iter().any(|script_tag| {
                        script_tag.to_lowercase().contains(&tag.to_lowercase())
                    })
                })
            })
            .cloned()
            .collect()
    }

    pub fn get_suggestions(&self, scripts: &[Script], partial_query: &str) -> Vec<String> {
        if partial_query.len() < 2 {
            return Vec::new();
        }

        let mut suggestions = std::collections::HashSet::new();

        // Collect suggestions from various fields
        for script in scripts {
            // From names
            if script.name.to_lowercase().starts_with(&partial_query.to_lowercase()) {
                suggestions.insert(script.name.clone());
            }

            if let Some(menu_name) = &script.menu_name {
                if menu_name.to_lowercase().starts_with(&partial_query.to_lowercase()) {
                    suggestions.insert(menu_name.clone());
                }
            }

            // From tags
            for tag in &script.tags {
                if tag.to_lowercase().starts_with(&partial_query.to_lowercase()) {
                    suggestions.insert(tag.clone());
                }
            }

            // From categories
            if script.category.to_lowercase().starts_with(&partial_query.to_lowercase()) {
                suggestions.insert(script.category.clone());
            }
        }

        let mut suggestions: Vec<String> = suggestions.into_iter().collect();
        suggestions.sort();
        suggestions.truncate(10); // Limit to 10 suggestions
        suggestions
    }

    pub fn highlight_matches(&self, text: &str, query: &str) -> Vec<(usize, usize)> {
        if let Some((_score, indices)) = self.matcher.fuzzy_indices(text, query) {
            // Convert Vec<usize> to Vec<(usize, usize)> for character ranges
            let mut ranges = Vec::new();
            for &idx in &indices {
                ranges.push((idx, idx + 1));
            }
            return ranges;
        }
        Vec::new()
    }
}

#[derive(Debug, Clone)]
pub struct SearchResult {
    pub script: Script,
    pub score: i64,
    pub matched_fields: Vec<String>,
    pub highlight_ranges: HashMap<String, Vec<(usize, usize)>>,
}

impl SearchEngine {
    pub fn advanced_search(&self, scripts: &[Script], query: &str) -> Vec<SearchResult> {
        let mut results: Vec<SearchResult> = scripts
            .iter()
            .filter_map(|script| {
                let mut result = SearchResult {
                    script: script.clone(),
                    score: 0,
                    matched_fields: Vec::new(),
                    highlight_ranges: HashMap::new(),
                };

                let mut total_score = 0i64;

                // Check each field and collect matches
                if let Some((score, indices)) = self.matcher.fuzzy_indices(&script.name, query) {
                    total_score += score * 3;
                    result.matched_fields.push("name".to_string());
                    let ranges: Vec<(usize, usize)> = indices.iter().map(|&i| (i, i + 1)).collect();
                    result.highlight_ranges.insert("name".to_string(), ranges);
                }

                if let Some(menu_name) = &script.menu_name {
                    if let Some((score, indices)) = self.matcher.fuzzy_indices(menu_name, query) {
                        total_score += score * 3;
                        result.matched_fields.push("menu_name".to_string());
                        let ranges: Vec<(usize, usize)> = indices.iter().map(|&i| (i, i + 1)).collect();
                        result.highlight_ranges.insert("menu_name".to_string(), ranges);
                    }
                }

                if let Some(description) = &script.description {
                    if let Some((score, indices)) = self.matcher.fuzzy_indices(description, query) {
                        total_score += score * 2;
                        result.matched_fields.push("description".to_string());
                        let ranges: Vec<(usize, usize)> = indices.iter().map(|&i| (i, i + 1)).collect();
                        result.highlight_ranges.insert("description".to_string(), ranges);
                    }
                }

                // Check tags
                for (i, tag) in script.tags.iter().enumerate() {
                    if let Some((score, indices)) = self.matcher.fuzzy_indices(tag, query) {
                        total_score += score * 2;
                        result.matched_fields.push(format!("tag_{}", i));
                        let ranges: Vec<(usize, usize)> = indices.iter().map(|&idx| (idx, idx + 1)).collect();
                        result.highlight_ranges.insert(format!("tag_{}", i), ranges);
                    }
                }

                if total_score > 0 {
                    result.score = total_score;
                    Some(result)
                } else {
                    None
                }
            })
            .collect();

        // Sort by score
        results.sort_by(|a, b| b.score.cmp(&a.score));
        results
    }
}