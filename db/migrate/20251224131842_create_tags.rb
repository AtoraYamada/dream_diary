class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags, comment: 'タグマスター（登場人物・場所）' do |t|
      t.references :user, null: false, foreign_key: true, comment: 'ユーザーID'
      t.string :name, null: false, comment: 'タグ名（元の表記）'
      t.string :yomi, null: false, comment: '読み仮名（ひらがな）'
      t.integer :yomi_index, null: false, comment: '五十音インデックス'
      t.integer :category, null: false, comment: 'カテゴリ（enum: 0=person, 1=place）'

      t.timestamps null: false, comment: '作成日時・更新日時'

      t.index [:user_id, :name], unique: true
      t.index [:user_id, :yomi]
      t.index [:user_id, :yomi_index]
      t.index [:user_id, :category]
    end
  end
end
