# RSpec ハンズオン

## 前提条件
Mac に Docker がインストール済みであること  
M1 Mac は一部追加作業あり

***
## 作業ディレクトリの準備
作業用ディレクトリを作成してそのディレクトリ内に移動  
名前の決め方は任意ですが、  
合わせた方がコピペが楽です。
```sh
% mkdir rspec_handson && cd $_
% pwd
/Users/Tanaka/projects/rspec_handson
```

次に以下の4つのからファイルを作成します
- Dockerfile
- docker-compose.yml
- Gemfile
- Gemfile.lock  

```sh
% touch Dockerfile docker-compose.yml Gemfile Gemfile.lock
% ls
Dockerfile		Gemfile.lock
Gemfile			docker-compose.yml
```

***
## Dockerfile の編集
```docker
FROM ruby:3.0.2

RUN wget --quiet -O - /tmp/pubkey.gpg https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list
RUN set -x && apt-get update -y -qq && apt-get install -yq nodejs yarn

RUN mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install
COPY . /app
```

***
## docker-compose.yml の編集
### ※ <font color="Red">M1 Mac</font> の人は下のコメントアウトを外すこと
```yml
version: '3'
services:
  app:
    build: .
    command: bundle exec rails s -p 3000 -b '0.0.0.0'
    volumes:
      - .:/app
    ports:
      - 3000:3000
    depends_on:
      - db
    tty: true
    stdin_open: true
  db:
    # platform: linux/x86_64
    image: mysql:5.7
    volumes:
      - db-volume:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: password
volumes:
  db-volume:
```

***
## Gemfile の編集
```ruby
source 'https://rubygems.org'
gem 'rails', '6.1.4'
```

***
## Docker 環境下で rails new
```sh
% docker-compose run app rails new . -f -d mysql
```
### ※ 時間がかかります

***
## database.yml の編集
rspec_handson/config/database.yml の  
default のホスト名とパスワードを `docker-compose.yml` で指定した値に変更  

```diff
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
-  password: 
+  password: password
-  host: localhost
+  host: db
```

***
## 再度ビルドして変更内容をコンテナに反映
```sh
% docker-compose build
```

***
## バックグラウンドでコンテナを起動
```sh
% docker-compose up -d
```

***
## データベース作成
```sh
% docker-compose run app rails db:create
```

***
## デフォルトページ確認
http://localhost:3000  
にアクセスしてRailsデフォルトページの表示を確認

***
## 一旦コンテナを停止
```sh
% docker-compose stop
```
