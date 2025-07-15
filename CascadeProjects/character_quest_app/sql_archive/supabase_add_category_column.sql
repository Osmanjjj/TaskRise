-- タスクテーブルにcategoryカラムを追加
-- このエラーは、アプリケーションがcategoryフィールドを送信しているが、
-- データベースにそのカラムが存在しないために発生しています

ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'その他';

-- 既存のレコードに対してデフォルト値を設定（必要に応じて）
UPDATE tasks 
SET category = 'その他' 
WHERE category IS NULL;