# iOS Setup Guide for Character Quest App

## 前提条件

- Xcode 14.0以上
- iOS 13.0以上のターゲット
- Apple Developer アカウント（実機テスト用）

## セットアップ手順

### 1. iOS プロジェクトを開く

```bash
cd ios
open Runner.xcworkspace
```

**注意**: `Runner.xcodeproj`ではなく`Runner.xcworkspace`を開いてください。

### 2. Bundle Identifier の設定

1. Xcodeで`Runner`ターゲットを選択
2. `General`タブで`Bundle Identifier`を設定
   - 例: `com.yourcompany.characterquestapp`
3. Info.plistのCFBundleURLSchemesも同じ値に更新

### 3. Supabase認証の設定

#### Info.plist の設定

既に追加済みですが、以下の設定が必要です：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.example.characterquestapp</string>
        </array>
    </dict>
</array>
```

#### Supabaseダッシュボードの設定

1. Supabaseダッシュボードにログイン
2. Authentication → URL Configuration に移動
3. Redirect URLs に以下を追加：
   - `com.example.characterquestapp://login-callback`
   - `com.example.characterquestapp://`

### 4. iOS特有の認証設定

#### Google Sign-In (オプション)

1. Google Cloud ConsoleでiOSアプリを追加
2. `GoogleService-Info.plist`をダウンロード
3. XcodeのRunnerフォルダに追加
4. Info.plistに以下を追加：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

#### Apple Sign-In (オプション)

1. Xcodeで`Signing & Capabilities`タブを開く
2. `+ Capability`をクリック
3. `Sign in with Apple`を追加
4. Apple Developer ConsoleでSign in with Appleを有効化

### 5. ネットワーク権限の設定

Info.plistに以下を追加（必要な場合）：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**注意**: 本番環境ではセキュアな接続のみを許可してください。

### 6. ビルドと実行

```bash
# クリーンビルド
flutter clean

# iOS依存関係の更新
cd ios
pod install
cd ..

# iOSシミュレータで実行
flutter run -d ios

# または実機で実行
flutter run -d "iPhone 15"
```

## トラブルシューティング

### 「ユーザー認証が表示されない」問題

1. **Supabase初期化の確認**
   ```dart
   // main.dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await SupabaseService.initialize();
     runApp(const CharacterQuestApp());
   }
   ```

2. **AuthGuardの動作確認**
   - AuthGuardが正しく認証状態を監視しているか
   - 初期ルートが正しく設定されているか

3. **ログの確認**
   - Xcodeのコンソールでエラーメッセージを確認
   - `print`文を追加してデバッグ

### よくあるエラー

1. **"Module 'supabase_flutter' not found"**
   ```bash
   cd ios
   pod deintegrate
   pod install
   ```

2. **ビルドエラー**
   ```bash
   flutter clean
   flutter pub get
   cd ios
   pod install
   ```

3. **認証後のリダイレクトが動作しない**
   - URL Schemeが正しく設定されているか確認
   - Supabaseダッシュボードのリダイレクト設定を確認

## デバッグのヒント

1. **Xcodeでのデバッグ**
   - ブレークポイントを設定
   - コンソールログを確認

2. **Flutter Inspector**
   - Widget treeを確認
   - 状態の変化を監視

3. **ネットワークリクエストの確認**
   - Charles ProxyやProxymanを使用
   - Supabase APIへのリクエストを監視

## 推奨事項

1. **開発環境**
   - メール確認を無効化（開発時のみ）
   - テスト用アカウントを使用

2. **本番環境への準備**
   - 適切なBundle Identifierを設定
   - プロビジョニングプロファイルを設定
   - App Store Connect の設定