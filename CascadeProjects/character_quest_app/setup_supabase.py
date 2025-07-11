#!/usr/bin/env python3
"""
Supabase テーブル自動セットアップスクリプト
Character Quest App のためのテーブルを作成します
"""

import os
import sys
from supabase import create_client, Client

# Supabase設定
SUPABASE_URL = "https://eumoeaflrukwfpiskbdd.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1bW9lYWZscnVrd2ZwaXNrYmRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMzQ4MzEsImV4cCI6MjA2NzgxMDgzMX0.cIt7wwCBztbur4ynctaVbNUJ5_rnTvzH0OiFjqTyMaA"

# テーブル作成SQL
CREATE_TABLES_SQL = """
-- Create characters table
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

-- Create tasks table
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_characters_created_at ON characters(created_at);
CREATE INDEX IF NOT EXISTS idx_tasks_character_id ON tasks(character_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at);
"""

# RLS ポリシーとトリガー
SETUP_POLICIES_SQL = """
-- Enable Row Level Security (RLS)
ALTER TABLE characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Create policies (for now, allow all operations - in production you'd want proper auth policies)
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

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing triggers if they exist and create new ones
DROP TRIGGER IF EXISTS update_characters_updated_at ON characters;
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;

CREATE TRIGGER update_characters_updated_at BEFORE UPDATE ON characters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
"""

# サンプルデータ
SAMPLE_DATA_SQL = """
-- Insert sample characters
INSERT INTO characters (name, level, experience, health, attack, defense) VALUES
('勇者アレックス', 3, 250, 120, 25, 15),
('魔法使いルナ', 2, 150, 90, 30, 8),
('戦士タロウ', 1, 50, 100, 15, 20)
ON CONFLICT (id) DO NOTHING;

-- Get character IDs for sample tasks
DO $$
DECLARE
    alex_id UUID;
    luna_id UUID;
    taro_id UUID;
BEGIN
    SELECT id INTO alex_id FROM characters WHERE name = '勇者アレックス' LIMIT 1;
    SELECT id INTO luna_id FROM characters WHERE name = '魔法使いルナ' LIMIT 1;
    SELECT id INTO taro_id FROM characters WHERE name = '戦士タロウ' LIMIT 1;
    
    -- Insert sample tasks
    INSERT INTO tasks (title, description, difficulty, status, experience_reward, character_id, due_date) VALUES
    ('朝の散歩', '健康のために毎朝30分散歩する', 'easy', 'completed', 10, alex_id, NOW() + INTERVAL '1 day'),
    ('プログラミング学習', 'Flutter開発を1時間学習する', 'normal', 'pending', 25, alex_id, NOW() + INTERVAL '2 days'),
    ('筋トレ', '腕立て伏せ20回、腹筋20回', 'hard', 'pending', 50, alex_id, NOW() + INTERVAL '1 day'),
    ('読書', '技術書を1章読む', 'normal', 'completed', 25, luna_id, NOW() + INTERVAL '3 days'),
    ('料理', '新しいレシピに挑戦する', 'normal', 'pending', 25, luna_id, NOW() + INTERVAL '2 days'),
    ('掃除', '部屋の整理整頓', 'easy', 'pending', 10, taro_id, NOW() + INTERVAL '1 day')
    ON CONFLICT (id) DO NOTHING;
END $$;
"""

def setup_supabase():
    """Supabaseのテーブルとサンプルデータをセットアップ"""
    try:
        print("🚀 Supabase セットアップを開始します...")
        
        # Supabaseクライアント作成
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
        print("✅ Supabase接続成功")
        
        # サンプルキャラクターを直接挿入
        print("👤 サンプルキャラクターを作成中...")
        characters_data = [
            {
                "name": "勇者アレックス",
                "level": 3,
                "experience": 250,
                "health": 120,
                "attack": 25,
                "defense": 15
            },
            {
                "name": "魔法使いルナ", 
                "level": 2,
                "experience": 150,
                "health": 90,
                "attack": 30,
                "defense": 8
            },
            {
                "name": "戦士タロウ",
                "level": 1, 
                "experience": 50,
                "health": 100,
                "attack": 15,
                "defense": 20
            }
        ]
        
        # 既存のキャラクターをチェック
        existing_chars = supabase.table('characters').select('name').execute()
        existing_names = [char['name'] for char in existing_chars.data]
        
        for char_data in characters_data:
            if char_data['name'] not in existing_names:
                result = supabase.table('characters').insert(char_data).execute()
                print(f"   ✅ {char_data['name']} を作成")
            else:
                print(f"   ⏭️  {char_data['name']} は既に存在")
        
        # キャラクターIDを取得
        characters = supabase.table('characters').select('id, name').execute()
        char_ids = {char['name']: char['id'] for char in characters.data}
        
        # サンプルタスクを作成
        print("📋 サンプルタスクを作成中...")
        from datetime import datetime, timedelta
        
        tasks_data = [
            {
                "title": "朝の散歩",
                "description": "健康のために毎朝30分散歩する",
                "difficulty": "easy",
                "status": "completed",
                "experience_reward": 10,
                "character_id": char_ids.get("勇者アレックス"),
                "due_date": (datetime.now() + timedelta(days=1)).isoformat()
            },
            {
                "title": "プログラミング学習",
                "description": "Flutter開発を1時間学習する", 
                "difficulty": "normal",
                "status": "pending",
                "experience_reward": 25,
                "character_id": char_ids.get("勇者アレックス"),
                "due_date": (datetime.now() + timedelta(days=2)).isoformat()
            },
            {
                "title": "筋トレ",
                "description": "腕立て伏せ20回、腹筋20回",
                "difficulty": "hard", 
                "status": "pending",
                "experience_reward": 50,
                "character_id": char_ids.get("勇者アレックス"),
                "due_date": (datetime.now() + timedelta(days=1)).isoformat()
            },
            {
                "title": "読書",
                "description": "技術書を1章読む",
                "difficulty": "normal",
                "status": "completed", 
                "experience_reward": 25,
                "character_id": char_ids.get("魔法使いルナ"),
                "due_date": (datetime.now() + timedelta(days=3)).isoformat()
            },
            {
                "title": "料理",
                "description": "新しいレシピに挑戦する",
                "difficulty": "normal",
                "status": "pending",
                "experience_reward": 25, 
                "character_id": char_ids.get("魔法使いルナ"),
                "due_date": (datetime.now() + timedelta(days=2)).isoformat()
            },
            {
                "title": "掃除",
                "description": "部屋の整理整頓",
                "difficulty": "easy",
                "status": "pending",
                "experience_reward": 10,
                "character_id": char_ids.get("戦士タロウ"),
                "due_date": (datetime.now() + timedelta(days=1)).isoformat()
            }
        ]
        
        # 既存のタスクをチェック
        existing_tasks = supabase.table('tasks').select('title').execute()
        existing_titles = [task['title'] for task in existing_tasks.data]
        
        for task_data in tasks_data:
            if task_data['title'] not in existing_titles and task_data['character_id']:
                result = supabase.table('tasks').insert(task_data).execute()
                print(f"   ✅ {task_data['title']} を作成")
        
        print("\n🎉 Character Quest App のSupabaseセットアップが完了しました！")
        print("\n📱 アプリを再起動すると以下が利用できます：")
        print("   - 3体のサンプルキャラクター")
        print("   - 6個のサンプルタスク")
        print("   - 完全なゲーミフィケーションシステム")
        
        return True
        
    except Exception as e:
        print(f"❌ エラーが発生しました: {e}")
        print("\n🔧 テーブルが存在しない場合は、以下の手順で作成してください：")
        print("1. Supabase Dashboard にアクセス")
        print("2. SQL Editor で supabase_tables.sql を実行")
        print("3. 再度このスクリプトを実行")
        return False

def check_tables():
    """テーブルの存在確認"""
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
        
        # キャラクター一覧を取得してテスト
        result = supabase.table('characters').select('*').execute()
        print(f"📊 現在のキャラクター数: {len(result.data)}")
        
        # タスク一覧を取得してテスト
        result = supabase.table('tasks').select('*').execute()
        print(f"📋 現在のタスク数: {len(result.data)}")
        
        return True
        
    except Exception as e:
        print(f"❌ テーブル確認エラー: {e}")
        return False

if __name__ == "__main__":
    print("🎮 Character Quest App - Supabase セットアップツール")
    print("=" * 50)
    
    if len(sys.argv) > 1 and sys.argv[1] == "--check":
        print("🔍 テーブル状況を確認中...")
        check_tables()
    else:
        setup_supabase()
        print("\n" + "=" * 50)
        print("💡 使い方:")
        print("   python setup_supabase.py        # セットアップ実行")
        print("   python setup_supabase.py --check # テーブル確認")
