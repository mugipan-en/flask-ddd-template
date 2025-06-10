# 🌶️ Flask DDD Template

[![CI](https://github.com/mugipan-en/flask-ddd-template/actions/workflows/ci.yml/badge.svg)](https://github.com/mugipan-en/flask-ddd-template/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/mugipan-en/flask-ddd-template/branch/main/graph/badge.svg)](https://codecov.io/gh/mugipan-en/flask-ddd-template)
[![Python](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Flask](https://img.shields.io/badge/Flask-3.0+-green.svg)](https://flask.palletsprojects.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Production-ready Flask + Domain Driven Design template with async task processing**

軽量API開発とバッチ処理に特化したFlaskテンプレート。FastAPIとの差別化としてCeleryを使った非同期処理を重視。

## 🏗️ アーキテクチャ

```
app/
├── domain/          # ドメイン層
│   ├── entities/    # エンティティ
│   ├── repositories/# リポジトリインターフェース
│   └── services/    # ドメインサービス
├── application/     # アプリケーション層
│   └── use_cases/   # ユースケース
├── infrastructure/ # インフラ層
│   ├── database/    # DB設定・マイグレーション
│   ├── repositories/# リポジトリ実装
│   ├── external/    # 外部API
│   └── tasks/       # Celeryタスク
├── presentation/   # プレゼンテーション層
│   ├── api/        # APIエンドポイント
│   ├── schemas/    # マーシャリング
│   └── middleware/ # ミドルウェア
└── worker/         # バッチ処理・ワーカー
    ├── tasks/      # 非同期タスク
    └── schedulers/ # 定期実行タスク
```

## 🚀 クイックスタート

### 1. 環境構築

```bash
# リポジトリをクローン
git clone https://github.com/mugipan-en/flask-ddd-template.git
cd flask-ddd-template

# uvをインストール（未インストールの場合）
curl -LsSf https://astral.sh/uv/install.sh | sh

# 依存関係をインストール
make setup
```

### 2. サービス起動

```bash
# PostgreSQL・Redis起動
docker-compose up -d postgres redis

# DBマイグレーション
make migrate

# アプリケーション起動
make dev

# 別ターミナルでワーカー起動
make worker

# タスク監視UI起動
make flower
```

### 3. 確認

```bash
# API確認
curl http://localhost:5000/api/v1/health

# Flower (タスク監視) 確認
open http://localhost:5555
```

## 📋 主な機能

### ✅ Web API機能
- **REST API**: Flask-RESTful + Marshmallow
- **認証**: JWT + Flask-JWT-Extended
- **バリデーション**: Marshmallow schemas
- **ページネーション**: SQLAlchemy pagination
- **レート制限**: Flask-Limiter
- **CORS**: Flask-CORS

### 🔄 バッチ処理機能（FastAPIとの差別化）
- **非同期処理**: Celery + Redis
- **定期実行**: Celery Beat
- **タスク監視**: Flower
- **エラーハンドリング**: Retry機能
- **メール送信**: SMTP対応
- **ファイル処理**: CSV/Excel読み込み

### 🗄️ データベース
- **ORM**: SQLAlchemy 2.0
- **マイグレーション**: Flask-Migrate (Alembic)
- **接続プール**: psycopg2-pool

## 🔧 開発コマンド

```bash
# セットアップ
make setup          # 依存関係インストール
make setup-dev      # 開発用依存関係も含む

# 開発
make dev            # 開発サーバー起動
make worker         # Celeryワーカー起動
make flower         # Flower監視UI起動
make scheduler      # Celery Beat起動

# テスト・品質
make test           # テスト実行
make test-cov       # カバレッジ付きテスト
make lint           # コード品質チェック
make fmt            # コードフォーマット

# データベース
make migrate        # マイグレーション実行
make migrate-auto   # 自動マイグレーション生成
make seed           # 初期データ投入

# タスク実行
make task name=example_task  # 手動タスク実行
```

## 📁 ディレクトリ構成

```
flask-ddd-template/
├── app/
│   ├── __init__.py
│   ├── main.py                    # Flaskアプリケーション
│   ├── core/                      # 共通設定
│   │   ├── config.py             # 設定管理
│   │   ├── database.py           # DB接続
│   │   └── extensions.py         # Flask拡張
│   ├── domain/                    # ドメイン層
│   ├── application/               # ユースケース層
│   ├── infrastructure/            # インフラ層
│   ├── presentation/              # API層
│   └── worker/                    # バッチ処理層
├── migrations/                    # Flask-Migrate
├── tests/                         # テストコード
├── scripts/                       # ユーティリティ
├── docker/                        # Docker設定
├── .github/workflows/             # CI/CD
├── celeryconfig.py               # Celery設定
├── pyproject.toml
└── docker-compose.yml
```

## 🔐 環境変数

`.env`ファイルを作成：

```env
# Flask
FLASK_APP=app.main:app
FLASK_ENV=development
SECRET_KEY=your-secret-key

# Database
DATABASE_URL=postgresql://user:password@localhost/flask_ddd
TEST_DATABASE_URL=sqlite:///test.db

# Redis & Celery
REDIS_URL=redis://localhost:6379
CELERY_BROKER_URL=redis://localhost:6379
CELERY_RESULT_BACKEND=redis://localhost:6379

# JWT
JWT_SECRET_KEY=your-jwt-secret

# Email (バッチ処理用)
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
```

## 🔄 非同期タスク例

### タスク定義
```python
# app/worker/tasks/example.py
from app.core.celery import celery_app

@celery_app.task(bind=True, max_retries=3)
def process_user_data(self, user_id: int):
    try:
        # 重い処理をここに
        result = heavy_computation(user_id)
        return {"status": "success", "result": result}
    except Exception as exc:
        # リトライ機能
        self.retry(countdown=60, exc=exc)
```

### タスク実行
```python
# APIエンドポイントから
from app.worker.tasks.example import process_user_data

@api.route('/users/<int:user_id>/process', methods=['POST'])
def trigger_process(user_id):
    task = process_user_data.delay(user_id)
    return {"task_id": task.id}, 202
```

## 📊 API仕様

### 認証
- `POST /api/v1/auth/login` - ログイン
- `POST /api/v1/auth/register` - ユーザー登録
- `POST /api/v1/auth/refresh` - トークン更新

### ユーザー管理
- `GET /api/v1/users` - ユーザー一覧
- `POST /api/v1/users` - ユーザー作成
- `GET /api/v1/users/<id>` - ユーザー詳細
- `PUT /api/v1/users/<id>` - ユーザー更新

### タスク管理
- `POST /api/v1/tasks` - タスク作成・実行
- `GET /api/v1/tasks/<task_id>` - タスク状態確認
- `GET /api/v1/tasks` - タスク一覧

## 🚀 デプロイ

### Docker
```bash
# イメージビルド
docker build -t flask-ddd-template .

# サービス起動
docker-compose up -d
```

### 本番環境設定
```bash
# Gunicorn + Nginx
gunicorn --bind 0.0.0.0:5000 "app.main:create_app()"

# Celeryワーカー（複数プロセス）
celery -A app.core.celery worker --loglevel=info --concurrency=4

# Celery Beat（スケジューラー）
celery -A app.core.celery beat --loglevel=info
```

## 🧪 テスト

```bash
# 全テスト実行
make test

# カバレッジレポート
make test-cov
open htmlcov/index.html

# 特定のテスト
pytest tests/test_tasks.py -v
```

## 🤝 コントリビューション

1. フォーク
2. ブランチ作成 (`git checkout -b feature/amazing-feature`)
3. コミット (`git commit -m 'Add amazing feature'`)
4. プッシュ (`git push origin feature/amazing-feature`)
5. Pull Request作成

## 📄 ライセンス

MIT License. 詳細は [LICENSE](LICENSE) を参照。

## 🙏 謝辞

- [Flask](https://flask.palletsprojects.com/) - Python Webフレームワーク
- [Celery](https://docs.celeryproject.org/) - 分散タスクキュー
- [SQLAlchemy](https://www.sqlalchemy.org/) - Python SQLツールキット

---

**⭐ 非同期処理が必要なプロジェクトにはこのテンプレートを！**