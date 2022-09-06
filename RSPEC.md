# RSpec の概要
## RSpec とは
- RSpecとは、RubyやRuby on Railsで作ったクラスやメソッドをテストするためのドメイン特化言語 (DSL)を使ったフレームワーク
- Rubyには「MiniTest」という標準テストフレームワークが存在するが、Rspec のほうがより利用されている。文献が圧倒的に多い
- 元はテスト駆動開発を学ぶためのトレーニングツールだった

## Rspec導入のメリット
- 開発フェーズでのバグ早期発見
- 改修時のリグレッションテストの工数削減
- 外部サービスのmockやテストdb接続などの導入が容易

## Rspec導入のデメリット
- 学習コストの高さ (DSLドメイン固有言語のため、Ruby + RSpec両方覚える必要が)
- テストケースは開発者自身で作成する必要がある

## RSpec の基本構文
```ruby
# user.rb
class User < ApplicationRecord
  def full_name
    if self.last_name.nil? || self.first_name.nil? then
      raise StandardError.new("値がないよ")
    end

    "#{self.last_name} #{self.first_name}"
  end
end
```
```ruby
# user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'full_nameについて' do
    context "正しく名前が与えられた場合" do
      let(:user) { create(:user, first_name: '太郎', last_name: '山田') }
      it 'フルネームを取得すること' do
        expect(user.full_name).to eq '山田 太郎'
      end
    end
  end
end
```
基本的に `expect(A).to eq B` のように期待値をテスト値を比較する

### describe
〇〇に関するテストであるかを宣言する

### context
テストしようとしている状況を宣言する

### it
期待される結果を宣言する  
it do ... endにまとめられたテストを"example"といい、  これがテストの1ケース単位となる  

# ハンズオン
## 前準備の訂正
最後にRailsの動作確認の後、コンテナを停止すると称して  
`% docker-compose down`  
を実行しましたが、実際はコンテナを削除しています。  
※ 停止の正しいコマンドは  
`% docker-compose stop`  
### 以下のコマンドでコンテナを作成してください
```sh
% docker-compose build
```

***
## まず CRUD なWEBアプリを作る
### scaffold コマンドで簡単な記事投稿アプリを作る
```sh
% docker-compose run app rails g scaffold article title:string content:string
```

### DBマイグレーションする
```sh
% docker-compose run app rails db:migrate
```

### バリデーションをかける
```diff
# app/models/article.rb
class Article < ApplicationRecord
+  validates :title, presence: true
+  validates :title, length: { minimum:2, maximum: 10 }
+  validates :content, presence: true
end
```

### コンテナを起動し、動作を確認
```sh
% docker-compose up -d
```

### 動作確認
http://localhost:3000/articles  
にアクセスし New Article を押し
- タイトル必須
- タイトル文字数制限(2〜10)
- 本文必須  

であることを確認する

### コンテナを一旦停止
```sh
% docker-compose stop
```

## RSpec のインストール
### Gemfileを編集してRSpec他テストツールのインストール設定
```diff
# Gemfile
# 中略
  group :development, :test do
    gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
+   gem 'rspec-rails'
+   gem 'factory_bot_rails'
  end
# 中略
```
factory_bot_rails はサンプルデータ作成用ツールです  

### Gemfileを編集後、以下コマンドを実行してインストール
```sh
% docker-compose build
% docker-compose run app rails g rspec:install
```

コマンド実行後、rspec用のフォルダが作成されます
```
.rspec
spec
spec/spec_helper.rb
spec/rails_helper.rb
```

***
## RSpec の実行
### 以下コマンドを実行し、テストコードの雛形を作成
```sh
% docker-compose run app rails g rspec:model Article
```

コマンド実行後、Postモデルに対してのテストの雛形が作成されます
```
spec/models/article_spec.rb
spec/factories/articles.rb
```

### Article モデルのテストコードを追加
Article クラスに登録できることを確認するテストを追加
```ruby
# spec/models/article_spec.rb
require 'rails_helper'

RSpec.describe Article, type: :model do
  context 'titleとcontentが両方存在する場合' do
    let(:article) do
      Article.new({ title: '今日の天気', content: '晴れ' })
    end
    it '登録可能であること' do
      expect(article).to be_valid
    end
  end
end
```
ここでは `let` を使用してローカル変数 `article` を宣言している。  
`article` では Postモデルを作成し、`expect` 内で呼び出すことで値の参照を行なっています。  
`be_valid` はモデルオブジェクトのバリデーションが成功したかを検証するマッチャです  

### 以下コマンドでテストを実行します。
```sh
% docker-compose run app bundle exec rspec spec/models/article_spec.rb
```

Article クラスの条件を満たしているため、テストは正常に完了します  
```
.  

Finished in 0.21279 seconds (files took 14.99 seconds to load)  
1 example, 0 failures
```

***
### 例題
contentがnilを設定した Articleモデルの場合、登録に失敗するテストケースを追加作成する

***
## Factorybotの利用
Factorybot を使用することで、テスト実施時にあらかじめDBにレコードが存在する状態を作ることができる  

### 以下コマンドを実行し、テストコードの雛形を作成
```sh
% docker-compose run app rails g rspec:controller Article
```

`spec/request/post_spec.rb` を編集してテストを実装していきます
```ruby
# spec/request/post_spec.rb
require 'rails_helper'

RSpec.describe "Articles", type: :request do
  let!(:article1) { FactoryBot.create(:post, title: "今日の天気", content:"晴れ") }
  let!(:article2) { FactoryBot.create(:post, title: "明日の天気", content:"曇り") }
  let!(:article3) { FactoryBot.create(:post, title: "明後日の天気", content:"雨") }

  context 'index.jsonを呼び出す' do
    it "保存された Article が全件取得できる" do
      get "/articles.json" 
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(3)
    end
  end
end
```

以下コマンドでテストを実行
```sh
% docker-compose run app bundle exec rspec spec/requests/article_spec.rb
```

今回は以下２点の検証を行なっています。
- httpレスポンスステータスが正常（200）
- responseのjsonにデータが3件存在するか

### チャレンジ問題
削除できることを確認するテストコードを調べて書いてみよう

## 以上