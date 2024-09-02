## DBが遅くなる原因
- ```クエリの数が遅い```
SELECTとINSERTを大量発生させるケース

- ```1本のクエリが遅い```

## N + 1問題発生原因
***ループ処理の中でループを書いて大量のSQLが発生(SELECT)***。
ex)
ループの中で別のテーブルを呼ぶ
```rb
Shop.all.each do |shop|
  puts shop.name
    # お寿司屋
    # コンビニ
    # 居酒屋

# SELECT ...
# SELECT ...

  Shop.foods.each do |shop|
    puts foods.name
      # お刺身
      # ハイボール
      # タバコ
      # ジャンプ
      # 大トロ
      # サーモン
  end
end
```

## N +1問題解決策
- ```Eager Load```
***今回はこっちを採用***。1本釣りではなく、1本は2本でSELECTを収める
```rb
Shop.includes(:menu).all.each do |shop|
```

- ```JOIN```
SQLのJoinを使って1本釣り
```rb
Shop.join(:menu).all.each do |shop|
```
- 補足
```Eager Load(先にSELECT)```と```Lazy Load(遅延SELECT)```
Eager Loadがいい。

## その他DBのパフォーマンス低下原因(調査中)
### 1. ```大量データの読み込み```
***Post.allを使って数千件のレコードを一度に読み込むと、システムに大きな負荷がかかる***ので、
- ```解決策```
①```Pagination（ページネーション)によって大量のレコードをページごとに分割して読み込む```。
```rb
@posts = Post.page(params[:page]).per(10)
```
②```Batch Processing(大量のデータを一度に読み込まず、バッチで処理)```
```rb
Post.find_each(batch_size: 100) do |post|
end
```

### 2.```不適切なインデックス```
テーブルに対してインデックスが適切に設定されていない場合、データ検索が遅くなる。
where句で頻繁に使われるカラムにインデックスがないと、クエリのパフォーマンスが著しく低下。

- ```解決策```
インデックスの追加: 頻繁に検索に使うカラムにインデックスを追加
```
rails g migration add_index_to_posts_content
```
マイグレーションファイル。
```rb
add_index :posts, :content
```
複数のカラムを組み合わせて検索する場合、```複合インデックス```
```rb
add_index :posts, [:title, :created_at]
```
- インデックスの資料(自分が書いた記事)
https://qiita.com/Hashimoto-Noriaki/items/6a4dd9c5f0e1d2cf5203

### 3.```複雑なクエリとジョイン```
複数のテーブルに対する複雑なクエリやJOINが多用されると、クエリの実行が遅くなり、特に、非効率なJOINやサブクエリがパフォーマンスに悪影響。
```rb
@posts = Post.joins(:comments).select('posts.id, posts.title, comments.content')
```
データ正規化と非正規化のバランス: 正規化しすぎるとクエリが複雑化することがあります。必要に応じてデータの非正規化を検討

### 4.```テーブルの肥大化```
テーブルが大きくなると、全体のパフォーマンスが低下(データが長期間蓄積されたログやイベントテーブルなど)
- ***アーカイブ***
古いデータを別のテーブルやストレージにアーカイブし、主要なテーブルから削除

- ***パーティショニング***
大規模なテーブルをパーティションに分割することで、データのアクセス速度を向上

・自分が書いたパーティションに関する記事
https://qiita.com/Hashimoto-Noriaki/items/6a4dd9c5f0e1d2cf5203

### 5.クエリキャッシュの未使用
同じクエリを何度も実行すると、パフォーマンスが低下。Railsにはクエリキャッシュ機能があり、同じクエリが複数回実行される場合に結果をキャッシュ。
クエリキャッシュの活用: Railsのクエリキャッシュを活用する
```rb
# キャッシュを手動で有効化する例
Rails.cache.fetch("post/#{post.id}") do
  post.comments.to_a
end
```

### 6.```データベースのロック```
複数のクライアントが同時にデータベースの同じレコードに対して書き込み操作を行う場合、データベースがロックされ、他のクエリのパフォーマンスが低下
- ```解決策```
トランザクションの適切な使用: トランザクションを適切に使用し、必要以上にロックを保持しないようにする。
```rb
Post.transaction do
  post.lock!
  # 更新操作
end
```
デッドロックの回避: 複数のテーブルを更新する際の順序を決め、デッドロックを避ける。
