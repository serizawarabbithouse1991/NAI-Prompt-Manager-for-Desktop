// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::Row;

#[derive(serde::Serialize)]
struct DanbooruTagMatch {
    name: String,
    tag_type: i64,
    popularity: i64,
}

#[derive(serde::Serialize)]
struct DanbooruDbStats {
    total_tags: i64,
    type_counts: std::collections::HashMap<String, i64>,
}

async fn connect_danbooru_db(db_path: String) -> Result<sqlx::SqlitePool, String> {
    if db_path.trim().is_empty() {
        return Err("Danbooru DBが未設定です".to_string());
    }

    let options = SqliteConnectOptions::new()
        .filename(db_path)
        .read_only(true)
        .create_if_missing(false);
    SqlitePoolOptions::new()
        .max_connections(1)
        .connect_with(options)
        .await
        .map_err(|err| format!("Danbooru DBに接続できません: {err}"))
}

#[tauri::command]
async fn get_danbooru_db_stats(db_path: String) -> Result<DanbooruDbStats, String> {
    let pool = connect_danbooru_db(db_path).await?;
    let total_tags: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM tag")
        .fetch_one(&pool)
        .await
        .map_err(|err| format!("DanbooruタグDBの確認に失敗しました: {err}"))?;

    let rows = sqlx::query("SELECT type, COUNT(*) AS count FROM tag GROUP BY type")
        .fetch_all(&pool)
        .await
        .map_err(|err| format!("Danbooruタグ種別の確認に失敗しました: {err}"))?;
    let mut type_counts = std::collections::HashMap::new();
    for row in rows {
        let tag_type: i64 = row.try_get("type").unwrap_or_default();
        let count: i64 = row.try_get("count").unwrap_or_default();
        type_counts.insert(tag_type.to_string(), count);
    }

    Ok(DanbooruDbStats {
        total_tags,
        type_counts,
    })
}

#[tauri::command]
async fn find_danbooru_tags(
    db_path: String,
    names: Vec<String>,
) -> Result<Vec<DanbooruTagMatch>, String> {
    if db_path.trim().is_empty() || names.is_empty() {
        return Ok(Vec::new());
    }

    let mut unique_names = Vec::new();
    for name in names {
        let normalized = name.trim().to_lowercase();
        if !normalized.is_empty() && !unique_names.contains(&normalized) {
            unique_names.push(normalized);
        }
    }
    if unique_names.is_empty() {
        return Ok(Vec::new());
    }

    let pool = connect_danbooru_db(db_path).await?;

    let mut matches = Vec::new();
    for chunk in unique_names.chunks(500) {
        let placeholders = vec!["?"; chunk.len()].join(", ");
        let sql = format!(
            "SELECT name, type, popularity FROM tag WHERE name IN ({}) ORDER BY popularity DESC",
            placeholders
        );
        let mut query = sqlx::query(&sql);
        for name in chunk {
            query = query.bind(name);
        }

        let rows = query
            .fetch_all(&pool)
            .await
            .map_err(|err| format!("Danbooruタグ照合に失敗しました: {err}"))?;
        for row in rows {
            matches.push(DanbooruTagMatch {
                name: row.try_get("name").unwrap_or_default(),
                tag_type: row.try_get("type").unwrap_or_default(),
                popularity: row.try_get("popularity").unwrap_or_default(),
            });
        }
    }

    Ok(matches)
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_sql::Builder::new().build())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            find_danbooru_tags,
            get_danbooru_db_stats
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
