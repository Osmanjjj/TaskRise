#!/usr/bin/env python3
"""
Selenium WebDriverを使用してSupabase Dashboardに自動アクセスし、
SQLを実行してテーブルを作成するスクリプト
"""

import time
import os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.keys import Keys

# Supabase設定
SUPABASE_PROJECT_URL = "https://supabase.com/dashboard/project/eumoeaflrukwfpiskbdd"
SQL_EDITOR_URL = "https://supabase.com/dashboard/project/eumoeaflrukwfpiskbdd/sql/new"

# テーブル作成SQL
CREATE_TABLES_SQL = """-- Character Quest App テーブル作成
-- キャラクターテーブル
CREATE TABLE IF NOT EXISTS characters (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    level INTEGER DEFAULT 1,
    experience INTEGER DEFAULT 0,
    health INTEGER DEFAULT 100,
    attack INTEGER DEFAULT 10,
    defense INTEGER DEFAULT 5,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- タスクテーブル
CREATE TABLE IF NOT EXISTS tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    difficulty VARCHAR(10) DEFAULT 'normal' CHECK (difficulty IN ('easy', 'normal', 'hard')),
    status VARCHAR(10) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
    experience_reward INTEGER DEFAULT 0,
    due_date TIMESTAMP WITH TIME ZONE,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス作成
CREATE INDEX IF NOT EXISTS idx_characters_created_at ON characters(created_at);
CREATE INDEX IF NOT EXISTS idx_tasks_character_id ON tasks(character_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at);

-- RLS (Row Level Security) 有効化
ALTER TABLE characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- RLSポリシー作成（開発用: 全アクセス許可）
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all operations on characters') THEN
        CREATE POLICY "Allow all operations on characters" ON characters FOR ALL USING (true);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all operations on tasks') THEN
        CREATE POLICY "Allow all operations on tasks" ON tasks FOR ALL USING (true);
    END IF;
END $$;

-- 自動更新トリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- トリガー作成
DROP TRIGGER IF EXISTS update_characters_updated_at ON characters;
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;

CREATE TRIGGER update_characters_updated_at BEFORE UPDATE ON characters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 完了メッセージ
SELECT '🎉 Character Quest App のテーブル作成が完了しました！' as message;
"""

def setup_webdriver():
    """Chrome WebDriverをセットアップ"""
    chrome_options = Options()
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    # ヘッドレスモードを無効化（デバッグ用）
    # chrome_options.add_argument("--headless")
    
    try:
        driver = webdriver.Chrome(options=chrome_options)
        return driver
    except Exception as e:
        print(f"❌ WebDriverの初期化に失敗: {e}")
        print("💡 ChromeDriverがインストールされていることを確認してください")
        print("   インストール方法: brew install chromedriver")
        return None

def create_tables_with_selenium():
    """SeleniumでSupabase SQL Editorにアクセスしてテーブル作成"""
    print("🌐 WebDriverでSupabaseにアクセスします...")
    
    driver = setup_webdriver()
    if not driver:
        return False
    
    try:
        # Supabase SQL Editorに移動
        print(f"📱 Supabase SQL Editorにアクセス: {SQL_EDITOR_URL}")
        driver.get(SQL_EDITOR_URL)
        
        # ページの読み込み待機
        print("⏳ ページの読み込みを待機中...")
        time.sleep(5)
        
        # ログインが必要な場合の処理
        print("🔐 認証状況を確認中...")
        if "login" in driver.current_url.lower() or "auth" in driver.current_url.lower():
            print("❗ Supabaseにログインが必要です")
            print("🔑 ブラウザでSupabaseにログインしてから、このスクリプトを再実行してください")
            input("ログイン完了後、任意のキーを押してください...")
            driver.refresh()
            time.sleep(3)
        
        # SQL Editorのテキストエリアを探す
        print("📝 SQL Editorを探しています...")
        wait = WebDriverWait(driver, 20)
        
        # 複数のセレクタを試行
        selectors = [
            "textarea",
            ".monaco-editor textarea",
            "[data-testid='sql-editor']",
            ".CodeMirror textarea",
            "#sql-editor",
            "[placeholder*='SQL']"
        ]
        
        sql_editor = None
        for selector in selectors:
            try:
                sql_editor = wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, selector)))
                print(f"✅ SQL Editorが見つかりました: {selector}")
                break
            except:
                continue
        
        if not sql_editor:
            print("❌ SQL Editorが見つかりません")
            print("🔍 現在のページ情報:")
            print(f"   URL: {driver.current_url}")
            print(f"   Title: {driver.title}")
            
            # スクリーンショットを保存
            screenshot_path = "supabase_debug.png"
            driver.save_screenshot(screenshot_path)
            print(f"📸 デバッグ用スクリーンショット保存: {screenshot_path}")
            
            # 手動で操作する時間を提供
            print("\n🔧 手動操作モード:")
            print("1. ブラウザウィンドウでSQL Editorに移動")
            print("2. 以下のSQLをコピー&ペースト:")
            print("─" * 50)
            print(CREATE_TABLES_SQL)
            print("─" * 50)
            input("SQLの実行が完了したら、任意のキーを押してください...")
            return True
        
        # SQLエディタにコードを入力
        print("📝 SQLを入力中...")
        sql_editor.clear()
        sql_editor.send_keys(CREATE_TABLES_SQL)
        
        # 実行ボタンを探して実行
        print("▶️ 実行ボタンを探しています...")
        run_selectors = [
            "[data-testid='run-sql']",
            "button[aria-label*='run']",
            "button[title*='Run']",
            ".btn-primary",
            "button:contains('Run')",
            "[data-cy='run-sql']"
        ]
        
        run_button = None
        for selector in run_selectors:
            try:
                run_button = driver.find_element(By.CSS_SELECTOR, selector)
                break
            except:
                continue
        
        if run_button:
            print("🚀 SQLを実行中...")
            run_button.click()
            time.sleep(3)
            print("✅ SQL実行完了")
        else:
            # Ctrl+Enter で実行を試行
            print("⌨️  Ctrl+Enterで実行を試行...")
            sql_editor.send_keys(Keys.CONTROL + Keys.ENTER)
            time.sleep(3)
        
        # 結果の確認
        print("✅ テーブル作成処理が完了しました")
        
        # ブラウザを開いたままにする
        print("🌐 ブラウザは開いたままにします。確認後、手動で閉じてください。")
        print("💡 結果を確認してから次の処理を続行します...")
        time.sleep(5)
        
        return True
        
    except Exception as e:
        print(f"❌ エラーが発生しました: {e}")
        
        # エラー時のスクリーンショット
        try:
            error_screenshot = "supabase_error.png"
            driver.save_screenshot(error_screenshot)
            print(f"📸 エラー時スクリーンショット: {error_screenshot}")
        except:
            pass
            
        return False
    
    finally:
        # クリーンアップ（コメントアウト：手動確認のため）
        # driver.quit()
        pass

def manual_setup_guide():
    """手動セットアップのガイド表示"""
    print("\n" + "="*60)
    print("🔧 手動セットアップガイド")
    print("="*60)
    print("1. 以下のURLにアクセス:")
    print(f"   {SQL_EDITOR_URL}")
    print("\n2. SQL Editorに以下のコードをコピー&ペースト:")
    print("─" * 50)
    print(CREATE_TABLES_SQL)
    print("─" * 50)
    print("\n3. 'Run' ボタンをクリックして実行")
    print("4. 成功メッセージを確認")
    print("5. setup_supabase.py を再実行")

if __name__ == "__main__":
    print("🎮 Character Quest App - Web自動セットアップ")
    print("="*60)
    
    try:
        # Seleniumでの自動セットアップを試行
        success = create_tables_with_selenium()
        
        if success:
            print("\n🎉 Webセットアップが完了しました！")
            print("📱 次にPythonスクリプトでサンプルデータを作成します...")
            
            # サンプルデータ作成スクリプトを実行
            import subprocess
            result = subprocess.run(["python3", "setup_supabase.py"], 
                                  capture_output=True, text=True)
            print(result.stdout)
            if result.stderr:
                print("⚠️  Warnings:", result.stderr)
        else:
            manual_setup_guide()
            
    except KeyboardInterrupt:
        print("\n⏹️  ユーザーによって中断されました")
    except Exception as e:
        print(f"❌ 予期しないエラー: {e}")
        manual_setup_guide()
